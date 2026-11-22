import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class EstimatorScreen extends StatefulWidget {
  const EstimatorScreen({super.key});

  @override
  State<EstimatorScreen> createState() => _EstimatorScreenState();
}

class _EstimatorScreenState extends State<EstimatorScreen> {
  String _selectedProperty = '2 BHK';
  String _selectedTier = 'Modern';
  final Set<String> _selectedScopes = {
    'Modular Kitchen',
    'Wardrobes',
    'False Ceiling & Lights',
    'Wall Painting',
  };

  static const _propertyTypes = [
    '1 BHK',
    '2 BHK',
    '3 BHK',
    'Villa',
    'Studio',
  ];

  static const _tiers = [
    'Basic',
    'Deluxe',
    'Modern',
    'Premium',
    'Luxury',
  ];

  static const _scopes = [
    ('Modular Kitchen', Icons.kitchen_outlined, 2200),
    ('Wardrobes', Icons.door_sliding_outlined, 1600),
    ('False Ceiling & Lights', Icons.light_outlined, 950),
    ('Wall Painting', Icons.format_paint_outlined, 750),
    ('Living Room Decor', Icons.chair_outlined, 1400),
    ('Flooring & Tiling', Icons.grid_view_outlined, 1100),
  ];

  double get _estimatedTotal {
    double base = switch (_selectedProperty) {
      '1 BHK' => 3500,
      '2 BHK' => 5200,
      '3 BHK' => 7800,
      'Villa' => 12500,
      'Studio' => 2800,
      _ => 5000,
    };

    double tierMultiplier = switch (_selectedTier) {
      'Basic' => 0.85,
      'Deluxe' => 1.05,
      'Modern' => 1.20,
      'Premium' => 1.45,
      'Luxury' => 1.80,
      _ => 1.0,
    };

    double scopeSum = 0;
    for (final scope in _scopes) {
      if (_selectedScopes.contains(scope.$1)) {
        scopeSum += scope.$3;
      }
    }

    return (base + scopeSum) * tierMultiplier;
  }

  void _bookConsultation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Estimate Requested!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our interior design specialist will reach out within 24 hours with a detailed 3D design blueprint and itemized quotation.',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF2EB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Free 3D Layout + Free Site Measurement Included',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Great, Got It',
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _estimatedTotal;
    final minEst = (estimate * 0.92).round();
    final maxEst = (estimate * 1.08).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Interior Estimator',
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF281E17), Color(0xFF453429)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'INSTANT ESTIMATE',
                        style: GoogleFonts.urbanist(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Color(0xFFD5CCC3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '30-45 Days Delivery',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: const Color(0xFFD5CCC3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '\$$minEst - \$$maxEst',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Approximate budget for $_selectedProperty ($_selectedTier Tier)',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: const Color(0xFFD5CCC3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Property Type
          Text(
            '1. Select Property Configuration',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _propertyTypes.map((prop) {
                final isSel = _selectedProperty == prop;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(prop),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedProperty = prop),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      color: isSel ? Colors.white : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSel ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 22),

          // Interior Tier (Basic, Deluxe, Modern, Premium, Luxury)
          Text(
            '2. Select Interior Tier',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tiers.map((tier) {
                final isSel = _selectedTier == tier;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTier = tier),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        tier,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                          color: isSel ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 22),

          // Scope of Work
          Text(
            '3. Scope of Work',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ..._scopes.map((scope) {
            final checked = _selectedScopes.contains(scope.$1);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: checked
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
              child: CheckboxListTile(
                value: checked,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                secondary: Icon(
                  scope.$2,
                  color: checked ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(
                  scope.$1,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: checked ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Starting from ~\$${scope.$3}',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedScopes.add(scope.$1);
                    } else {
                      _selectedScopes.remove(scope.$1);
                    }
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 24),

          // Call to action
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _bookConsultation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.architecture_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Book Free Site Consultation',
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
