import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Reusable Funica brand logo badge for splash, auth, and header screens.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = 76,
    this.showText = false,
    this.textSize = 28,
    this.isDark = false,
  });

  final double size;
  final bool showText;
  final double textSize;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withValues(
              alpha: 0.22,
            ),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.chair_rounded,
          size: size * 0.54,
          color: isDark ? AppColors.primary : Colors.white,
        ),
      ),
    );

    if (!showText) return badge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: 14),
        Text(
          'Funica',
          style: GoogleFonts.urbanist(
            fontSize: textSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
