import 'product.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.codeId = 'code_1',
    this.selectedColor,
  });

  final String id;
  final Product product;
  final int quantity;
  final String codeId;
  final int? selectedColor;

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? codeId,
    int? selectedColor,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      codeId: codeId ?? this.codeId,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'codeId': codeId,
      'selectedColor': selectedColor,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String? ?? '',
      product: Product.fromMap(map['product'] as Map<String, dynamic>? ?? {}),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      codeId: map['codeId'] as String? ?? 'code_1',
      selectedColor: (map['selectedColor'] as num?)?.toInt(),
    );
  }
}
