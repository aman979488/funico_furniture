import 'package:flutter/foundation.dart';
import '../../../core/constants/app_assets.dart';

@immutable
class BhkConfig {
  final String bhk; // '1BHK', '2BHK', '3BHK', '4BHK', '5BHK'
  final String title;
  final String subtitle;
  final int approxAreaSqFt;
  final double baseCostMin;
  final double baseCostMax;
  final String samplePlanText;
  final String imageAsset;
  final List<String> roomHighlights;

  const BhkConfig({
    required this.bhk,
    required this.title,
    required this.subtitle,
    required this.approxAreaSqFt,
    required this.baseCostMin,
    required this.baseCostMax,
    required this.samplePlanText,
    required this.imageAsset,
    required this.roomHighlights,
  });

  static const List<BhkConfig> allConfigs = [
    BhkConfig(
      bhk: '1BHK',
      title: '1 BHK Apartment',
      subtitle: 'Compact & Modern Living Space',
      approxAreaSqFt: 580,
      baseCostMin: 180000,
      baseCostMax: 260000,
      samplePlanText: '1BHK Sample Plan',
      imageAsset: AppAssets.floorplan1Bhk,
      roomHighlights: [
        '1 Master Bedroom',
        'Living Room & Dining',
        'Modular Kitchen',
        '1 Bathroom & Balcony',
      ],
    ),
    BhkConfig(
      bhk: '2BHK',
      title: '2 BHK Apartment',
      subtitle: 'Comfortable Family Home',
      approxAreaSqFt: 960,
      baseCostMin: 320000,
      baseCostMax: 450000,
      samplePlanText: '2BHK Sample Plan',
      imageAsset: AppAssets.floorplan1Bhk,
      roomHighlights: [
        '2 Bedrooms (Master + Guest)',
        'Spacious Living & Dining Area',
        'Modular Kitchen with Chimney',
        '2 Bathrooms & Utility Balcony',
      ],
    ),
    BhkConfig(
      bhk: '3BHK',
      title: '3 BHK Apartment',
      subtitle: 'Spacious & Elegant Residence',
      approxAreaSqFt: 1480,
      baseCostMin: 490000,
      baseCostMax: 680000,
      samplePlanText: '3BHK Sample Plan',
      imageAsset: AppAssets.floorplan1Bhk,
      roomHighlights: [
        '3 Bedrooms with Custom Wardrobes',
        'Grand Living Room with TV Unit',
        'Designer Modular Kitchen',
        '3 Bathrooms & 2 Balconies',
      ],
    ),
    BhkConfig(
      bhk: '4BHK',
      title: '4 BHK Luxury Apartment',
      subtitle: 'Premium Architectural Interior',
      approxAreaSqFt: 2150,
      baseCostMin: 720000,
      baseCostMax: 990000,
      samplePlanText: '4BHK Sample Plan',
      imageAsset: AppAssets.floorplan1Bhk,
      roomHighlights: [
        '4 Bedrooms with Ensuite Facilities',
        'Luxury Living & Formal Dining',
        'Island Modular Kitchen & Pantry',
        '4 Bathrooms & Deck Area',
      ],
    ),
    BhkConfig(
      bhk: '5BHK',
      title: '5 BHK Penthouse / Villa',
      subtitle: 'Ultra-Luxury Custom Architecture',
      approxAreaSqFt: 3200,
      baseCostMin: 1050000,
      baseCostMax: 1480000,
      samplePlanText: '5BHK Sample Plan',
      imageAsset: AppAssets.floorplan1Bhk,
      roomHighlights: [
        '5 Deluxe Suites / Bedrooms',
        'Double Height Living Lounge',
        'Chef Kitchen with Wet Area',
        'Private Terrace & Home Theatre',
      ],
    ),
  ];
}

@immutable
class EstimatorPurposeInfo {
  final String id;
  final String label;
  final double multiplier;
  final String description;

  const EstimatorPurposeInfo({
    required this.id,
    required this.label,
    required this.multiplier,
    required this.description,
  });

