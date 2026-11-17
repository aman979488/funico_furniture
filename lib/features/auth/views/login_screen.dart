import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_input_field.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Is screen ke texts
class _Txt {
  _Txt._();
  static const title = 'Login to Your Account';
  static const email = 'Email address';
  static const password = 'Password';
  static const forgot = 'Forgot password?';
  static const login = 'Login';
  static const orLoginWith = 'or login with';
  static const noAccount = "Don't have an account?";
  static const signUp = 'Sign Up';
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool get _allFilled =>
      _emailCtrl.text.trim().isNotEmpty && _passCtrl.text.isNotEmpty;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ---------- Validators ----------
  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your email address';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    return null;
  }

  // ---------- Submit ----------
  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final signedIn = await ref
        .read(authViewModelProvider.notifier)
        .signIn(email: _emailCtrl.text, password: _passCtrl.text);
    if (!mounted) return;

    if (signedIn) {
      PinSession.lock();
      context.go(AppRoutes.enterPin);
      return;
    }

    final message =
        ref.read(authViewModelProvider).error ?? 'Could not log in.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
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
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.letsYouIn);
            }
          },
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // ---------- Logo ----------
                    Image.asset(
                      AppAssets.logo,
                      height: 80,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.chair_alt,
                        size: 80,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------- Title ----------
                    Text(
                      _Txt.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---------- Fields ----------
                    AuthInputField(
                      controller: _emailCtrl,
                      hint: _Txt.email,
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 16),
                    AuthInputField(
                      controller: _passCtrl,
                      hint: _Txt.password,
                      icon: Icons.lock,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (_allFilled && !authState.isLoading) _onLogin();
                      },
                    ),
                    const SizedBox(height: 14),

                    // ---------- Forgot password (beech mein) ----------
                    Center(
                      child: TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _Txt.forgot,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---------- Login button (grey -> white) ----------
                    ListenableBuilder(
                      listenable: Listenable.merge([_emailCtrl, _passCtrl]),
                      builder: (context, _) {
                        final filled = _allFilled;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 58,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: filled ? Colors.white : AppColors.disabled,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: (filled && !authState.isLoading)
                                  ? _onLogin
                                  : null,
                              child: Center(
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        _Txt.login,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: filled
                                              ? Colors.black
                                              : Colors.white70,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // ---------- Divider ----------
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _Txt.orLoginWith,
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ---------- Social boxes ----------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialSquare(
                          icon: const FaIcon(
                            FontAwesomeIcons.google,
                            size: 26,
                            color: Color(0xFFEA4335),
                          ),
                          onTap: authState.isLoading ? null : _google,
                        ),
                        const SizedBox(width: 16),
                        _SocialSquare(
                          icon: const FaIcon(
                            FontAwesomeIcons.apple,
                            size: 28,
                            color: Colors.white,
                          ),
                          onTap: () {
                            // TODO: Apple sign-in
                          },
                        ),
                        const SizedBox(width: 16),
                        _SocialSquare(
                          icon: const FaIcon(
                            FontAwesomeIcons.facebook,
                            size: 26,
                            color: Color(0xFF1877F2),
                          ),
                          onTap: () {
                            // TODO: Facebook sign-in
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ---------- Don't have an account? ----------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _Txt.noAccount,
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () =>
                              context.pushReplacement(AppRoutes.signup),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Text(
                              _Txt.signUp,
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialSquare extends StatelessWidget {
  const _SocialSquare({required this.icon, required this.onTap});

  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(width: 64, height: 64, child: Center(child: icon)),
      ),
    );
  }
}
