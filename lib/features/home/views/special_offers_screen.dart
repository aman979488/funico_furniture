import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../models/special_offer.dart';

class SpecialOffersScreen extends StatelessWidget {
  const SpecialOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Special Offers',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: specialOffers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _SpecialOfferCard(offer: specialOffers[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialOfferCard extends StatelessWidget {
  const _SpecialOfferCard({required this.offer});

  final SpecialOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF192231),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF28354A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.45,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(20),
                  ),
                  image: offer.imagePath == null
                      ? null
                      : DecorationImage(
                          image: AssetImage(offer.imagePath!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: offer.imagePath == null
                    ? Center(
                        child: Icon(offer.icon, color: offer.color, size: 44),
                      )
                    : null,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.55,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: offer.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: offer.color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        offer.discount,
                        style: TextStyle(
                          color: offer.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      offer.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
