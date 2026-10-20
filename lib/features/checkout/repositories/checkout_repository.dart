import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class CheckoutRepository {
  // TODO: methods add karo
}

class CheckoutRepositoryImpl implements CheckoutRepository {
  // TODO: implementation
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepositoryImpl(),
);