  static const List<EstimatorPurposeInfo> allPurposes = [
    EstimatorPurposeInfo(
      id: 'Renovate',
      label: 'Renovate',
      multiplier: 1.0,
      description: 'Upgrade & refresh existing woodwork, paint, and fittings.',
    ),
    EstimatorPurposeInfo(
      id: 'New Home',
      label: 'New Home',
      multiplier: 1.25,
      description: 'Complete interior from scratch for bare shell possession.',
    ),
    EstimatorPurposeInfo(
      id: 'Custom Design',
      label: 'Custom Design',
      multiplier: 1.40,
      description: 'Architect-crafted tailored luxury concepts & furniture.',
    ),
    EstimatorPurposeInfo(
      id: 'Civil Work',
      label: 'Civil Work',
      multiplier: 0.70,
      description: 'Flooring, false ceiling, plumbing, and wall modification.',
    ),
    EstimatorPurposeInfo(
      id: 'Others',
      label: 'Others',
      multiplier: 0.95,
      description: 'Partial room makeover or selective upgrades.',
    ),
  ];
}

@immutable
class PackageConfig {
  final String id; // 'basic', 'modern', 'deluxe', 'premium', 'luxury'
  final String title;
  final double ratePerSqFt;
  final String imageAsset;
  final List<String> images;
  final String description;

  const PackageConfig({
    required this.id,
    required this.title,
    required this.ratePerSqFt,
    required this.imageAsset,
    required this.images,
    required this.description,
  });

  String get formattedRate {
    final rateInt = ratePerSqFt.toInt();
    final formatted = rateInt.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '₹$formatted /sqft';
  }

  static const List<PackageConfig> allPackages = [
    PackageConfig(
      id: 'basic',
      title: 'Basic Package',
      ratePerSqFt: 1000,
      imageAsset: AppAssets.pkgBasic,
      images: [
        AppAssets.pkgBasic,
        AppAssets.livingRoomImage,
        AppAssets.twoSeaterSofa,
      ],
      description: 'Essential woodwork, standard laminates, and clean finishes.',
    ),
    PackageConfig(
      id: 'modern',
      title: 'Modern Package',
      ratePerSqFt: 1500,
      imageAsset: AppAssets.pkgModern,
      images: [
        AppAssets.pkgModern,
        AppAssets.midCenturySofa1,
        AppAssets.heroDreamSpaceCleanHd,
      ],
      description: 'Contemporary TV wall, designer ceiling, and ambient lighting.',
    ),
    PackageConfig(
      id: 'deluxe',
      title: 'Deluxe Package',
      ratePerSqFt: 2000,
      imageAsset: AppAssets.pkgDeluxe,
      images: [
        AppAssets.pkgDeluxe,
        AppAssets.neutralSofaRoom,
        AppAssets.diningCollectionImage,
      ],
      description: 'High-gloss acrylics, custom mandir/cabinetry, and luxury lights.',
    ),
    PackageConfig(
      id: 'premium',
      title: 'Premium Package',
      ratePerSqFt: 2500,
      imageAsset: AppAssets.pkgPremium,
      images: [
        AppAssets.pkgPremium,
        AppAssets.chesterfieldSofa,
        AppAssets.bedroomImage,
      ],
      description: 'Back-lit marble TV backdrop, fluted panels, and velvet seating.',
    ),
    PackageConfig(
      id: 'luxury',
      title: 'Luxury Package',
      ratePerSqFt: 3000,
      imageAsset: AppAssets.pkgLuxury,
      images: [
        AppAssets.pkgLuxury,
        AppAssets.lShapedSofa,
        AppAssets.heroDreamSpaceCleanHd,
      ],
      description: 'Ultra-luxurious veneer, Italian marble, and motorized modular elements.',
    ),
  ];
}

@immutable
class EstimatorQuote {
  final String id;
  final String quoteName;
  final String bhk;
  final String purpose;
  final String packageTitle;
  final double ratePerSqFt;
  final int approxAreaSqFt;
  final double estimatedCostMin;
  final double estimatedCostMax;
  final DateTime createdAt;
  final Map<String, double> roomBreakdown;

  const EstimatorQuote({
    required this.id,
    required this.quoteName,
    required this.bhk,
    required this.purpose,
    this.packageTitle = 'Modern Package',
    this.ratePerSqFt = 1500,
    this.approxAreaSqFt = 960,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.createdAt,
    required this.roomBreakdown,
  });

  String get formattedCostRange {
    final minStr = formatCurrency(estimatedCostMin);
    final maxStr = formatCurrency(estimatedCostMax);
    return '$minStr - $maxStr';
  }

  static String formatCurrency(double amount) {
    final rounded = amount.round();
    final s = rounded.toString();
    if (s.length <= 3) return '₹$s';

    final lastThree = s.substring(s.length - 3);
    final otherNumbers = s.substring(0, s.length - 3);
    final formattedOther = otherNumbers.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (match) => ',',
    );
    return '₹$formattedOther,$lastThree';
  }
}
