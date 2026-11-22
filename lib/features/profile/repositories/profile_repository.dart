import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../shared/models/address.dart';
import '../../../shared/models/payment_card.dart';
import '../../../shared/models/user.dart';

class NotificationPreferences {
  final bool generalNotification;
  final bool sound;
  final bool vibrate;
  final bool specialOffers;
  final bool promoAndDiscount;
  final bool payments;
  final bool cashbacks;
  final bool newService;
  final bool newTips;

  const NotificationPreferences({
    this.generalNotification = true,
    this.sound = true,
    this.vibrate = false,
    this.specialOffers = true,
    this.promoAndDiscount = true,
    this.payments = true,
    this.cashbacks = false,
    this.newService = false,
    this.newTips = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      generalNotification: map['generalNotification'] as bool? ?? true,
      sound: map['sound'] as bool? ?? true,
      vibrate: map['vibrate'] as bool? ?? false,
      specialOffers: map['specialOffers'] as bool? ?? true,
      promoAndDiscount: map['promoAndDiscount'] as bool? ?? true,
      payments: map['payments'] as bool? ?? true,
      cashbacks: map['cashbacks'] as bool? ?? false,
      newService: map['newService'] as bool? ?? false,
      newTips: map['newTips'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'generalNotification': generalNotification,
      'sound': sound,
      'vibrate': vibrate,
      'specialOffers': specialOffers,
      'promoAndDiscount': promoAndDiscount,
      'payments': payments,
      'cashbacks': cashbacks,
      'newService': newService,
      'newTips': newTips,
    };
  }

  NotificationPreferences copyWith({
    bool? generalNotification,
    bool? sound,
    bool? vibrate,
    bool? specialOffers,
    bool? promoAndDiscount,
    bool? payments,
    bool? cashbacks,
    bool? newService,
    bool? newTips,
  }) {
    return NotificationPreferences(
      generalNotification: generalNotification ?? this.generalNotification,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      specialOffers: specialOffers ?? this.specialOffers,
      promoAndDiscount: promoAndDiscount ?? this.promoAndDiscount,
      payments: payments ?? this.payments,
      cashbacks: cashbacks ?? this.cashbacks,
      newService: newService ?? this.newService,
      newTips: newTips ?? this.newTips,
    );
  }
}

class SecurityPreferences {
  final bool rememberMe;
  final bool biometricAuth;
  final bool googleAuthenticator;

  const SecurityPreferences({
    this.rememberMe = true,
    this.biometricAuth = false,
    this.googleAuthenticator = false,
  });

  factory SecurityPreferences.fromMap(Map<String, dynamic> map) {
    return SecurityPreferences(
      rememberMe: map['rememberMe'] as bool? ?? true,
      biometricAuth: map['biometricAuth'] as bool? ?? false,
      googleAuthenticator: map['googleAuthenticator'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rememberMe': rememberMe,
      'biometricAuth': biometricAuth,
      'googleAuthenticator': googleAuthenticator,
    };
  }

  SecurityPreferences copyWith({
    bool? rememberMe,
    bool? biometricAuth,
    bool? googleAuthenticator,
  }) {
    return SecurityPreferences(
      rememberMe: rememberMe ?? this.rememberMe,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      googleAuthenticator: googleAuthenticator ?? this.googleAuthenticator,
    );
  }
}

abstract class ProfileRepository {
  Future<UserProfile> fetchProfile();
  Future<void> updateProfile(UserProfile profile);

  Future<List<Address>> fetchAddresses();
  Future<void> saveAddress(Address address);
  Future<void> deleteAddress(String addressId);
  Future<void> setDefaultAddress(String addressId);

  Future<List<PaymentCard>> fetchPaymentCards();
  Future<void> savePaymentCard(PaymentCard card);
  Future<void> deletePaymentCard(String cardId);
  Future<void> setDefaultPaymentCard(String cardId);

  Future<NotificationPreferences> fetchNotificationPreferences();
  Future<void> saveNotificationPreferences(NotificationPreferences prefs);

  Future<SecurityPreferences> fetchSecurityPreferences();
  Future<void> saveSecurityPreferences(SecurityPreferences prefs);

