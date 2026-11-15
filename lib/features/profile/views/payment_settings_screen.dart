import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/payment_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../viewmodels/profile_viewmodel.dart';

class PaymentSettingsScreen extends ConsumerWidget {
  const PaymentSettingsScreen({super.key});

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    PaymentCard card,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Card',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to remove card ending in ${card.maskedNumber.split(' ').last}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(profileViewModelProvider.notifier)
                  .deletePaymentCard(card.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card removed successfully.')),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final cards = state.paymentCards;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Payment',
          style: GoogleFonts.urbanist(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Text(
                  'Credit & Debit Cards',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                if (cards.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'No cards added yet. Tap below to add a card.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CardItem(
                        card: card,
                        onSelectDefault: () {
                          ref
                              .read(profileViewModelProvider.notifier)
                              .setDefaultPaymentCard(card.id);
                        },
                        onDelete: () => _showDeleteDialog(context, ref, card),
                      ),
                    ),
                const SizedBox(height: 20),
                Text(
                  'More Payment Options',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'PayPal',
                  subtitle: 'andrew.ainsley@example.com',
                ),
                _OptionTile(
                  icon: Icons.g_mobiledata_rounded,
                  iconSize: 32,
                  title: 'Google Pay',
                  subtitle: 'Connected',
                ),
                _OptionTile(
                  icon: Icons.apple_rounded,
                  title: 'Apple Pay',
                  subtitle: 'Connected',
                ),
                _OptionTile(
                  icon: Icons.payments_outlined,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay at your doorstep',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: SafeArea(
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: PrimaryButton(
              text: 'Add New Card',
              icon: Icons.add_rounded,
              onPressed: () => context.push(AppRoutes.addCard),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  const _CardItem({
    required this.card,
    required this.onSelectDefault,
    required this.onDelete,
  });

  final PaymentCard card;
  final VoidCallback onSelectDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isVisa = card.cardType.toLowerCase().contains('visa');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: card.isDefault ? Colors.white : AppColors.border,
          width: card.isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2B3344),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isVisa
                  ? const Text(
                      'VISA',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-4, 0),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      card.cardHolderName.isNotEmpty
                          ? card.cardHolderName
                          : 'Funica Card',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (card.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  card.maskedNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              card.isDefault
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: card.isDefault ? Colors.white : AppColors.textHint,
            ),
            tooltip: 'Make Default',
            onPressed: onSelectDefault,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.error,
            ),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconSize = 24,
  });

  final IconData icon;
  final double iconSize;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF283142),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}
