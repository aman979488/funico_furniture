import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ProductRepository {
  // TODO: methods add karo
}

class ProductRepositoryImpl implements ProductRepository {
  // TODO: implementation
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(),
);
