import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ProfileRepository {
  // TODO: methods add karo
}

class ProfileRepositoryImpl implements ProfileRepository {
  // TODO: implementation
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(),
);
