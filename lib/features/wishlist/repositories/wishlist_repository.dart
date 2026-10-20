import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WishlistRepository {
  // TODO: methods add karo
}

class WishlistRepositoryImpl implements WishlistRepository {
  // TODO: implementation
}

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepositoryImpl(),
);
