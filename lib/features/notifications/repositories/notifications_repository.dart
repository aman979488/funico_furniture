import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NotificationsRepository {
  // TODO: methods add karo
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  // TODO: implementation
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(),
);
