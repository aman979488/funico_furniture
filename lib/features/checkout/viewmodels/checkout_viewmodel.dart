import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/address.dart';
import '../../../shared/models/cart_item.dart';
import '../../../shared/models/order.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../../orders/viewmodels/orders_viewmodel.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';
import '../repositories/checkout_repository.dart';

class ShippingOption {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final String estimatedDate;

  const ShippingOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.estimatedDate,
  });
}

class CheckoutState {
  const CheckoutState({
    this.selectedAddress,
    this.selectedShippingOption = const ShippingOption(
      id: 'standard',
      title: 'Standard Delivery & Fitting',
      subtitle: 'Estimated delivery & assembly in 2-3 business days',
      price: 1200.0,
      estimatedDate: '2-3 Days',
    ),
    this.selectedPaymentMethod = 'UPI',
    this.promoCode = '10% Add code',
    this.promoDiscountRate = 0.10, // 10%
    this.isLoading = false,
    this.lastPlacedOrder,
    this.error,
  });

  final Address? selectedAddress;
  final ShippingOption selectedShippingOption;
  final String selectedPaymentMethod;
  final String promoCode;
  final double promoDiscountRate;
  final bool isLoading;
  final AppOrder? lastPlacedOrder;
  final String? error;

  CheckoutState copyWith({
    Address? selectedAddress,
    ShippingOption? selectedShippingOption,
    String? selectedPaymentMethod,
    String? promoCode,
    double? promoDiscountRate,
    bool? isLoading,
    AppOrder? lastPlacedOrder,
    String? error,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedShippingOption:
          selectedShippingOption ?? this.selectedShippingOption,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      promoCode: promoCode ?? this.promoCode,
      promoDiscountRate: promoDiscountRate ?? this.promoDiscountRate,
      isLoading: isLoading ?? this.isLoading,
      lastPlacedOrder: lastPlacedOrder ?? this.lastPlacedOrder,
      error: error,
    );
  }
}

class CheckoutViewModel extends Notifier<CheckoutState> {
  late final CheckoutRepository _repository;

  @override
  CheckoutState build() {
    _repository = ref.watch(checkoutRepositoryProvider);
    final profileState = ref.watch(profileViewModelProvider);
    final initialAddress = profileState.defaultAddress ??
        const Address(
          id: 'default_home',
          name: 'Home',
          details: 'Flat 402, Lotus Court, MG Road',
          city: 'New Delhi',
          state: 'Delhi',
          postalCode: '110001',
          country: 'India',
          isDefault: true,
          phoneNumber: '+91 98765 43210',
        );

    return CheckoutState(selectedAddress: initialAddress);
  }

  void selectAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  void selectShippingOption(ShippingOption option) {
    state = state.copyWith(selectedShippingOption: option);
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void applyPromoCode(String code) {
    state = state.copyWith(promoCode: code, promoDiscountRate: 0.10);
  }

  Future<AppOrder> confirmOrder({
    required List<CartItem> cartItems,
    required double subtotal,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final shippingCost = state.selectedShippingOption.price;
      final discount = subtotal * state.promoDiscountRate;
      final total = subtotal + shippingCost - discount;

      final randomNum = 1000 + Random().nextInt(9000);
      final orderNumber = 'FH-$randomNum';

      final order = AppOrder(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: orderNumber,
        items: cartItems.map((c) => OrderItem.fromCartItem(c)).toList(),
        shippingAddress: state.selectedAddress,
        shippingType: state.selectedShippingOption.title,
        shippingCost: shippingCost,
        paymentMethod: state.selectedPaymentMethod,
        subtotal: subtotal,
        discount: discount,
        totalAmount: total,
        createdAt: DateTime.now(),
        status: 'Processing',
        progressStep: 1,
      );

      final savedOrder = await _repository.placeOrder(order);

      // Save order to orders viewmodel
      ref.read(ordersViewModelProvider.notifier).addOrder(savedOrder);

      // Clear the cart
      ref.read(cartViewModelProvider.notifier).clearCart();

      state = state.copyWith(isLoading: false, lastPlacedOrder: savedOrder);
      return savedOrder;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final checkoutViewModelProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);
