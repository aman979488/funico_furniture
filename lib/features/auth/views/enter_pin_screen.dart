import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
import '../../../core/services/pin_storage.dart';
import '../../../core/theme/app_colors.dart';

const _pinLength = 4;

class EnterPinScreen extends ConsumerStatefulWidget {
  const EnterPinScreen({super.key});

  @override
  ConsumerState<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends ConsumerState<EnterPinScreen> {
  String _pin = '';
  String? _savedPin;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) context.go(AppRoutes.letsYouIn);
      return;
    }

    try {
      final pin = await ref.read(pinStorageProvider).readPin(userId);
      if (!mounted) return;
      if (pin == null) {
        setState(() {
          _isLoading = false;
          _error = 'No saved PIN was found. Sign out and try again.';
        });
        return;
      }
      setState(() {
        _savedPin = pin;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not access your saved PIN. Please retry.';
      });
    }
  }

  void _onDigit(String digit) {
    if (_isLoading || _error != null || _pin.length == _pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == _pinLength) _verifyPin();
  }

  Future<void> _verifyPin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) context.go(AppRoutes.letsYouIn);
      return;
    }

    if (_pin == _savedPin) {
      HapticFeedback.lightImpact();
      PinSession.unlock(userId);
      if (mounted) context.go(AppRoutes.home);
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _pin = '';
      _error = 'Incorrect PIN. Try again.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _error = null);
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isLoading || _error != null) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onLogoutAndReset() async {
    try {
      await FirebaseAuth.instance.signOut();
      PinSession.lock();
      if (mounted) context.go(AppRoutes.letsYouIn);
    } catch (_) {
      if (mounted) context.go(AppRoutes.letsYouIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.accentLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1AD66B2C),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter your PIN',
                    style: GoogleFonts.urbanist(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter the 4-digit PIN you created to unlock your account.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pinLength,
                      (index) {
                        final isFilled = index < _pin.length;
                        final hasError = _error != null;

                        return Container(
                          width: 58,
                          height: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasError
                                  ? AppColors.error
                                  : isFilled
                                      ? AppColors.primary
                                      : AppColors.border,
                              width: isFilled || hasError ? 1.6 : 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A24211F),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isFilled
                              ? const Icon(
                                  Icons.circle,
                                  color: AppColors.primary,
                                  size: 14,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primary,
                              ),
                            )
                          : _error != null
                              ? Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.urbanist(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                    ),
                  ),
                  if (_error != null && _savedPin == null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _loadPin();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else ...[
                    _buildKeypad(),
                    const SizedBox(height: 20),
                  ],
                  TextButton(
                    onPressed: _onLogoutAndReset,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'Forgot PIN? Sign out & log in again',
                      style: GoogleFonts.urbanist(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 76, height: 56);

              final isBack = key == 'back';

              return Container(
                width: 76,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0824211F),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: isBack ? _onBackspace : () => _onDigit(key),
                    child: Center(
                      child: isBack
                          ? const Icon(
                              Icons.backspace_outlined,
                              color: AppColors.textPrimary,
                              size: 22,
                            )
                          : Text(
                              key,
                              style: GoogleFonts.urbanist(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
