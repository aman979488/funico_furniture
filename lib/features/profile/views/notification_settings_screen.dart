import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final prefs = state.notificationPreferences;
    final notifier = ref.read(profileViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notification',
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                _SectionTitle(title: 'Common Notifications'),
                _SwitchTile(
                  title: 'General Notification',
                  value: prefs.generalNotification,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(generalNotification: v),
                  ),
                ),
                _SwitchTile(
                  title: 'Sound',
                  value: prefs.sound,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(sound: v),
                  ),
                ),
                _SwitchTile(
                  title: 'Vibrate',
                  value: prefs.vibrate,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(vibrate: v),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _SectionTitle(title: 'System & Services'),
                _SwitchTile(
                  title: 'Special Offers',
                  value: prefs.specialOffers,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(specialOffers: v),
                  ),
                ),
                _SwitchTile(
                  title: 'Promo & Discount',
                  value: prefs.promoAndDiscount,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(promoAndDiscount: v),
                  ),
                ),
                _SwitchTile(
                  title: 'Payments',
                  value: prefs.payments,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(payments: v),
                  ),
                ),
                _SwitchTile(
                  title: 'Cashback',
                  value: prefs.cashbacks,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(cashbacks: v),
                  ),
                ),
                _SwitchTile(
                  title: 'New Service Available',
                  value: prefs.newService,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(newService: v),
                  ),
                ),
                _SwitchTile(
                  title: 'New Tips Available',
                  value: prefs.newTips,
                  onChanged: (v) => notifier.updateNotificationPreferences(
                    prefs.copyWith(newTips: v),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF4A5568),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: AppColors.background,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
