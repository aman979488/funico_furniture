import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cart_item.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../viewmodels/checkout_viewmodel.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutViewModelProvider);
    final cartState = ref.watch(cartViewModelProvider);
    final items = cartState.selectedCodeItems;

    final subtotal = cartState.subtotal;
    final shippingFee = checkoutState.selectedShippingOption.price;
    final discount = subtotal * checkoutState.promoDiscountRate;
    final total = subtotal + shippingFee - discount;

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.cart);
            }
          },
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items to checkout',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to Cart'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      children: [
                        // 1. Shipping Address Section
                        _buildSectionHeader(
                          title: 'Shipping Address',
                          actionText: 'Change',
                          onAction: () =>
                              context.push(AppRoutes.shippingAddress),
                        ),
                        const SizedBox(height: 8),
                        _buildAddressCard(context, checkoutState),
                        const SizedBox(height: 20),

                        // 2. Order Summary / Items Section
                        _buildSectionHeader(
                          title: 'Order List (${items.length} Items)',
                        ),
                        const SizedBox(height: 8),
                        ...items.map((item) => _buildItemCard(item)),
                        const SizedBox(height: 16),

                        // 3. Choose Shipping & Fitting
                        _buildSectionHeader(
                          title: 'Delivery & Fitting Type',
                          actionText: 'Change',
                          onAction: () =>
                              context.push(AppRoutes.chooseShipping),
                        ),
                        const SizedBox(height: 8),
                        _buildShippingOptionCard(context, checkoutState),
                        const SizedBox(height: 20),

                        // 4. Promo Code Applied
                        _buildSectionHeader(title: 'Promo Code'),
                        const SizedBox(height: 8),
                        _buildPromoCard(checkoutState),
                        const SizedBox(height: 20),

                        // 5. Cost Breakdown
                        _buildSectionHeader(title: 'Price Details'),
                        const SizedBox(height: 8),
                        _buildPriceCard(
                          subtotal: subtotal,
                          shippingFee: shippingFee,
                          discount: discount,
                          total: total,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Bottom Button Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
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
                              'Total Amount',
                              style: GoogleFonts.urbanist(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
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
                              onPressed: () {
                                context.push(AppRoutes.paymentMethods);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue to Payment',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
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

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        if (actionText != null && onAction != null)
          InkWell(
            onTap: onAction,
            child: Text(
              actionText,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF5722),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressCard(BuildContext context, CheckoutState state) {
    final address = state.selectedAddress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFFF5722),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address?.name ?? 'Delivery Address',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address?.fullAddress ?? 'No address selected',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: const Color(0xFFF3F4F6),
              child: item.product.image.isNotEmpty
                  ? Image.asset(
                      item.product.image,
                      fit: BoxFit.cover,
                      cacheWidth: 180,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF9CA3AF),
                      ),
                    )
                  : const Icon(
                      Icons.chair_outlined,
                      color: Color(0xFFFF5722),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.product.category} · Qty: ${item.quantity}',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.inRupees(item.totalPrice),
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF5722),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOptionCard(
      BuildContext context, CheckoutState state) {
    final option = state.selectedShippingOption;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Color(0xFFFF5722),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Est: ${option.estimatedDate} · ${CurrencyFormatter.inRupees(option.price)}',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.discount_outlined,
            color: Color(0xFFFF5722),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            state.promoCode,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Applied',
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF5722),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard({
    required double subtotal,
    required double shippingFee,
    required double discount,
    required double total,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildRow('Subtotal', CurrencyFormatter.inRupees(subtotal)),
          const SizedBox(height: 8),
          _buildRow(
            'Dynamic Cost (Delivery & Fitting)',
            CurrencyFormatter.inRupees(shippingFee),
          ),
          const SizedBox(height: 8),
          _buildRow(
            'Promo Discount',
            '-${CurrencyFormatter.inRupees(discount)}',
            valueColor: const Color(0xFFFF5722),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFE5E7EB), height: 1),
          ),
          _buildRow(
            'Total Amount',
            CurrencyFormatter.inRupees(total),
            isBold: true,
            valueColor: const Color(0xFFFF5722),
            fontSize: 15,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ??
                (isBold ? const Color(0xFF1F2937) : const Color(0xFF374151)),
          ),
        ),
      ],
    );
  }
}
