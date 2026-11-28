import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cart_item.dart';

abstract class CartRepository {
  List<CartItem> getCartItems();
  Future<void> addItem(CartItem item);
  Future<void> updateQuantity(String id, int quantity);
  Future<void> removeItem(String id);
  Future<void> clearCart();
}

class CartRepositoryImpl implements CartRepository {
  final List<CartItem> _items = [];

  @override
  List<CartItem> getCartItems() => List.unmodifiable(_items);

  @override
  Future<void> addItem(CartItem item) async {
    final existingIndex = _items.indexWhere(
      (element) =>
          element.product.id == item.product.id &&
          element.codeId == item.codeId &&
          element.selectedColor == item.selectedColor,
    );

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> updateQuantity(String id, int quantity) async {
    final index = _items.indexWhere((element) => element.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
    }
  }

  @override
  Future<void> removeItem(String id) async {
    _items.removeWhere((element) => element.id == id);
  }

  @override
  Future<void> clearCart() async {
    _items.clear();
  }
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(),
);
