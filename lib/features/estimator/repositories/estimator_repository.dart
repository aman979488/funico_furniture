import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/estimator_model.dart';

class EstimatorRepository {
  static const _quotesKey = 'saved_interior_quotes_cache';

  EstimatorQuote calculateEstimate({
    required String quoteName,
    required String bhk,
    required String purpose,
    required String packageId,
  }) {
    final bhkConfig = BhkConfig.allConfigs.firstWhere(
      (c) => c.bhk.toUpperCase() == bhk.toUpperCase(),
      orElse: () => BhkConfig.allConfigs.first,
    );

    final purposeInfo = EstimatorPurposeInfo.allPurposes.firstWhere(
      (p) => p.id.toLowerCase() == purpose.toLowerCase(),
      orElse: () => EstimatorPurposeInfo.allPurposes.first,
    );

    final package = PackageConfig.allPackages.firstWhere(
      (pkg) => pkg.id.toLowerCase() == packageId.toLowerCase(),
      orElse: () => PackageConfig.allPackages[1], // default modern
    );

    final area = bhkConfig.approxAreaSqFt;
    final baseCost = area * package.ratePerSqFt;
    final multiplier = purposeInfo.multiplier;

    final estimatedAvg = baseCost * multiplier;
    final minCost = estimatedAvg * 0.90;
    final maxCost = estimatedAvg * 1.10;

    // Room breakdown (approximate percentage share)
    final roomBreakdown = <String, double>{
      'Modular Kitchen': estimatedAvg * 0.32,
      'Living & Dining': estimatedAvg * 0.28,
      'Bedrooms & Wardrobes': estimatedAvg * 0.25,
      'Bathrooms & Lighting': estimatedAvg * 0.10,
      'Civil, Paint & Electrical': estimatedAvg * 0.05,
    };

    return EstimatorQuote(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      quoteName: quoteName.trim().isEmpty ? 'Quote 1' : quoteName.trim(),
      bhk: bhkConfig.bhk,
      purpose: purposeInfo.label,
      packageTitle: package.title,
      ratePerSqFt: package.ratePerSqFt,
      approxAreaSqFt: area,
      estimatedCostMin: minCost,
      estimatedCostMax: maxCost,
      createdAt: DateTime.now(),
      roomBreakdown: roomBreakdown,
    );
  }

  Future<List<EstimatorQuote>> loadSavedQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_quotesKey);
      if (jsonList == null || jsonList.isEmpty) {
        // Return default starter quote for demo if empty
        return [
          EstimatorQuote(
            id: 'sample_quote_1',
            quoteName: 'Dream 2BHK Renovation',
            bhk: '2BHK',
            purpose: 'Renovate',
            packageTitle: 'Modern Package',
            ratePerSqFt: 1500,
            approxAreaSqFt: 960,
            estimatedCostMin: 1296000,
            estimatedCostMax: 1584000,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            roomBreakdown: const {
              'Modular Kitchen': 460000,
              'Living & Dining': 403000,
              'Bedrooms & Wardrobes': 360000,
              'Bathrooms & Lighting': 144000,
              'Civil, Paint & Electrical': 73000,
            },
          ),
        ];
      }

      return jsonList.map((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final breakdownMap =
            (map['roomBreakdown'] as Map<String, dynamic>?) ?? {};
        final convertedBreakdown = breakdownMap.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );

        return EstimatorQuote(
          id: map['id'] as String,
          quoteName: map['quoteName'] as String,
          bhk: map['bhk'] as String,
          purpose: map['purpose'] as String,
          packageTitle: (map['packageTitle'] as String?) ?? 'Modern Package',
          ratePerSqFt: (map['ratePerSqFt'] as num?)?.toDouble() ?? 1500,
          approxAreaSqFt: (map['approxAreaSqFt'] as num?)?.toInt() ?? 960,
          estimatedCostMin: (map['estimatedCostMin'] as num).toDouble(),
          estimatedCostMax: (map['estimatedCostMax'] as num).toDouble(),
          createdAt:
              DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                  DateTime.now(),
          roomBreakdown: convertedBreakdown,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQuote(EstimatorQuote quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotes = await loadSavedQuotes();
      // Remove any with same id
      quotes.removeWhere((q) => q.id == quote.id);
      quotes.insert(0, quote);

      final encoded = quotes.map((q) => jsonEncode({
            'id': q.id,
            'quoteName': q.quoteName,
            'bhk': q.bhk,
            'purpose': q.purpose,
            'packageTitle': q.packageTitle,
            'ratePerSqFt': q.ratePerSqFt,
            'approxAreaSqFt': q.approxAreaSqFt,
            'estimatedCostMin': q.estimatedCostMin,
            'estimatedCostMax': q.estimatedCostMax,
            'createdAt': q.createdAt.toIso8601String(),
            'roomBreakdown': q.roomBreakdown,
          })).toList();

      await prefs.setStringList(_quotesKey, encoded);
    } catch (_) {}
  }

  Future<void> deleteQuote(String quoteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotes = await loadSavedQuotes();
      quotes.removeWhere((q) => q.id == quoteId);

      final encoded = quotes.map((q) => jsonEncode({
            'id': q.id,
            'quoteName': q.quoteName,
            'bhk': q.bhk,
            'purpose': q.purpose,
            'packageTitle': q.packageTitle,
            'ratePerSqFt': q.ratePerSqFt,
            'approxAreaSqFt': q.approxAreaSqFt,
            'estimatedCostMin': q.estimatedCostMin,
            'estimatedCostMax': q.estimatedCostMax,
            'createdAt': q.createdAt.toIso8601String(),
            'roomBreakdown': q.roomBreakdown,
          })).toList();

      await prefs.setStringList(_quotesKey, encoded);
    } catch (_) {}
  }
}

final estimatorRepositoryProvider = Provider<EstimatorRepository>((ref) {
  return EstimatorRepository();
});
