import 'package:flutter/foundation.dart';

class _PinRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class PinSession {
  PinSession._();

  static String? _unlockedUserId;
  static final refreshListenable = _PinRefreshNotifier();

  static bool isUnlockedFor(String userId) => _unlockedUserId == userId;

  static void unlock(String userId) {
    if (_unlockedUserId == userId) return;
    _unlockedUserId = userId;
    refreshListenable.notify();
  }

  static void lock() {
    if (_unlockedUserId == null) return;
    _unlockedUserId = null;
    refreshListenable.notify();
  }
}
