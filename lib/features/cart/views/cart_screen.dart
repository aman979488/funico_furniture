import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cart_item.dart';
import '../viewmodels/cart_viewmodel.dart';
import 'remove_from_cart_sheet.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartViewModelProvider);
    final items = cartState.items;
    const deliveryAndFitting = 1200.0;
    final promoDiscount = cartState.subtotal * 0.1;
    final total = cartState.subtotal + deliveryAndFitting - promoDiscount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Future Interior App',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: Color(0xFF6B7280),
                ),
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5722),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => context.go(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              size: 22,
              color: Color(0xFF6B7280),
            ),
            tooltip: 'Profile',
            onPressed: () => context.go(AppRoutes.profile),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState(context)
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      // "My Cart" Title + Badge + "Review your items"
                      Row(
                        children: [
                          const Text(
                            'My Cart',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEE4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cartState.totalItemCount} ${cartState.totalItemCount == 1 ? 'Item' : 'Items'}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Review your items',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cart item cards
                      for (final item in items) ...[
                        _CartItemCard(
                          item: item,
                          onIncrement: () {
                            ref
                                .read(cartViewModelProvider.notifier)
                                .updateQuantity(item.id, item.quantity + 1);
                          },
                          onDecrement: () {
                            if (item.quantity > 1) {
                              ref
                                  .read(cartViewModelProvider.notifier)
                                  .updateQuantity(item.id, item.quantity - 1);
                            } else {
                              RemoveFromCartSheet.show(context, item);
                            }
                          },
                          onRemove: () {
                            RemoveFromCartSheet.show(context, item);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 4),

                      // Price breakdown
                      _CartSummaryRow(
                        label: 'Subtotal',
                        value: CurrencyFormatter.inRupees(cartState.subtotal),
                        isBoldValue: true,
                      ),
                      const SizedBox(height: 6),
                      _CartSummaryRow(
                        label: 'Dynamic Cost (Delivery & Fitting)',
                        value: CurrencyFormatter.inRupees(deliveryAndFitting),
                        isBoldValue: true,
                      ),
                      const SizedBox(height: 6),
                      _CartSummaryRow(
                        label: 'Promo Discount',
                        value: '-${CurrencyFormatter.inRupees(promoDiscount)}',
                        valueColor: const Color(0xFFFF5722),
                        isBoldValue: true,
                      ),
                      const SizedBox(height: 6),
                      _CartSummaryRow(
                        label: 'Total Amount',
                        value: CurrencyFormatter.inRupees(total),
                        labelBold: true,
                        isBoldValue: true,
                        valueColor: const Color(0xFFFF5722),
                        fontSize: 12,
                      ),
                      const SizedBox(height: 14),

                      // Promo Code box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Promo Code',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEE4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '10% Add code',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // "Buy Now" button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Proceeding to checkout...'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bottom actions: "♡ Add to Favorites   |   ♡ Add to Favorites"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to Favorites'),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  size: 13,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add to Favorites',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '|',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to Favorites'),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  size: 13,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add to Favorites',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 42,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore our furniture catalog and add items you like.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              height: 42,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Shopping',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final packageText = product.packageTitle.isNotEmpty
        ? product.packageTitle
        : 'Basic Package';
    final materialText = product.material.isNotEmpty
        ? product.material
        : (product.category.isNotEmpty
            ? product.category
            : 'Commercial Ply • Matte Laminate');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Product Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 82,
              height: 82,
              color: const Color(0xFFF3F4F6),
              child: _buildThumb(product.image),
            ),
          ),
          const SizedBox(width: 12),

          // Right Product Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Delete trash icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2640),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Material / Category subtitle
                Text(
                  materialText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A92A6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),

                // Package pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEE4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    packageText,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                ),
                const SizedBox(height: 7),

                // Price and Quantity counter pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Price: ${CurrencyFormatter.inRupees(item.totalPrice)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2640),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onDecrement,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onIncrement,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(String image) {
    const fallback = Center(
      child: Icon(Icons.chair_outlined, size: 30, color: Color(0xFFBDBDBD)),
    );
    if (image.isEmpty) return fallback;
    if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _CartSummaryRow extends StatelessWidget {
  const _CartSummaryRow({
    required this.label,
    required this.value,
    this.labelBold = false,
    this.isBoldValue = false,
    this.valueColor = const Color(0xFF1E2640),
    this.fontSize = 11,
  });

  final String label;
  final String value;
  final bool labelBold;
  final bool isBoldValue;
  final Color valueColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: labelBold ? FontWeight.w800 : FontWeight.w500,
              color: labelBold ? const Color(0xFF1E2640) : const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
