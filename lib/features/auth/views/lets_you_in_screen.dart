import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/social_button.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Reference design ke measurements ek jagah. Kuch adjust karna ho toh
/// sirf yahan badlo.
class _Dim {
  _Dim._();

  static const double sideMargin = 28;
  static const double topGap = 48;
  static const double heroSize = 190;
  static const double heroToTitle = 16;
  static const double titleSize = 44;
  static const double titleToButtons = 28;
  static const double socialHeight = 60;
  static const double socialFont = 17;
  static const double socialGap = 14;
  static const double minGapBeforeCreate = 24;
  static const double createHeight = 60;
  static const double createFont = 19;
  static const double createToLogin = 32;
  static const double bottomText = 15;
  static const double bottomGap = 40;

  /// Isse chhoti screen pe layout compress hone ke bajay scroll hoga
  static const double minContentHeight = 720;
}

class LetsYouInScreen extends ConsumerStatefulWidget {
  const LetsYouInScreen({super.key});

  @override
  ConsumerState<LetsYouInScreen> createState() => _LetsYouInScreenState();
}

class _LetsYouInScreenState extends ConsumerState<LetsYouInScreen> {
  Future<void> _google() async {
    final signedIn = await ref
        .read(authViewModelProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;

    final authState = ref.read(authViewModelProvider);
    if (!signedIn) {
      final message = authState.error;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error),
          );
      }
      return;
    }

    if (authState.isNewGoogleUser) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not complete Google sign-in.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      context.go(
        AppRoutes.fillProfile,
        extra: {'name': user.displayName ?? '', 'email': user.email ?? ''},
      );
    } else {
      PinSession.lock();
      context.go(AppRoutes.enterPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Column ko definite height milti hai, isliye Spacer
                // hamesha bachi hui jagah bharta hai
                final height = math.max(
                  constraints.maxHeight,
                  _Dim.minContentHeight,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _Dim.sideMargin,
                  ),
                  child: SizedBox(
                    height: height,
                    child: Column(
                      children: [
                        const SizedBox(height: _Dim.topGap),

                        // ---------- Illustration (circle, bina border) ----------
                        ClipOval(
                          child: Image.asset(
                            AppAssets.homeDesignLogo,
                            height: _Dim.heroSize,
                            width: _Dim.heroSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: _Dim.heroSize,
                              width: _Dim.heroSize,
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chair_alt,
                                size: 80,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _Dim.heroToTitle),

                        // ---------- Title ----------
                        const Text(
                          AppStrings.letsYouIn,
                          style: TextStyle(
                            fontSize: _Dim.titleSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: _Dim.titleToButtons),

                        // ---------- Social buttons ----------
                        _PressScale(
                          child: SocialButton(
                            height: _Dim.socialHeight,
                            fontSize: _Dim.socialFont,
                            icon: const FaIcon(
                              FontAwesomeIcons.google,
                              size: 22,
                              color: Color(0xFFEA4335),
                            ),
                            label: AppStrings.continueWithGoogle,
                            onPressed: isLoading ? null : _google,
                          ),
                        ),
                        const SizedBox(height: _Dim.socialGap),
                        _PressScale(
                          child: SocialButton(
                            height: _Dim.socialHeight,
                            fontSize: _Dim.socialFont,
                            icon: const FaIcon(
                              FontAwesomeIcons.apple,
                              size: 24,
                              color: Colors.white,
                            ),
                            label: AppStrings.continueWithApple,
                            onPressed: () {
                              // TODO: Apple sign-in baad mein
                            },
                          ),
                        ),
                        const SizedBox(height: _Dim.socialGap),
                        _PressScale(
                          child: SocialButton(
                            height: _Dim.socialHeight,
                            fontSize: _Dim.socialFont,
                            icon: const FaIcon(
                              FontAwesomeIcons.facebook,
                              size: 23,
                              color: Color(0xFF1877F2),
                            ),
                            label: AppStrings.continueWithFacebook,
                            onPressed: () {
                              // TODO: Facebook sign-in baad mein
                            },
                          ),
                        ),

                        // Beech ki flexible khali jagah (reference jaisi)
                        const Spacer(),
                        const SizedBox(height: _Dim.minGapBeforeCreate),

                        // ---------- Create account ----------
                        _PressScale(
                          child: PrimaryButton(
                            height: _Dim.createHeight,
                            fontSize: _Dim.createFont,
                            text: AppStrings.createAccount,
                            onPressed: () => context.push(AppRoutes.signup),
                          ),
                        ),
                        const SizedBox(height: _Dim.createToLogin),

                        // ---------- Already have account ----------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              AppStrings.alreadyHaveAccount,
                              style: TextStyle(
                                fontSize: _Dim.bottomText,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => context.push(AppRoutes.login),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: Text(
                                  AppStrings.login,
                                  style: TextStyle(
                                    fontSize: _Dim.bottomText,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _Dim.bottomGap),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Dabane pe button thoda chhota hota hai (press effect), chhodne pe wapas.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
