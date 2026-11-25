import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_brand_logo.dart';
import '../../../shared/widgets/auth_input_field.dart';
import '../widgets/auth_components.dart';
import '../viewmodels/auth_viewmodel.dart';

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

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final signedIn = await ref
        .read(authViewModelProvider.notifier)
        .signIn(email: _emailCtrl.text, password: _passCtrl.text);
    if (!mounted) return;

    if (signedIn) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not complete sign-in.')),
        );
        return;
      }
      PinSession.unlock(user.uid);
      context.go(AppRoutes.home);
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

    if (authState.isNewGoogleUser) {
      context.go(
        AppRoutes.fillProfile,
        extra: {'name': user.displayName ?? '', 'email': user.email ?? ''},
      );
    } else {
      PinSession.unlock(user.uid);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                    const SizedBox(height: 20),

                    // ---------- Logo ----------
                    const AppBrandLogo(size: 72),
                    const SizedBox(height: 18),

                    // ---------- Title ----------
                    Text(
                      _Txt.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---------- Fields ----------
                    AuthInputField(
                      controller: _emailCtrl,
                      hint: _Txt.email,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 16),
                    AuthInputField(
                      controller: _passCtrl,
                      hint: _Txt.password,
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (_allFilled && !authState.isLoading) _onLogin();
                      },
                    ),
                    const SizedBox(height: 14),

                    // ---------- Forgot password ----------
                    Center(
                      child: TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
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
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ---------- Login button ----------
                    ListenableBuilder(
                      listenable: Listenable.merge([_emailCtrl, _passCtrl]),
                      builder: (context, _) {
                        final filled = _allFilled;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.primary
                                : AppColors.disabled,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: filled
                                ? const [
                                    BoxShadow(
                                      color: Color(0x33D66B2C),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ]
                                : null,
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
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _Txt.login,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: filled
                                              ? Colors.white
                                              : AppColors.textSecondary,
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
                        const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
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
                        const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
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
                            size: 24,
                            color: Color(0xFFEA4335),
                          ),
                          onTap: authState.isLoading ? null : _google,
                        ),
                        const SizedBox(width: 16),
                        _SocialSquare(
                          icon: const FaIcon(
                            FontAwesomeIcons.apple,
                            size: 26,
                            color: AppColors.textPrimary,
                          ),
                          onTap: () {},
                        ),
                        const SizedBox(width: 16),
                        _SocialSquare(
                          icon: const FaIcon(
                            FontAwesomeIcons.facebook,
                            size: 24,
                            color: Color(0xFF1877F2),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ---------- Don't have an account? ----------
                    AuthFooter(
                      prompt: _Txt.noAccount,
                      action: _Txt.signUp,
                      onTap: () => context.pushReplacement(AppRoutes.signup),
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
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A24211F),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
