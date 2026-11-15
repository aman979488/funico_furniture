import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

class SpecialOffer {
  const SpecialOffer({
    required this.discount,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.imagePath,
  });

  final String discount;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? imagePath;
}

const specialOffers = [
  SpecialOffer(
    discount: '25% OFF',
    title: 'Special Discount',
    description:
        'Upgrade your home with premium furniture. Style meets comfort!',
    icon: Icons.weekend_rounded,
    color: Color(0xFF8DB4FF),
    imagePath: AppAssets.sofaimg,
  ),
  SpecialOffer(
    discount: '20% OFF',
    title: 'Living Room Sale',
    description: 'Make room for comfort with deals on sofas and lounge chairs.',
    icon: Icons.chair_rounded,
    color: Color(0xFFD9A57E),
    imagePath: AppAssets.livingRoomImage,
  ),
  SpecialOffer(
    discount: '30% OFF',
    title: 'Bedroom Refresh',
    description: 'Find a better night’s sleep with special bedroom offers.',
    icon: Icons.bed_rounded,
    color: Color(0xFFB7A2E8),
    imagePath: AppAssets.bedroomImage,
  ),
  SpecialOffer(
    discount: '15% OFF',
    title: 'Dining Collection',
    description: 'Bring everyone together around a table made for sharing.',
    icon: Icons.dining_rounded,
    color: Color(0xFFE0BC72),
    imagePath: AppAssets.diningCollectionImage,
  ),
  SpecialOffer(
    discount: '40% OFF',
    title: 'Lighting Deals',
    description: 'Brighten every corner with warm, welcoming lights.',
    icon: Icons.light_rounded,
    color: Color(0xFFE6D58C),
    imagePath: AppAssets.lightingDealsImage,
  ),
];
