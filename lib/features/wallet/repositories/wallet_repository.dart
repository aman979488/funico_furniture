import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WalletRepository {
  // TODO: methods add karo
}

class WalletRepositoryImpl implements WalletRepository {
  // TODO: implementation
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(),
);
