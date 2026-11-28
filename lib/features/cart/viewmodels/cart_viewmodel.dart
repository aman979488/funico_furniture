import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cart_item.dart';
import '../../../shared/models/product.dart';
import '../repositories/cart_repository.dart';

class CartCode {
  const CartCode({required this.id, required this.name});

  final String id;
  final String name;
}

class CartState {
  const CartState({
    this.items = const [],
    this.codes = const [
      CartCode(id: 'code_1', name: 'Code 1'),
      CartCode(id: 'code_2', name: 'Code 2'),
      CartCode(id: 'code_3', name: 'Code 3'),
    ],
    this.selectedCodeId = 'code_1',
    this.isLoading = false,
    this.error,
  });

  final List<CartItem> items;
  final List<CartCode> codes;
  final String selectedCodeId;
  final bool isLoading;
  final String? error;

  List<CartItem> get selectedCodeItems =>
      items.where((item) => item.codeId == selectedCodeId).toList();
  double get subtotal =>
      selectedCodeItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal;
  int get totalItemCount =>
      selectedCodeItems.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => selectedCodeItems.isEmpty;
  bool get isNotEmpty => selectedCodeItems.isNotEmpty;

  CartCode get selectedCode =>
      codes.firstWhere((code) => code.id == selectedCodeId);

  CartState copyWith({
    List<CartItem>? items,
    List<CartCode>? codes,
    String? selectedCodeId,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      codes: codes ?? this.codes,
      selectedCodeId: selectedCodeId ?? this.selectedCodeId,
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

  void addToCart(
    Product product, {
    int quantity = 1,
    int? selectedColor,
    String? codeId,
  }) {
    final targetCodeId = codeId ?? state.selectedCodeId;
    if (!state.codes.any((code) => code.id == targetCodeId)) {
      throw ArgumentError.value(targetCodeId, 'codeId', 'Unknown cart code');
    }
    final colorSuffix = selectedColor != null
        ? selectedColor.toString()
        : 'default';
    final itemId = '${product.id}_${targetCodeId}_$colorSuffix';

    final cartItem = CartItem(
      id: itemId,
      product: product,
      quantity: quantity,
      codeId: targetCodeId,
      selectedColor: selectedColor,
    );

    _repository.addItem(cartItem);
    state = state.copyWith(items: List.from(_repository.getCartItems()));
  }

  void selectCode(String codeId) {
    if (!state.codes.any((code) => code.id == codeId)) {
      throw ArgumentError.value(codeId, 'codeId', 'Unknown cart code');
    }
    state = state.copyWith(selectedCodeId: codeId);
  }

  CartCode createCode(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Code name cannot be empty');
    }
    if (state.codes.any(
      (code) => code.name.toLowerCase() == normalizedName.toLowerCase(),
    )) {
      throw ArgumentError.value(name, 'name', 'This code already exists');
    }
    var suffix = 1;
    while (state.codes.any((code) => code.id == 'code_$suffix')) {
      suffix++;
    }
    final code = CartCode(id: 'code_$suffix', name: normalizedName);
    state = state.copyWith(
      codes: [...state.codes, code],
      selectedCodeId: code.id,
    );
    return code;
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
