import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': '35% Special Discount!',
      'description':
          'Special promotion only valid for today. Upgrade your living room with modern luxury sofas.',
      'time': 'Just now',
      'section': 'Today',
      'icon': Icons.local_offer_rounded,
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'Order Placed Successfully',
      'description':
          'Your order #FN-9821 for Nordic Minimalist Sofa has been placed and is being packed.',
      'time': '2 hours ago',
      'section': 'Today',
      'icon': Icons.shopping_bag_rounded,
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'Payment Confirmed',
      'description':
          'Payment of \$420.00 via MasterCard has been verified and processed securely.',
      'time': 'Yesterday, 18:30',
      'section': 'Yesterday',
      'icon': Icons.payment_rounded,
      'isRead': true,
    },
    {
      'id': '4',
      'title': 'New Collection Released',
      'description':
          'Explore 30+ new Scandinavian dining tables and designer pendant lights in stock.',
      'time': 'Yesterday, 11:15',
      'section': 'Yesterday',
      'icon': Icons.chair_rounded,
      'isRead': true,
    },
    {
      'id': '5',
      'title': 'Welcome to Funica!',
      'description':
          'Your account profile is ready. Browse high-end furniture designed for modern comfort.',
      'time': '3 days ago',
      'section': 'Earlier',
      'icon': Icons.celebration_rounded,
      'isRead': true,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _clearAll() {
    setState(() => _notifications.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: AppColors.surface,
              onSelected: (val) {
                if (val == 'mark_read') _markAllAsRead();
                if (val == 'clear') _clearAll();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Text(
                    'Mark all as read',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text(
                    'Clear all',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Notifications',
                            style: GoogleFonts.urbanist(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You do not have any notifications at the moment.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final isFirstInSection = index == 0 ||
                          _notifications[index - 1]['section'] !=
                              item['section'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFirstInSection) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Text(
                                item['section'] as String,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item['isRead'] == true
                                  ? AppColors.surface
                                  : const Color(0xFF222B3D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item['isRead'] == true
                                    ? AppColors.border
                                    : const Color(0xFF3B4D6E),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A364C),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title'] as String,
                                              style: GoogleFonts.urbanist(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            item['time'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['description'] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
