import 'package:flutter/foundation.dart';

class PinSession {
  PinSession._();

  static String? _unlockedUserId;
  static final refreshListenable = ChangeNotifier();

  static bool isUnlockedFor(String userId) => _unlockedUserId == userId;

  static void unlock(String userId) {
    if (_unlockedUserId == userId) return;
    _unlockedUserId = userId;
    refreshListenable.notifyListeners();
  }

  static void lock() {
    if (_unlockedUserId == null) return;
    _unlockedUserId = null;
    refreshListenable.notifyListeners();
  }
}
