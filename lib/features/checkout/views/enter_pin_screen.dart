import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/formatters.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../viewmodels/checkout_viewmodel.dart';
import 'order_success_sheet.dart';

class CheckoutEnterPinScreen extends ConsumerStatefulWidget {
  const CheckoutEnterPinScreen({super.key});

  @override
  ConsumerState<CheckoutEnterPinScreen> createState() =>
      _CheckoutEnterPinScreenState();
}

class _CheckoutEnterPinScreenState
    extends ConsumerState<CheckoutEnterPinScreen> {
  String _pin = '';
  bool _isProcessing = false;

  void _onDigit(String digit) {
    if (_isProcessing || _pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      _processPayment();
    }
  }

  void _onBackspace() {
    if (_isProcessing || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final cartState = ref.read(cartViewModelProvider);
    final items = cartState.selectedCodeItems;
    final subtotal = cartState.subtotal;

    try {
      final order = await ref
          .read(checkoutViewModelProvider.notifier)
          .confirmOrder(cartItems: items, subtotal: subtotal);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Show Order Success Sheet
      OrderSuccessSheet.show(
        context,
        orderNumber: order.orderNumber,
        estimatedDelivery: '2-3 Days',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _pin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
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
          'Enter Your PIN',
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
            const SizedBox(height: 20),
            Text(
              'Enter your 4-digit PIN to confirm payment of',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.inRupees(total),
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFF5722),
              ),
            ),
            const SizedBox(height: 36),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? const Color(0xFFFF5722)
                        : const Color(0xFFE5E7EB),
                    border: Border.all(
                      color: isFilled
                          ? const Color(0xFFFF5722)
                          : const Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            if (_isProcessing) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722)),
              ),
              const SizedBox(height: 12),
              Text(
                'Processing payment & placing order...',
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const SizedBox(width: 64, height: 64),
                      _buildKeypadButton('0'),
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: IconButton(
                          onPressed: _onBackspace,
                          icon: const Icon(
                            Icons.backspace_outlined,
                            size: 24,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: digits.map((d) => _buildKeypadButton(d)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onDigit(digit),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.urbanist(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}
