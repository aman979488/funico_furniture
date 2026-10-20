import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class OnboardingRepository {
  // TODO: methods add karo
}

class OnboardingRepositoryImpl implements OnboardingRepository {
  // TODO: implementation
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepositoryImpl(),
);
