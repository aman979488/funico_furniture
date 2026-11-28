import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final isSignedIn =
        Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
    try {
      context.go(isSignedIn ? AppRoutes.home : AppRoutes.onboarding);
    } catch (_) {
      // Safe fallback for tests without GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Column(
          children: [
            const Spacer(flex: 9),
            const SizedBox(height: 24),
            const AppBrandLogo(
              size: 88,
              showText: true,
              textSize: 36,
            ),
            const SizedBox(height: 10),
            Text(
              'Modern Furniture & Interior',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(flex: 5),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 52),
          ],
        ),
      ),
    );
  }
}
