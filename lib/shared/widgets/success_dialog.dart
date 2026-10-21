// TODO: success_dialog.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'primary_button.dart';

/// Congratulations / success modal.
///
/// SuccessDialog.show(
///   context,
///   title: 'Congratulations!',
///   message: 'Your account is ready to use.',
///   showLoader: true,
/// );
class SuccessDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.check_rounded,
    bool showLoader = false,
    String? primaryLabel,
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: Colors.black),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (showLoader) ...[
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (primaryLabel != null) ...[
                  const SizedBox(height: 28),
                  PrimaryButton(
                    text: primaryLabel,
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onPrimary?.call();
                    },
                  ),
                ],
                if (secondaryLabel != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onSecondary?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(secondaryLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}