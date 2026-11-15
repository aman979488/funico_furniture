import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  List<Product> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return Product.sampleProducts.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search furniture',
                  prefixIcon: const Icon(Icons.search_rounded, size: 24),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.textHint),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? const SizedBox.shrink()
                  : results.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 900
                            ? 4
                            : constraints.maxWidth >= 650
                            ? 3
                            : 2;

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                          itemCount: results.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 22,
                                childAspectRatio: 0.60,
                              ),
                          itemBuilder: (context, index) {
                            final product = results[index];
                            return ProductCard(
                              product: product,
                              onTap: () => context.push(
                                AppRoutes.productDetails,
                                extra: product,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
