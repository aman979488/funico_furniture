import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../viewmodels/checkout_viewmodel.dart';
import 'order_success_sheet.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  late String _selectedMethod;
  bool _isProcessingCOD = false;

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'UPI',
      'title': 'UPI (Google Pay, PhonePe, Paytm)',
      'subtitle': 'Fast & secure UPI payment',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF2563EB),
    },
    {
      'id': 'Card',
      'title': 'Credit / Debit Card',
      'subtitle': 'Visa, Mastercard, RuPay',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'id': 'Wallet',
      'title': 'Funico Wallet',
      'subtitle': 'Available balance: ₹25,000',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF059669),
    },
    {
      'id': 'COD',
      'title': 'Cash on Delivery',
      'subtitle': 'Pay cash to the delivery team',
      'icon': Icons.handshake_rounded,
      'color': Color(0xFFFF5722),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethod =
        ref.read(checkoutViewModelProvider).selectedPaymentMethod;
  }

  Future<void> _handlePayment() async {
    ref
        .read(checkoutViewModelProvider.notifier)
        .selectPaymentMethod(_selectedMethod);

    if (_selectedMethod == 'COD') {
      // Place order directly for COD
      setState(() => _isProcessingCOD = true);
      final cartState = ref.read(cartViewModelProvider);
      try {
        final order = await ref
            .read(checkoutViewModelProvider.notifier)
            .confirmOrder(
              cartItems: cartState.selectedCodeItems,
              subtotal: cartState.subtotal,
            );
        if (!mounted) return;
        setState(() => _isProcessingCOD = false);
        OrderSuccessSheet.show(
          context,
          orderNumber: order.orderNumber,
          estimatedDelivery: '2-3 Days',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessingCOD = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } else {
      // Navigate to enter PIN screen for online/wallet/card
      context.push(AppRoutes.checkoutPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutViewModelProvider);
    final cartState = ref.watch(cartViewModelProvider);
    final total = cartState.subtotal +
        checkoutState.selectedShippingOption.price -
        (cartState.subtotal * checkoutState.promoDiscountRate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Methods',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  Text(
                    'Select how you would like to pay',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._methods.map((method) {
                    final isSelected = _selectedMethod == method['id'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF5722)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedMethod = method['id']);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (method['color'] as Color)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  method['icon'] as IconData,
                                  color: method['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method['title'] as String,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      method['subtitle'] as String,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: method['id'] as String,
                                groupValue: _selectedMethod,
                                activeColor: const Color(0xFFFF5722),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedMethod = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Payable',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.inRupees(total),
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isProcessingCOD ? null : _handlePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessingCOD
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _selectedMethod == 'COD'
                                    ? 'Confirm Order'
                                    : 'Proceed to Pay',
                                style: GoogleFonts.urbanist(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
