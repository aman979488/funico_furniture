import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HelpRepository {
  // TODO: methods add karo
}

class HelpRepositoryImpl implements HelpRepository {
  // TODO: implementation
}

final helpRepositoryProvider = Provider<HelpRepository>(
  (ref) => HelpRepositoryImpl(),
);
