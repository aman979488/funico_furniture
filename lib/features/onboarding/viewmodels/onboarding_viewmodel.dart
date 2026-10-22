import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;

  Future<bool> isOnboardingSeen() => _storage.isOnboardingSeen();

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingSeen();
    notifyListeners();
  }
}