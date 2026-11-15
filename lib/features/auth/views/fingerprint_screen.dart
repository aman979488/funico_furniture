import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/pin_storage.dart';
import '../widgets/fingerprint_bottom_sheet.dart';

class FingerprintScreen extends ConsumerStatefulWidget {
  const FingerprintScreen({super.key});

  @override
  ConsumerState<FingerprintScreen> createState() => _FingerprintScreenState();
}

class _FingerprintScreenState extends ConsumerState<FingerprintScreen> {
  bool _isProcessing = false;

  Future<void> _onSkip() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await ref.read(pinStorageProvider).setFingerprintEnabled(userId, false);
    }
    if (mounted) context.go(AppRoutes.home);
  }

  Future<void> _startFingerprintAuth() async {
    if (_isProcessing) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) context.go(AppRoutes.letsYouIn);
      return;
    }

    await FingerprintBottomSheet.show(
      context: context,
      title: 'Enable Fingerprint',
      subtitle:
          'Touch the fingerprint sensor to register your biometric login.',
      onAuthenticated: () async {
        setState(() => _isProcessing = true);
        await ref.read(pinStorageProvider).setFingerprintEnabled(userId, true);
        if (mounted) {
          context.go(AppRoutes.home);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191A1F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go(AppRoutes.createPin),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Back to PIN',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Set Your Fingerprint',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add a fingerprint to make your account more secure and unlock the app faster.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9AA3B2),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),

              // Interactive sensor widget
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _startFingerprintAuth,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2430),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF5C8DFF).withValues(alpha: 0.35),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF3B82F6),
                          blurRadius: 36,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 104,
                        color: Color(0xFF8DB4FF),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Touch the sensor above to verify',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 3),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onSkip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBFC8D9),
                        side: const BorderSide(
                          color: Color(0xFF2A3347),
                          width: 1.2,
                        ),
                        backgroundColor: const Color(0xFF1C2233),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _startFingerprintAuth,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
