import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';

abstract class OrdersRepository {
  List<AppOrder> getOrders();
  void addOrder(AppOrder order);
}

class OrdersRepositoryImpl implements OrdersRepository {
  final List<AppOrder> _orders = [
    AppOrder(
      id: 'order_1',
      orderNumber: 'FH-5021',
      items: const [],
      shippingType: 'Standard Delivery & Fitting',
      shippingCost: 1200.0,
      paymentMethod: 'UPI',
      subtotal: 43800.0,
      discount: 0.0,
      totalAmount: 45000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Processing',
      progressStep: 2,
    ),
    AppOrder(
      id: 'order_2',
      orderNumber: 'FH-5020',
      items: const [],
      shippingType: 'Standard Delivery & Fitting',
      shippingCost: 1200.0,
      paymentMethod: 'Credit Card',
      subtotal: 43800.0,
      discount: 0.0,
      totalAmount: 45000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      status: 'In Progress',
      progressStep: 2,
    ),
  ];

  @override
  List<AppOrder> getOrders() => List.unmodifiable(_orders);

  @override
  void addOrder(AppOrder order) {
    _orders.insert(0, order);
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(),
);
