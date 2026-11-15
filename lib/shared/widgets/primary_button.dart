// TODO: primary_button.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// White pill button. onPressed null ho to grey (disabled) dikhta hai.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 16,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        // Loading mein button white rehta hai par tap kaam nahi karta.
        onPressed: onPressed == null ? null : (isLoading ? () {} : onPressed),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.onPrimary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.textSecondary,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: TextStyle(fontSize: fontSize)),
                ],
              ),
      ),
    );
  }
}
