import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import '../models/special_offer.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'All';

  static const _categories = [
    _HomeCategory('Sofa', Icons.weekend_rounded, image: AppAssets.categorySofa),
    _HomeCategory('Chair', Icons.chair_rounded, image: AppAssets.categoryChair),
    _HomeCategory('Bed', Icons.bed_rounded, image: AppAssets.categoryBed),
    _HomeCategory(
      'Wardrobe',
      Icons.door_sliding_rounded,
      image: AppAssets.categoryWardrobe,
    ),
    _HomeCategory(
      'Table',
      Icons.table_restaurant_rounded,
      image: AppAssets.categoryTable,
    ),
    _HomeCategory(
      'Lighting',
      Icons.light_rounded,
      image: AppAssets.categoryLighting,
    ),
    _HomeCategory(
      'Cabinet',
      Icons.inventory_2_rounded,
      image: AppAssets.categoryCabinet,
    ),
    _HomeCategory(
      'Decor',
      Icons.local_florist_rounded,
      image: AppAssets.categoryDecor,
    ),
  ];

  List<Product> get _visibleProducts => Product.sampleProducts.where((product) {
    final selectedProductCategory = _selectedCategory == 'Lighting'
        ? 'Lamp'
        : _selectedCategory;
    return selectedProductCategory == 'All' ||
        product.category.toLowerCase() == selectedProductCategory.toLowerCase();
  }).toList();

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final profileState = ref.watch(profileViewModelProvider);
    final userName = profileState.userProfile?.name.isNotEmpty == true
        ? profileState.userProfile!.name
        : (user?.displayName?.trim() ?? 'Funica User');
    final userPhoto = profileState.userProfile?.photoUrl ?? user?.photoURL;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 650
                    ? 3
                    : 2;

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                      sliver: SliverToBoxAdapter(
                        child: _HomeHeader(
                          userName: userName,
                          photoUrl: userPhoto,
                          onProfileTap: () => context.push(AppRoutes.profile),
                          onCartTap: () => context.go(AppRoutes.cart),
                          onNotifications: () =>
                              context.push(AppRoutes.notifications),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                      sliver: SliverToBoxAdapter(
                        child: TextField(
                          readOnly: true,
                          onTap: () => context.push(AppRoutes.search),
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Search furniture',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 25,
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Filter categories',
                              onPressed: _showCategoryFilter,
                              icon: const Icon(Icons.tune_rounded),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Special Offers',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.specialOffers),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See All',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
                      sliver: SliverToBoxAdapter(child: _FeaturedBanner()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Categories',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final category = _categories[index];
                          return _CategoryShortcut(
                            category: category,
                            onTap: () => context.push(
                              AppRoutes.categoryProducts,
                              extra: category.name,
                            ),
                          );
                        }, childCount: _categories.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisExtent: 108,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 8,
                            ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Popular Categories',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(
                                AppRoutes.categoryProducts,
                                extra: 'All',
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                children: [
                                  Text('See All'),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 150,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          scrollDirection: Axis.horizontal,
                          itemCount: Product.sampleProducts.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final product = Product.sampleProducts[index];
                            return _PopularCategoryCard(
                              product: product,
                              onTap: () => context.push(
                                AppRoutes.categoryProducts,
                                extra: product.category == 'Lamp'
                                    ? 'Lighting'
                                    : product.category,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Popular Products',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (products.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No furniture found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => ProductCard(
                              product: products[index],
                              onTap: () => context.push(
                                AppRoutes.productDetails,
                                extra: products[index],
                              ),
                            ),
                            childCount: products.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryFilter() async {
    final category = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Filter by category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            for (final option in ['All', ..._categories.map((e) => e.name)])
              ListTile(
                title: Text(option),
                trailing: _selectedCategory == option
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (category != null && mounted) {
      setState(() => _selectedCategory = category);
    }
  }
}

class _HomeCategory {
  const _HomeCategory(this.name, this.icon, {this.image});

  final String name;
  final IconData icon;
  final String? image;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.photoUrl,
    required this.onProfileTap,
    required this.onCartTap,
    required this.onNotifications,
  });

  final String userName;
  final String? photoUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onCartTap;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Row(
      children: [
        _ProfileAvatar(photoUrl: photoUrl, onTap: onProfileTap),
        const SizedBox(width: 14),
        Expanded(
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userName.isEmpty ? 'Welcome back' : userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        _HeaderAction(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onPressed: onNotifications,
        ),
        _HeaderAction(
          icon: Icons.shopping_bag_outlined,
          tooltip: 'Cart',
          onPressed: onCartTap,
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, this.onTap});

  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (!kIsWeb && File(photoUrl!).existsSync()) {
        imageProvider = FileImage(File(photoUrl!));
      } else if (photoUrl!.startsWith('http://') ||
          photoUrl!.startsWith('https://')) {
        imageProvider = NetworkImage(photoUrl!);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: Colors.white70,
                ),
              )
            : const Icon(Icons.person_rounded, size: 34, color: Colors.white70),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: _HeaderActionIcon(icon: icon),
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textPrimary),
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({required this.category, required this.onTap});

  final _HomeCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: category.image == null
                ? Icon(category.icon, color: AppColors.textPrimary, size: 32)
                : Image.asset(
                    category.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      category.icon,
                      color: AppColors.textPrimary,
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(height: 7),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularCategoryCard extends StatelessWidget {
  const _PopularCategoryCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  IconData get _icon => switch (product.category) {
    'Sofa' => Icons.weekend_rounded,
    'Chair' => Icons.chair_rounded,
    'Table' => Icons.table_restaurant_rounded,
    'Lamp' => Icons.light_rounded,
    'Bed' => Icons.bed_rounded,
    _ => Icons.chair_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final categoryName = product.category == 'Lamp'
        ? 'Lighting'
        : product.category;

    return SizedBox(
      width: 126,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2A3347)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(
                          _icon,
                          size: 54,
                          color: const Color(0xFFD9C3A8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatefulWidget {
  const _FeaturedBanner();

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  final _pageController = PageController();
  late final Timer _slideTimer;
  int _currentPage = 0;
  bool _isAutoSliding = false;

  @override
  void initState() {
    super.initState();
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _slideToNextPage();
    });
  }

  Future<void> _slideToNextPage() async {
    if (_isAutoSliding || !mounted || !_pageController.hasClients) return;

    _isAutoSliding = true;
    try {
      final currentPage = _pageController.page?.round() ?? _currentPage;
      final nextPage = (currentPage + 1) % specialOffers.length;
      if (!mounted || !_pageController.hasClients) return;
      await _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } catch (_) {
      // Ignore animation cancellation on user swipe
    } finally {
      if (mounted) {
        _isAutoSliding = false;
      }
    }
  }

  @override
  void dispose() {
    _slideTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            controller: _pageController,
            itemCount: specialOffers.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) => _OfferSlide(
              offer: specialOffers[index],
              onTap: () {
                final nextPage = (index + 1) % specialOffers.length;
                _pageController.animateToPage(
                  nextPage,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            specialOffers.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: index == _currentPage ? 22 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == _currentPage
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferSlide extends StatelessWidget {
  const _OfferSlide({required this.offer, required this.onTap});

  final SpecialOffer offer;
  final VoidCallback onTap;

  void _showFullImage(BuildContext context, String imagePath, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF192231),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF28354A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: offer.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: offer.color.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          offer.discount,
                          style: TextStyle(
                            color: offer.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        offer.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: TextStyle(
                              color: offer.color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: offer.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (offer.imagePath != null)
                Expanded(
                  flex: 9,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GestureDetector(
                      onTap: () => _showFullImage(
                        context,
                        offer.imagePath!,
                        offer.title,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A26),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF232D3F)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              offer.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(
                                  offer.icon,
                                  size: 56,
                                  color: offer.color,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.fullscreen_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 8,
                  child: Center(
                    child: Icon(offer.icon, size: 76, color: offer.color),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
