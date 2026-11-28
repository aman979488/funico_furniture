import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/product.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../models/estimator_model.dart';
import '../viewmodels/estimator_viewmodel.dart';

class ProductComparisonScreen extends ConsumerStatefulWidget {
  const ProductComparisonScreen({
    super.key,
    required this.products,
    required this.packages,
    this.categoryTitle,
    this.onAddToQuote,
    this.onAddToCart,
  });

  final List<Product> products;
  final List<PackageConfig> packages;
  final String? categoryTitle;
  final Future<void> Function(Product product, int quantity)? onAddToQuote;
  final void Function(Product product, int quantity)? onAddToCart;

  @override
  ConsumerState<ProductComparisonScreen> createState() =>
      _ProductComparisonScreenState();
}

class _ProductComparisonScreenState
    extends ConsumerState<ProductComparisonScreen> {
  final Map<String, int> _quantities = {};
  final Map<String, String> _dimensionValues = {};
  final Map<String, bool> _swappedMap = {};
  final Map<String, TextEditingController> _dimensionControllers = {};

  @override
  void initState() {
    super.initState();
    for (final product in widget.products) {
      _quantities[product.id] = 1;
      final dim = _dimensionValue(product.dimensions);
      _dimensionValues[product.id] = dim;
      _swappedMap[product.id] = false;
      _dimensionControllers[product.id] = TextEditingController(text: dim);
    }
  }

  @override
  void dispose() {
    for (final controller in _dimensionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PackageConfig _packageFor(Product product) {
    return widget.packages.firstWhere(
      (pkg) => pkg.id.toLowerCase() == product.packageId.toLowerCase(),
      orElse: () => PackageConfig.allPackages.firstWhere(
        (pkg) => pkg.id.toLowerCase() == product.packageId.toLowerCase(),
        orElse: () => widget.packages.isNotEmpty
            ? widget.packages.first
            : PackageConfig.allPackages.first,
      ),
    );
  }

  String _dimensionValue(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'^\([^)]*\)\s*'), '').trim();
    return cleaned.isNotEmpty ? cleaned : '8.5 ft × 4.0 ft';
  }

  String _dimensionLabel(String raw) {
    final match = RegExp(r'^\(([^)]*)\)').firstMatch(raw);
    return match?.group(1) ?? 'L × H';
  }

  String _swapDimensionParts(String value) {
    final parts = value.split(RegExp(r'\s*[×xX]\s*'));
    return parts.length == 2 ? '${parts[1]} × ${parts[0]}' : value;
  }

  double _calculatePrice(
    String dimensionValue,
    double ratePerSqFt,
    double fallbackPrice,
  ) {
    final matches = RegExp(r'(\d+(?:\.\d+)?)')
        .allMatches(dimensionValue)
        .toList();
    if (matches.length < 2) return fallbackPrice;

    final length = double.tryParse(matches[0].group(0) ?? '');
    final height = double.tryParse(matches[1].group(0) ?? '');
    if (length == null || height == null || length <= 0 || height <= 0) {
      return fallbackPrice;
    }
    return length * height * ratePerSqFt;
  }

  void _onSwapDimension(Product product) {
    final controller = _dimensionControllers[product.id];
    if (controller == null) return;
    final currentText = controller.text;
    final swapped = _swapDimensionParts(currentText);
    controller.text = swapped;
    setState(() {
      _dimensionValues[product.id] = swapped;
      _swappedMap[product.id] = !(_swappedMap[product.id] ?? false);
    });
  }

  Future<void> _handleAddToQuote(Product product, int quantity) async {
    final dimensionValue =
        _dimensionControllers[product.id]?.text ??
        _dimensionValues[product.id] ??
        _dimensionValue(product.dimensions);
    final enrichedProduct = product.copyWith(
      dimensions: '(${_dimensionLabel(product.dimensions)}) $dimensionValue',
    );

    if (widget.onAddToQuote != null) {
      await widget.onAddToQuote!(enrichedProduct, quantity);
    } else {
      await ref
          .read(estimatorViewModelProvider.notifier)
          .addProductToQuote(enrichedProduct, quantity);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to My Quotes.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAddToCart(Product product, int quantity) {
    final dimensionValue =
        _dimensionControllers[product.id]?.text ??
        _dimensionValues[product.id] ??
        _dimensionValue(product.dimensions);
    final enrichedProduct = product.copyWith(
      dimensions: '(${_dimensionLabel(product.dimensions)}) $dimensionValue',
    );

    if (widget.onAddToCart != null) {
      widget.onAddToCart!(enrichedProduct, quantity);
    } else {
      ref
          .read(cartViewModelProvider.notifier)
          .addToCart(enrichedProduct, quantity: quantity);
      context.push(AppRoutes.cart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryTitle ?? 'Product';
    final products = widget.products;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Compare Products',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Package Comparison Chart
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Package Comparison Chart',
                    style: GoogleFonts.urbanist(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compare and choose the perfect $title package for your home',
                    style: GoogleFonts.urbanist(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Scrollable Cards with "vs" Badges
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        'No products to compare.',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < products.length; i++) ...[
                            if (i > 0) _buildVsBadge(),
                            _buildComparisonCard(products[i]),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVsBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 120),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'vs',
            style: GoogleFonts.urbanist(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard(Product product) {
    final package = _packageFor(product);
    final quantity = _quantities[product.id] ?? 1;
    final dimensionValue =
        _dimensionControllers[product.id]?.text ??
        _dimensionValues[product.id] ??
        _dimensionValue(product.dimensions);
    final isSwapped = _swappedMap[product.id] ?? false;

    final baseLabel = _dimensionLabel(product.dimensions);
    final currentLabel = isSwapped ? _swapDimensionParts(baseLabel) : baseLabel;

    final unitPrice = _calculatePrice(
      dimensionValue,
      package.ratePerSqFt,
      product.price,
    );

    final imageUrl = product.image.isNotEmpty
        ? product.image
        : (product.images.isNotEmpty
            ? product.images.first
            : AppAssets.livingRoomImage);
    final isRemote =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    final materialText = product.material.isNotEmpty
        ? product.material
        : (product.description.isNotEmpty
            ? product.description
            : product.category);

    final controller = _dimensionControllers[product.id];

    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Package Title (Center / Header)
            Center(
              child: Text(
                package.title,
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Big Product Image (Compact 155px to prevent overflow)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 155,
                child: isRemote
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ColoredBox(
                          color: Color(0xFFF1F5F9),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => Image.asset(
                          AppAssets.livingRoomImage,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),

            // Product Title
            Text(
              product.name,
              style: GoogleFonts.urbanist(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // Material / Specs
            Text(
              materialText,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Package Tag & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  package.title,
                  style: GoogleFonts.urbanist(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  CurrencyFormatter.inRupees(unitPrice),
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Editable Dimension Box (L x H) with Swap Button
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '($currentLabel)',
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: (val) {
                        setState(() {
                          _dimensionValues[product.id] = val;
                        });
                      },
                      maxLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onSwapDimension(product),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Quantity Selector Box
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Qty',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (quantity > 1) {
                        setState(() => _quantities[product.id] = quantity - 1);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: quantity > 1
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$quantity',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _quantities[product.id] = quantity + 1);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Add to Quote Button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: () => _handleAddToQuote(product, quantity),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFFFFD4B8),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Add to Quote',
                      style: GoogleFonts.urbanist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () => _handleAddToCart(product, quantity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add to Cart',
                  style: GoogleFonts.urbanist(
                    fontSize: 12.5,
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
