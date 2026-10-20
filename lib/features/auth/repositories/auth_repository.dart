import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AuthRepository {
  // TODO: methods add karo
}

class AuthRepositoryImpl implements AuthRepository {
  // TODO: implementation
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);
