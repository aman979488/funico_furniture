import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
import '../../../core/services/pin_storage.dart';

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
      backgroundColor: const Color(0xFF191A1F),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF8DB4FF),
                    size: 52,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Enter your PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter the 4-digit PIN you created to unlock your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9AA3B2), fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pinLength,
                      (index) => Container(
                        width: 58,
                        height: 58,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2233),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _error != null
                                ? Colors.redAccent
                                : const Color(0xFF2A3347),
                          ),
                        ),
                        child: index < _pin.length
                            ? const Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 12,
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : _error != null
                          ? Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
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
                      child: const Text('Retry'),
                    )
                  else
                    _buildKeypad(),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _onLogoutAndReset,
                    child: const Text(
                      'Forgot PIN? Sign out & log in again',
                      style: TextStyle(
                        color: Color(0xFF8DB4FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 72, height: 58);

            final isBack = key == 'back';

            return SizedBox(
              width: 72,
              height: 58,
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: isBack ? _onBackspace : () => _onDigit(key),
                child: isBack
                    ? const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white,
                        size: 24,
                      )
                    : Text(
                        key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
