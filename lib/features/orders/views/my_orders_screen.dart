import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../viewmodels/orders_viewmodel.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersViewModelProvider);
    final orders = ordersState.orders;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF24211F),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.urbanist(
            color: const Color(0xFF24211F),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 21,
              color: Color(0xFFFF5722),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(
              Icons.person_outline_rounded,
              size: 21,
              color: Color(0xFF424242),
            ),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No orders placed yet',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                Color statusColor;
                switch (order.status) {
                  case 'Processing':
                    statusColor = const Color(0xFF2F80ED);
                    break;
                  case 'In Progress':
                    statusColor = const Color(0xFFFF5722);
                    break;
                  case 'Completed':
                  case 'Active':
                    statusColor = const Color(0xFF0D8A4F);
                    break;
                  default:
                    statusColor = const Color(0xFF6B7280);
                }

                final dateStr =
                    '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';

                return _OrderCard(
                  status: order.status,
                  statusColor: statusColor,
                  orderNumber: order.orderNumber,
                  date: dateStr,
                  amount: CurrencyFormatter.inRupees(order.totalAmount),
                  progressStep: order.progressStep,
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.status,
    required this.statusColor,
    required this.orderNumber,
    required this.date,
    required this.amount,
    required this.progressStep,
  });

  final String status;
  final Color statusColor;
  final String orderNumber;
  final String date;
  final String amount;
  final int progressStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.orders),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Order: ',
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: const Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '#$orderNumber',
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' - $status',
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _ProgressLine(progressStep: progressStep),
                  const SizedBox(height: 5),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProgressLabel('Ordered'),
                      _ProgressLabel('Designing'),
                      _ProgressLabel('Manufacturing'),
                      _ProgressLabel('Installation'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        date,
                        style: GoogleFonts.urbanist(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        amount,
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progressStep});

  final int progressStep;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 11,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = (constraints.maxWidth - 16) / 3;
          return Stack(
            children: [
              Positioned(
                left: 5,
                right: 5,
                top: 5,
                child: Container(
                  height: 2,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              Positioned(
                left: 5,
                width: segmentWidth * (progressStep - 1) + 5,
                top: 5,
                child: Container(
                  height: 2,
                  color: const Color(0xFFFF5722),
                ),
              ),
              for (var i = 0; i < 4; i++)
                Positioned(
                  left: 5 + segmentWidth * i - 5,
                  top: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i < progressStep
                          ? const Color(0xFFFF5722)
                          : const Color(0xFFD1D5DB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.urbanist(
        fontSize: 8.5,
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
