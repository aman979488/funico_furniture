import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// App me fingerprint ka bottom sheet / pop-up box jo niche se drag hoke aata hai
/// Uses the device's native biometric prompt for fingerprint verification.
class FingerprintBottomSheet extends StatefulWidget {
  const FingerprintBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onAuthenticated,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAuthenticated;
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onAuthenticated,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191F2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => FingerprintBottomSheet(
        title: title,
        subtitle: subtitle,
        onAuthenticated: onAuthenticated,
      ),
    );
  }

  @override
  State<FingerprintBottomSheet> createState() => _FingerprintBottomSheetState();
}

class _FingerprintBottomSheetState extends State<FingerprintBottomSheet>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isSuccess = false;
  bool _isAuthenticating = false;
  String? _statusText;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    if (kIsWeb || _isSuccess || _isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusText = 'Waiting for fingerprint verification...';
    });
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        if (mounted) {
          setState(() {
            _statusText = 'Fingerprint authentication is unavailable.';
          });
        }
        return;
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        if (mounted) {
          setState(() {
            _statusText = 'No fingerprint is enrolled on this device.';
          });
        }
        return;
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: widget.title,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuth && mounted) {
        _onVerificationSuccess();
      } else if (mounted) {
        setState(() {
          _statusText = 'Fingerprint not verified. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusText = 'Fingerprint verification failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _onVerificationSuccess() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSuccess = true;
      _statusText = 'Fingerprint verified!';
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onAuthenticated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B4861),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Icon / Sensor with pulse effect
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _pulseController.value;
                final ringColor = _isSuccess
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6)
                          .withValues(alpha: 0.2 + (pulse * 0.3));

                return Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isAuthenticating
                        ? null
                        : _authenticateWithBiometrics,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? const Color(0xFF0F3A2E)
                            : const Color(0xFF1F2B42),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSuccess
                              ? const Color(0xFF10B981)
                              : ringColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isSuccess
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.25 * pulse),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSuccess
                            ? Icons.check_rounded
                            : Icons.fingerprint_rounded,
                        size: 56,
                        color: _isSuccess
                            ? const Color(0xFF34D399)
                            : const Color(0xFF8DB4FF),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText ?? widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isSuccess
                    ? const Color(0xFF34D399)
                    : const Color(0xFF9AA3B2),
                fontSize: 14,
                fontWeight: _isSuccess ? FontWeight.w600 : FontWeight.w400,
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBFC8D9),
                      side: const BorderSide(color: Color(0xFF2E3A52)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (!_isSuccess) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isAuthenticating
                          ? null
                          : _authenticateWithBiometrics,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isAuthenticating ? 'Waiting...' : 'Touch Sensor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
