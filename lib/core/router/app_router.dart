// TODO: app_router.dart
import 'package:go_router/go_router.dart';

import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/lets_you_in_screen.dart';
import '../../features/auth/views/signup_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/onboarding/views/splash_screen.dart';

/// Saare route paths ek jagah. Navigate karne ke liye:
/// context.go(AppRoutes.login);   (replace)
/// context.push(AppRoutes.signup); (upar stack karna)
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const letsYouIn = '/lets-you-in';
  static const signup = '/signup';
  static const login = '/login';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.letsYouIn,
      builder: (context, state) => const LetsYouInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    // Naya screen banao to yahan route add karte jao.
  ],
);