// TODO: storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _onboardingSeenKey = 'onboarding_seen';

  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}