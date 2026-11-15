import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
import '../../../core/services/pin_storage.dart';

const _bg = Color(0xFF191A1F);
const _field = Color(0xFF1C2233);
const _border = Color(0xFF2A3347);
const _hint = Color(0xFF8A90A0);
const _accent = Color(0xFF3B82F6);

const _pinLength = 4;

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String _pin = '';
  String? _firstPin; // step 1 ka PIN
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _error;

  bool get _isComplete => _pin.length == _pinLength;

  // ---------- Keypad actions ----------
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

  // ---------- Continue ----------
  Future<void> _onContinue() async {
    if (!_isComplete) return;

    // Step 1: PIN bana liya, ab confirm karwao
    if (!_isConfirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
      return;
    }

    // Step 2: dono PIN match hone chahiye
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
    // Confirm step mein back = step 1 pe wapas
    if (_isConfirming) {
      setState(() {
        _isConfirming = false;
        _firstPin = null;
        _pin = '';
        _error = null;
      });
    } else {
      context.go(AppRoutes.fillProfile);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            title: const Text(
              'Create New PIN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
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
                        style: const TextStyle(
                          color: _hint,
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
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
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
                            backgroundColor: _accent,
                            disabledBackgroundColor: const Color(0xFF383B45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isComplete ? Colors.white : _hint,
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
      ),
    );
  }

  // ---------- PIN input ----------
  Widget _buildPinBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        return Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _field,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _error != null
                  ? Colors.redAccent
                  : index < _pin.length
                  ? _accent
                  : _border,
              width: index < _pin.length || _error != null ? 1.6 : 1,
            ),
          ),
          child: index < _pin.length
              ? const Text(
                  '●',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        );
      }),
    );
  }

  // ---------- Number keypad ----------
  Widget _buildKeypad({required bool compact}) {
    final keyHeight = compact ? 48.0 : 60.0;
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
    if (key.isEmpty) return SizedBox(width: 72, height: keyHeight);

    final isBack = key == 'back';
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => isBack ? _onBackspace() : _onDigit(key),
      child: Container(
        width: 72,
        height: keyHeight,
        alignment: Alignment.center,
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
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
