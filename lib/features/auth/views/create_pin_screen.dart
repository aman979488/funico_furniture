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

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String _pin = '';
  String? _firstPin;
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _error;

  bool get _isComplete => _pin.length == _pinLength;

  void _onDigit(String digit) {
    if (_pin.length >= _pinLength || _isLoading) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isLoading) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _onContinue() async {
    if (!_isComplete) return;

    if (!_isConfirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
      return;
    }

    if (_pin != _firstPin) {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _error = 'PINs do not match. Try again.';
      });
      return;
    }

    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please sign in again before creating a PIN.';
      });
      return;
    }

    try {
      await ref.read(pinStorageProvider).savePin(userId, _pin);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not securely save your PIN. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    PinSession.unlock(userId);
    setState(() => _isLoading = false);

    context.go(AppRoutes.home);
  }

  void _onBack() {
    if (_isConfirming) {
      setState(() {
        _isConfirming = false;
        _firstPin = null;
        _pin = '';
        _error = null;
      });
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(AppRoutes.letsYouIn);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            _isConfirming ? 'Confirm PIN' : 'Create New PIN',
            style: GoogleFonts.urbanist(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: _onBack,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 620;
              final content = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    SizedBox(height: compact ? 12 : 24),
                    Text(
                      _isConfirming
                          ? 'Confirm your PIN to make sure it is correct.'
                          : 'Add a PIN number to make your account more secure.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: compact ? 20 : 36),
                    _buildPinBoxes(),
                    SizedBox(height: compact ? 8 : 16),
                    SizedBox(
                      height: 20,
                      child: _error == null
                          ? null
                          : Text(
                              _error!,
                              style: GoogleFonts.urbanist(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    if (compact)
                      const SizedBox(height: 12)
                    else
                      const Spacer(),
                    _buildKeypad(compact: compact),
                    SizedBox(height: compact ? 12 : 20),
                    SizedBox(
                      width: double.infinity,
                      height: compact ? 52 : 56,
                      child: FilledButton(
                        onPressed: (_isComplete && !_isLoading)
                            ? _onContinue
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.disabled,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isConfirming ? 'Confirm' : 'Continue',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _isComplete
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 20),
                  ],
                ),
              );
              final centered = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: content,
                ),
              );

              return compact
                  ? SingleChildScrollView(child: centered)
                  : centered;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPinBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < _pin.length;
        final hasError = _error != null;

        return Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
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
              ? const Text(
                  '●',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        );
      }),
    );
  }

  Widget _buildKeypad({required bool compact}) {
    final keyHeight = compact ? 48.0 : 58.0;
    final rowPadding = compact ? 4.0 : 6.0;
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: rowPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) => _buildKey(key, keyHeight)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key, double keyHeight) {
    if (key.isEmpty) return SizedBox(width: 76, height: keyHeight);

    final isBack = key == 'back';
    return Container(
      width: 76,
      height: keyHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1),
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
          onTap: () => isBack ? _onBackspace() : _onDigit(key),
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
  }
}
