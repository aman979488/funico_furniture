import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HomeRepository {
  // TODO: methods add karo
}

class HomeRepositoryImpl implements HomeRepository {
  // TODO: implementation
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(),
);
