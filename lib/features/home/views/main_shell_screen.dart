import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  final Widget child;
  final String currentLocation;

  static const _tabs = [
    (label: 'Home', route: AppRoutes.home),
    (label: 'Estimator', route: AppRoutes.estimator),
    (label: 'Cart', route: AppRoutes.cart),
    (label: 'Orders', route: AppRoutes.orders),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1EAE4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: _NavigationTab(
                    label: tab.label,
                    selected: currentLocation == tab.route,
                    onTap: () => context.go(tab.route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationTab extends StatelessWidget {
  const _NavigationTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = const Color(0xFF24211F);
    final color = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFDE5D4) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                style: GoogleFonts.urbanist(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: switch (label) {
          'Home' => Icon(Icons.home_outlined, size: 23, color: color),
          'Estimator' => CustomPaint(
            size: const Size(22, 22),
            painter: _EstimatorNavIconPainter(color: color),
          ),
          'Cart' => Icon(Icons.shopping_cart_outlined, size: 22, color: color),
          'Orders' => CustomPaint(
            size: const Size(22, 22),
            painter: _ShoppingBagNavIconPainter(color: color),
          ),
          _ => Icon(Icons.circle_outlined, size: 22, color: color),
        },
      ),
    );
  }
}

class _EstimatorNavIconPainter extends CustomPainter {
  const _EstimatorNavIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Outer rounded square blueprint border
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.10, w * 0.80, h * 0.80),
      const Radius.circular(4),
    );
    canvas.drawRRect(outer, paint);

    // Inner floor plan partition lines
    // Horizontal divider (left to center)
    canvas.drawLine(
      Offset(w * 0.10, h * 0.52),
      Offset(w * 0.56, h * 0.52),
      paint,
    );
    // Vertical divider (top to middle)
    canvas.drawLine(
      Offset(w * 0.56, h * 0.10),
      Offset(w * 0.56, h * 0.70),
      paint,
    );
    // Small lower divider
    canvas.drawLine(
      Offset(w * 0.36, h * 0.52),
      Offset(w * 0.36, h * 0.90),
      paint,
    );
    // Small square/symbol in bottom-right room
    final dotRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.66, h * 0.62, w * 0.13, h * 0.13),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(dotRect, paint);
  }

  @override
  bool shouldRepaint(covariant _EstimatorNavIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ShoppingBagNavIconPainter extends CustomPainter {
  const _ShoppingBagNavIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Bag body
    final bag = Path()
      ..moveTo(w * 0.22, h * 0.34)
      ..lineTo(w * 0.78, h * 0.34)
      ..lineTo(w * 0.85, h * 0.88)
      ..lineTo(w * 0.15, h * 0.88)
      ..close();
    canvas.drawPath(bag, paint);

    // Handle loop
    final handleRect = Rect.fromLTWH(w * 0.34, h * 0.14, w * 0.32, h * 0.38);
    canvas.drawArc(handleRect, 3.14159, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ShoppingBagNavIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
