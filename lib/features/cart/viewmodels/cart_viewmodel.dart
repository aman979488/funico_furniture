import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cart_item.dart';
import '../../../shared/models/product.dart';
import '../repositories/cart_repository.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal;
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CartViewModel extends Notifier<CartState> {
  late final CartRepository _repository;

  @override
  CartState build() {
    _repository = ref.watch(cartRepositoryProvider);
    return CartState(items: _repository.getCartItems());
  }

  void addToCart(Product product, {int quantity = 1, int? selectedColor}) {
    final colorSuffix = selectedColor != null ? selectedColor.toString() : 'default';
    final itemId = '${product.id}_$colorSuffix';

    final cartItem = CartItem(
      id: itemId,
      product: product,
      quantity: quantity,
      selectedColor: selectedColor,
    );

    _repository.addItem(cartItem);
    state = state.copyWith(items: List.from(_repository.getCartItems()));
  }

  void updateQuantity(String cartItemId, int quantity) {
    _repository.updateQuantity(cartItemId, quantity);
    state = state.copyWith(items: List.from(_repository.getCartItems()));
  }

  void removeFromCart(String cartItemId) {
    _repository.removeItem(cartItemId);
    state = state.copyWith(items: List.from(_repository.getCartItems()));
  }

  void clearCart() {
    _repository.clearCart();
    state = state.copyWith(items: const []);
  }

  bool isInCart(String productId) {
    return state.items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId, {int? selectedColor}) {
    for (final item in state.items) {
      if (item.product.id == productId) {
        if (selectedColor == null || item.selectedColor == selectedColor) {
          return item.quantity;
        }
      }
    }
    return 0;
  }
}

final cartViewModelProvider = NotifierProvider<CartViewModel, CartState>(
  CartViewModel.new,
);
