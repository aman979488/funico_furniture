import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/address.dart';
import '../../../shared/models/payment_card.dart';
import '../../../shared/models/user.dart';
import '../repositories/profile_repository.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.error,
    this.userProfile,
    this.addresses = const [],
    this.paymentCards = const [],
    this.notificationPreferences = const NotificationPreferences(),
    this.securityPreferences = const SecurityPreferences(),
    this.selectedLanguage = 'English (US)',
  });

  final bool isLoading;
  final String? error;
  final UserProfile? userProfile;
  final List<Address> addresses;
  final List<PaymentCard> paymentCards;
  final NotificationPreferences notificationPreferences;
  final SecurityPreferences securityPreferences;
  final String selectedLanguage;

  Address? get defaultAddress {
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  PaymentCard? get defaultPaymentCard {
    try {
      return paymentCards.firstWhere((c) => c.isDefault);
    } catch (_) {
      return paymentCards.isNotEmpty ? paymentCards.first : null;
    }
  }

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    UserProfile? userProfile,
    List<Address>? addresses,
    List<PaymentCard>? paymentCards,
    NotificationPreferences? notificationPreferences,
    SecurityPreferences? securityPreferences,
    String? selectedLanguage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userProfile: userProfile ?? this.userProfile,
      addresses: addresses ?? this.addresses,
      paymentCards: paymentCards ?? this.paymentCards,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      securityPreferences: securityPreferences ?? this.securityPreferences,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }
}

class ProfileViewModel extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    // Initial fetch trigger
    Future.microtask(() => loadAll());
    return const ProfileState(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.fetchProfile();
      final addresses = await _repository.fetchAddresses();
      final cards = await _repository.fetchPaymentCards();
      final notifs = await _repository.fetchNotificationPreferences();
      final sec = await _repository.fetchSecurityPreferences();
      final lang = await _repository.fetchSelectedLanguage();

      state = state.copyWith(
        isLoading: false,
        userProfile: profile,
        addresses: addresses,
        paymentCards: cards,
        notificationPreferences: notifs,
        securityPreferences: sec,
        selectedLanguage: lang,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateProfile(profile);
      state = state.copyWith(isLoading: false, userProfile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // --- Address methods ---
  Future<void> saveAddress(Address address) async {
    try {
      await _repository.saveAddress(address);
      final addresses = await _repository.fetchAddresses();
      state = state.copyWith(addresses: addresses);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _repository.deleteAddress(addressId);
      final addresses = await _repository.fetchAddresses();
      state = state.copyWith(addresses: addresses);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _repository.setDefaultAddress(addressId);
      final addresses = await _repository.fetchAddresses();
      state = state.copyWith(addresses: addresses);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // --- Payment cards ---
  Future<void> savePaymentCard(PaymentCard card) async {
    try {
      await _repository.savePaymentCard(card);
      final cards = await _repository.fetchPaymentCards();
      state = state.copyWith(paymentCards: cards);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePaymentCard(String cardId) async {
    try {
      await _repository.deletePaymentCard(cardId);
      final cards = await _repository.fetchPaymentCards();
      state = state.copyWith(paymentCards: cards);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> setDefaultPaymentCard(String cardId) async {
    try {
      await _repository.setDefaultPaymentCard(cardId);
      final cards = await _repository.fetchPaymentCards();
      state = state.copyWith(paymentCards: cards);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // --- Preferences ---
  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    state = state.copyWith(notificationPreferences: preferences);
    try {
      await _repository.saveNotificationPreferences(preferences);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSecurityPreferences(
    SecurityPreferences preferences,
  ) async {
    state = state.copyWith(securityPreferences: preferences);
    try {
      await _repository.saveSecurityPreferences(preferences);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(selectedLanguage: language);
    try {
      await _repository.saveSelectedLanguage(language);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
