import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:funica/core/theme/app_colors.dart';
import 'package:funica/core/theme/app_theme.dart';
import 'package:funica/features/auth/views/forgot_password_screen.dart';
import 'package:funica/features/auth/views/login_screen.dart';
import 'package:funica/features/auth/views/signup_screen.dart';
import 'package:funica/features/onboarding/views/splash_screen.dart';
import 'package:funica/shared/widgets/app_brand_logo.dart';
import 'package:funica/shared/widgets/auth_input_field.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: child,
      ),
    );
  }

  testWidgets('SplashScreen renders with Funica brand badge and primary loader',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const SplashScreen()));

    expect(find.byType(AppBrandLogo), findsOneWidget);
    expect(find.text('Funica'), findsOneWidget);
    expect(find.text('Modern Furniture & Interior'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.background);

    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(progress.color, AppColors.primary);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('LoginScreen renders with AppColors.background and brand logo',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const LoginScreen()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.background);

    expect(find.byType(AppBrandLogo), findsOneWidget);
    expect(find.text('Login to Your Account'), findsOneWidget);
    expect(find.byType(AuthInputField), findsNWidgets(2));
  });

  testWidgets('SignupScreen renders with warm background and fields',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const SignupScreen()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.background);

    expect(find.byType(AppBrandLogo), findsOneWidget);
    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.byType(AuthInputField), findsNWidgets(3));
  });

  testWidgets('ForgotPasswordScreen renders with warm theme', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const ForgotPasswordScreen()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.background);

    expect(find.byType(AppBrandLogo), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.byType(AuthInputField), findsOneWidget);
  });
}
