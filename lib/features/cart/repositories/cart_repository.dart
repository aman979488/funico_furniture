import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class CartRepository {
  // TODO: methods add karo
}

class CartRepositoryImpl implements CartRepository {
  // TODO: implementation
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(),
);
