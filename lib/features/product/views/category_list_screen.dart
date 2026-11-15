import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({required this.category, super.key});

  final String category;

  static const _categoryTypes =
      <String, List<({String name, double price, String description})>>{
        'Chair': [
          (
            name: 'Accent Chair',
            price: 199,
            description: 'Stylish extra seating',
          ),
          (
            name: 'Armchair',
            price: 249,
            description: 'Comfortable living room seat',
          ),
          (name: 'Dining Chair', price: 89, description: 'For dining tables'),
          (
            name: 'Office Chair',
            price: 179,
            description: 'Comfortable desk seating',
          ),
          (
            name: 'Rocking Chair',
            price: 229,
            description: 'Relaxing rocking seat',
          ),
          (
            name: 'Lounge Chair',
            price: 299,
            description: 'Relaxed lounge seating',
          ),
          (
            name: 'Bar Stool',
            price: 99,
            description: 'For counters and bar tables',
          ),
        ],
        'Bed': [
          (
            name: 'Single Bed',
            price: 299,
            description: 'Compact single sleeper',
          ),
          (
            name: 'Double Bed',
            price: 449,
            description: 'Comfortable double sleeper',
          ),
          (name: 'Queen Bed', price: 599, description: 'Spacious everyday bed'),
          (name: 'King Bed', price: 799, description: 'Extra room for two'),
          (
            name: 'Bunk Bed',
            price: 499,
            description: 'Space-saving stacked beds',
          ),
          (
            name: 'Storage Bed',
            price: 699,
            description: 'Bed with useful storage',
          ),
          (
            name: 'Platform Bed',
            price: 549,
            description: 'Modern low-profile bed',
          ),
        ],
        'Wardrobe': [
          (
            name: '2-Door Wardrobe',
            price: 399,
            description: 'Compact clothing storage',
          ),
          (
            name: '3-Door Wardrobe',
            price: 599,
            description: 'Extra space for clothes',
          ),
          (
            name: 'Sliding-Door Wardrobe',
            price: 749,
            description: 'Space-saving sliding doors',
          ),
          (
            name: 'Hinged-Door Wardrobe',
            price: 499,
            description: 'Classic hinged doors',
          ),
          (
            name: 'Mirrored Wardrobe',
            price: 649,
            description: 'Wardrobe with a full mirror',
          ),
          (
            name: 'Walk-In Wardrobe',
            price: 1499,
            description: 'Roomy dressing and storage',
          ),
        ],
        'Table': [
          (
            name: 'Coffee Table',
            price: 149,
            description: 'For your living room',
          ),
          (
            name: 'Dining Table',
            price: 499,
            description: 'Gather around for meals',
          ),
          (
            name: 'Side Table',
            price: 99,
            description: 'Convenient sofa-side surface',
          ),
          (
            name: 'Console Table',
            price: 199,
            description: 'Slim table for an entryway',
          ),
          (
            name: 'Study Desk',
            price: 249,
            description: 'A practical work surface',
          ),
          (
            name: 'Nesting Tables',
            price: 179,
            description: 'Stackable space-saving tables',
          ),
        ],
        'Lamp': [
          (
            name: 'Pendant Light',
            price: 129,
            description: 'A hanging statement light',
          ),
          (
            name: 'Chandelier',
            price: 399,
            description: 'Decorative ceiling lighting',
          ),
          (
            name: 'Floor Lamp',
            price: 159,
            description: 'Standing light for any corner',
          ),
          (
            name: 'Table Lamp',
            price: 79,
            description: 'Soft light for desks and tables',
          ),
          (
            name: 'Wall Sconce',
            price: 69,
            description: 'Space-saving wall lighting',
          ),
          (
            name: 'Ceiling Light',
            price: 99,
            description: 'Everyday overhead lighting',
          ),
        ],
        'Cabinet': [
          (
            name: 'TV Cabinet',
            price: 349,
            description: 'Storage for your media setup',
          ),
          (
            name: 'Shoe Cabinet',
            price: 179,
            description: 'Keep footwear organized',
          ),
          (
            name: 'Display Cabinet',
            price: 499,
            description: 'Showcase your favorite pieces',
          ),
          (
            name: 'Kitchen Cabinet',
            price: 399,
            description: 'Extra kitchen storage',
          ),
          (
            name: 'Storage Cabinet',
            price: 279,
            description: 'Versatile home storage',
          ),
          (
            name: 'Bathroom Cabinet',
            price: 149,
            description: 'Compact bathroom storage',
          ),
        ],
        'Decor': [
          (
            name: 'Wall Art',
            price: 89,
            description: 'Add character to your walls',
          ),
          (
            name: 'Decorative Mirror',
            price: 129,
            description: 'A stylish accent mirror',
          ),
          (name: 'Vase', price: 39, description: 'A simple decorative accent'),
          (
            name: 'Area Rug',
            price: 199,
            description: 'Add warmth to your room',
          ),
          (
            name: 'Decorative Cushion',
            price: 29,
            description: 'A comfortable color accent',
          ),
          (
            name: 'Wall Clock',
            price: 59,
            description: 'A useful decorative detail',
          ),
          (
            name: 'Artificial Plant',
            price: 49,
            description: 'Greenery with easy care',
          ),
        ],
      };

  static List<Product> _productsForCategory(String category) {
    if (category == 'Sofa') return Product.sofaOptions;
    final types = _categoryTypes[category] ?? const [];
    return [
      for (final type in types)
        Product(
          id: '${category.toLowerCase()}-${type.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
          name: type.name,
          category: category,
          price: type.price,
          image: '',
          description: type.description,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final productCategory = category == 'Lighting' ? 'Lamp' : category;
    final categoryProducts = category == 'All'
        ? Product.sampleProducts
        : Product.sampleProducts
              .where(
                (product) =>
                    product.category.toLowerCase() ==
                    productCategory.toLowerCase(),
              )
              .toList();
    final products = category == 'All'
        ? categoryProducts
        : [...categoryProducts, ..._productsForCategory(productCategory)];

    return Scaffold(
      appBar: AppBar(
        title: Text(category == 'All' ? 'All Products' : category),
      ),
      body: products.isEmpty
          ? Center(
              child: Text(
                'No products found in $category',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 650
                    ? 3
                    : 2;

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () => context.push(
                              AppRoutes.productDetails,
                              extra: product,
                            ),
                          );
                        }, childCount: products.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 22,
                          childAspectRatio: 0.60,
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
