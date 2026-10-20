import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class SearchRepository {
  // TODO: methods add karo
}

class SearchRepositoryImpl implements SearchRepository {
  // TODO: implementation
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(),
);