  Future<String> fetchSelectedLanguage();
  Future<void> saveSelectedLanguage(String language);
}

class ProfileRepositoryImpl implements ProfileRepository {
  static const _profilePrefix = 'profile_data_';
  static const _addressPrefix = 'user_addresses_';
  static const _cardsPrefix = 'user_cards_';
  static const _notifPrefix = 'user_notif_prefs_';
  static const _secPrefix = 'user_sec_prefs_';
  static const _langPrefix = 'user_selected_lang_';

  String get _currentUid {
    if (Firebase.apps.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) return user.uid;
    }
    return 'default_guest_user';
  }

  Future<DocumentReference<Map<String, dynamic>>> _getUserDocRef(String uid) async {
    final collections = [
      FirestoreCollections.customers,
      FirestoreCollections.vendors,
      FirestoreCollections.staff,
    ];
    for (final col in collections) {
      final docRef = FirebaseFirestore.instance.collection(col).doc(uid);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return docRef;
      }
    }
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.customers)
        .doc(uid);
  }

  @override
  Future<UserProfile> fetchProfile() async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();

    // 1. Try local cache first for quick initial load
    UserProfile? localProfile;
    final cachedStr = prefs.getString('$_profilePrefix$uid');
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
        localProfile = UserProfile.fromMap(decoded, uid: uid);
      } catch (_) {}
    }

    // 2. Fetch from Firestore if available
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        final authUser = FirebaseAuth.instance.currentUser!;
        final docRef = await _getUserDocRef(uid);
        final doc = await docRef.get();

        if (doc.exists && doc.data() != null) {
          final profile = UserProfile.fromMap(doc.data()!, uid: uid);
          await prefs.setString(
            '$_profilePrefix$uid',
            jsonEncode(profile.toMap()),
          );
          return profile;
        } else {
          final profile = UserProfile(
            uid: uid,
            name: authUser.displayName ?? '',
            email: authUser.email ?? '',
            photoUrl: authUser.photoURL,
          );
          await prefs.setString(
            '$_profilePrefix$uid',
            jsonEncode(profile.toMap()),
          );
          return profile;
        }
      } catch (_) {}
    }

    if (localProfile != null) return localProfile;

    return UserProfile(
      uid: uid,
      name: '',
      email: '',
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final uid = profile.uid.isNotEmpty ? profile.uid : _currentUid;
    final prefs = await SharedPreferences.getInstance();

    // Cache locally
    await prefs.setString('$_profilePrefix$uid', jsonEncode(profile.toMap()));

    // Update Firebase Auth & Firestore
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      final authUser = FirebaseAuth.instance.currentUser!;
      try {
        if (profile.name.isNotEmpty) {
          await authUser.updateDisplayName(profile.name);
        }
        if (profile.photoUrl != authUser.photoURL) {
          await authUser.updatePhotoURL(profile.photoUrl);
        }
      } catch (_) {}

      try {
        final docRef = await _getUserDocRef(uid);
        await docRef.set(profile.toMap()..['updatedAt'] = FieldValue.serverTimestamp(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ================= ADDRESSES =================
  @override
  Future<List<Address>> fetchAddresses() async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_addressPrefix$uid');

    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        final addresses = list
            .map((e) => Address.fromMap(e as Map<String, dynamic>))
            .toList();
        if (addresses.isNotEmpty) return addresses;
      } catch (_) {}
    }

    // 2. Fetch from Firestore if available
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        final docRef = await _getUserDocRef(uid);
        final doc = await docRef.get();
        if (doc.exists && doc.data()?['addresses'] != null) {
          final list = doc.data()!['addresses'] as List;
          final addresses = list
              .map((e) => Address.fromMap(e as Map<String, dynamic>))
              .toList();
          await prefs.setString(
            '$_addressPrefix$uid',
            jsonEncode(addresses.map((e) => e.toMap()).toList()),
          );
          return addresses;
        }
      } catch (_) {}
    }

    return const [];
  }

  @override
  Future<void> saveAddress(Address address) async {
    final uid = _currentUid;
    final addresses = await fetchAddresses();
    final index = addresses.indexWhere((a) => a.id == address.id);

    List<Address> updated;
    if (index >= 0) {
      updated = List.of(addresses);
      updated[index] = address;
    } else {
      updated = [...addresses, address];
    }

    // If new or updated address is default, reset others
    if (address.isDefault) {
      updated = updated
          .map((a) => a.copyWith(isDefault: a.id == address.id))
          .toList();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_addressPrefix$uid',
      jsonEncode(updated.map((e) => e.toMap()).toList()),
    );

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'addresses': updated.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    final uid = _currentUid;
    final addresses = await fetchAddresses();
    final updated = addresses.where((a) => a.id != addressId).toList();

    // If we removed the default address and there are still addresses left, make the first one default
    if (updated.isNotEmpty && !updated.any((a) => a.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_addressPrefix$uid',
      jsonEncode(updated.map((e) => e.toMap()).toList()),
    );

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'addresses': updated.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    final uid = _currentUid;
    final addresses = await fetchAddresses();
    final updated = addresses
        .map((a) => a.copyWith(isDefault: a.id == addressId))
        .toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_addressPrefix$uid',
      jsonEncode(updated.map((e) => e.toMap()).toList()),
    );

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'addresses': updated.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ================= PAYMENT CARDS =================
  @override
  Future<List<PaymentCard>> fetchPaymentCards() async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cardsPrefix$uid');

    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        final cards = list
            .map((e) => PaymentCard.fromMap(e as Map<String, dynamic>))
            .toList();
        if (cards.isNotEmpty) return cards;
      } catch (_) {}
    }

    // 2. Fetch from Firestore if available
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        final docRef = await _getUserDocRef(uid);
        final doc = await docRef.get();
        if (doc.exists && doc.data()?['paymentCards'] != null) {
          final list = doc.data()!['paymentCards'] as List;
          final cards = list
              .map((e) => PaymentCard.fromMap(e as Map<String, dynamic>))
              .toList();
          await prefs.setString(
            '$_cardsPrefix$uid',
            jsonEncode(cards.map((e) => e.toMap()).toList()),
          );
          return cards;
        }
      } catch (_) {}
    }

    return const [];
  }

  @override
  Future<void> savePaymentCard(PaymentCard card) async {
    final uid = _currentUid;
    final cards = await fetchPaymentCards();
    final index = cards.indexWhere((c) => c.id == card.id);

    List<PaymentCard> updated;
    if (index >= 0) {
      updated = List.of(cards);
      updated[index] = card;
    } else {
      updated = [...cards, card];
    }

    if (card.isDefault || updated.length == 1) {
      updated = updated
          .map((c) => c.copyWith(isDefault: c.id == card.id))
          .toList();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_cardsPrefix$uid',
      jsonEncode(updated.map((e) => e.toMap()).toList()),
    );

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'paymentCards': updated.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> deletePaymentCard(String cardId) async {
    final uid = _currentUid;
    final cards = await fetchPaymentCards();
    final updated = cards.where((c) => c.id != cardId).toList();

    if (updated.isNotEmpty && !updated.any((c) => c.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_cardsPrefix$uid',
      jsonEncode(updated.map((e) => e.toMap()).toList()),
    );

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'paymentCards': updated.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> setDefaultPaymentCard(String cardId) async {
    final uid = _currentUid;
    final cards = await fetchPaymentCards();
    final updated = cards
        .map((c) => c.copyWith(isDefault: c.id == cardId))
        .toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_cardsPrefix$uid',
      jsonEncode(updated.map((e) => e.toMap()).toList()),
    );

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'paymentCards': updated.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ================= NOTIFICATIONS =================
  @override
  Future<NotificationPreferences> fetchNotificationPreferences() async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_notifPrefix$uid');

    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return NotificationPreferences.fromMap(map);
      } catch (_) {}
    }

    return const NotificationPreferences();
  }

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_notifPrefix$uid', jsonEncode(preferences.toMap()));

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'notificationPreferences': preferences.toMap(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ================= SECURITY =================
  @override
  Future<SecurityPreferences> fetchSecurityPreferences() async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_secPrefix$uid');

    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return SecurityPreferences.fromMap(map);
      } catch (_) {}
    }

    return const SecurityPreferences();
  }

  @override
  Future<void> saveSecurityPreferences(SecurityPreferences preferences) async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_secPrefix$uid', jsonEncode(preferences.toMap()));

    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await (await _getUserDocRef(uid)).set({
          'securityPreferences': preferences.toMap(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ================= LANGUAGE =================
  @override
  Future<String> fetchSelectedLanguage() async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_langPrefix$uid') ?? 'English (US)';
  }

  @override
  Future<void> saveSelectedLanguage(String language) async {
    final uid = _currentUid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_langPrefix$uid', language);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(),
);
