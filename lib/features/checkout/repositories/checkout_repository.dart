import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';

abstract class CheckoutRepository {
  Future<AppOrder> placeOrder(AppOrder order);
}

class CheckoutRepositoryImpl implements CheckoutRepository {
  @override
  Future<AppOrder> placeOrder(AppOrder order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return order;
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepositoryImpl(),
);
