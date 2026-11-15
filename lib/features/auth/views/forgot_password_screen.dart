import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_input_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _onSendResetLink() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final sent = await ref
        .read(authViewModelProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text.trim());
    if (!mounted) return;

    final message = sent
        ? 'If an account exists for this email, a password reset link has been sent.'
        : ref.read(authViewModelProvider).error ??
              'Could not send the password reset email.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
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
                      Text(
                        'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your email address and we’ll send you a link to reset your password.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AuthInputField(
                        controller: _emailController,
                        hint: 'Email address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: _validateEmail,
                        autofillHints: const [AutofillHints.email],
                        onSubmitted: (_) {
                          if (!authState.isLoading) _onSendResetLink();
                        },
                      ),
                      const SizedBox(height: 28),
                      ListenableBuilder(
                        listenable: _emailController,
                        builder: (context, _) {
                          final emailEntered = _emailController.text
                              .trim()
                              .isNotEmpty;
                          final canSubmit =
                              emailEntered && !authState.isLoading;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 58,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: emailEntered
                                  ? Colors.white
                                  : AppColors.disabled,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: canSubmit ? _onSendResetLink : null,
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
                                          'Send Reset Link',
                                          style: GoogleFonts.urbanist(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: emailEntered
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password?',
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () =>
                                context.pushReplacement(AppRoutes.login),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              child: Text(
                                'Login',
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
      ),
    );
  }
}
