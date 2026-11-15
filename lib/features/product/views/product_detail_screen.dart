import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.product, super.key});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImage = 0;

  List<String> get _images {
    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.image];
    return images.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = _images;

    return Scaffold(
      appBar: AppBar(title: Text(product.category)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showImageViewer(_selectedImage),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        height: 340,
                        color: AppColors.card,
                        child: _buildImage(
                          images[_selectedImage],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => setState(() => _selectedImage = index),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: index == _selectedImage
                                    ? AppColors.textPrimary
                                    : AppColors.border,
                                width: index == _selectedImage ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildImage(images[index]),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (product.rating > 0 ||
                      product.soldCount > 0 ||
                      product.price > 0)
                    Row(
                      children: [
                        if (product.rating > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                        if (product.soldCount > 0) ...[
                          if (product.rating > 0) const SizedBox(width: 12),
                          Text(
                            '${product.soldCount} sold',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (product.price > 0) ...[
                          const Spacer(),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? '${product.name}, made for your home. Browse the details and available options for this ${product.category.toLowerCase()}.'
                        : product.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  if (product.colors.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Available colors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: product.colors
                          .map(
                            (color) => Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String image, {BoxFit fit = BoxFit.cover}) {
    const fallback = Center(
      child: Icon(Icons.chair_outlined, size: 72, color: AppColors.textHint),
    );
    if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(image, fit: fit, errorBuilder: (_, _, _) => fallback);
  }

  void _showImageViewer(int initialIndex) {
    final images = _images;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (context, index) => Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: _buildImage(images[index], fit: BoxFit.contain),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Close image',
            ),
          ],
        ),
      ),
    );
  }
}
