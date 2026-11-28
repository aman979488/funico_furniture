import 'address.dart';
import 'cart_item.dart';

class OrderItem {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;
  final String? packageType;
  final String? material;

  const OrderItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.packageType,
    this.material,
  });

  factory OrderItem.fromCartItem(CartItem item) {
    final img = item.product.image.isNotEmpty
        ? item.product.image
        : (item.product.images.isNotEmpty ? item.product.images.first : '');
    return OrderItem(
      id: item.id,
      title: item.product.name,
      imageUrl: img,
      price: item.product.price,
      quantity: item.quantity,
      packageType: item.product.category,
      material: item.product.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'packageType': packageType,
      'material': material,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      packageType: map['packageType'] as String?,
      material: map['material'] as String?,
    );
  }
}

class AppOrder {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final Address? shippingAddress;
  final String shippingType;
  final double shippingCost;
  final String paymentMethod;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final DateTime createdAt;
  final String status; // 'Processing', 'In Progress', 'Completed', 'Cancelled'
  final int progressStep; // 1, 2, 3, 4

  const AppOrder({
    required this.id,
    required this.orderNumber,
    required this.items,
    this.shippingAddress,
    required this.shippingType,
    required this.shippingCost,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.createdAt,
    this.status = 'Processing',
    this.progressStep = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'items': items.map((i) => i.toMap()).toList(),
      'shippingAddress': shippingAddress?.toMap(),
      'shippingType': shippingType,
      'shippingCost': shippingCost,
      'paymentMethod': paymentMethod,
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'progressStep': progressStep,
    };
  }

  factory AppOrder.fromMap(Map<String, dynamic> map) {
    return AppOrder(
      id: map['id'] as String? ?? '',
      orderNumber: map['orderNumber'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      shippingAddress: map['shippingAddress'] != null
          ? Address.fromMap(map['shippingAddress'] as Map<String, dynamic>)
          : null,
      shippingType:
          map['shippingType'] as String? ?? 'Standard Delivery & Fitting',
      shippingCost: (map['shippingCost'] as num?)?.toDouble() ?? 1200.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'UPI',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] as String? ?? 'Processing',
      progressStep: (map['progressStep'] as num?)?.toInt() ?? 1,
    );
  }
}
