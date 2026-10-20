import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class OrdersRepository {
  // TODO: methods add karo
}

class OrdersRepositoryImpl implements OrdersRepository {
  // TODO: implementation
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(),
);
