import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
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
  String _selectedTier = 'Basic';

  void _handleMoreMenu(BuildContext context, String value) {
    switch (value) {
      case 'cart':
        context.go(AppRoutes.cart);
        break;
      case 'wishlist':
        context.push(AppRoutes.wishlist);
        break;
      case 'orders':
        context.push(AppRoutes.orders);
        break;
      case 'help':
        context.push(AppRoutes.helpCenter);
        break;
      case 'profile':
        context.push(AppRoutes.profile);
        break;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
      PinSession.lock();
      if (mounted) context.go(AppRoutes.letsYouIn);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not log out. Please try again.',
          ),
        ),
      );
    }
  }

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

  List<Product> get _visibleProducts {
    final selectedProductCategory = _selectedCategory == 'Lighting'
        ? 'Lamp'
        : _selectedCategory;
    final categoryFiltered = Product.sampleProducts.where((product) {
      return selectedProductCategory == 'All' ||
          product.category.toLowerCase() ==
              selectedProductCategory.toLowerCase();
    }).toList();

    if (_selectedTier == 'Basic') return categoryFiltered;

    final tierFiltered = categoryFiltered.where((product) {
      if (_selectedTier == 'Deluxe') return product.rating >= 4.7;
      if (_selectedTier == 'Modern') {
        final text = '${product.name} ${product.description}'.toLowerCase();
        return text.contains('modern') ||
            text.contains('century') ||
            text.contains('nordic');
      }
      if (_selectedTier == 'Premium') return product.price >= 100;
      if (_selectedTier == 'Luxury') {
        final text = '${product.name} ${product.description}'.toLowerCase();
        return product.price >= 150 ||
            text.contains('luxury') ||
            text.contains('premium');
      }
      return true;
    }).toList();

    return tierFiltered.isNotEmpty ? tierFiltered : categoryFiltered;
  }

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
      backgroundColor: AppColors.background,
      drawer: _HomeDrawer(
        userName: userName,
        userPhoto: userPhoto,
        userEmail: user?.email,
        onProfileTap: () => context.push(AppRoutes.profile),
        onHelpTap: () => context.push(AppRoutes.helpCenter),
        onWishlistTap: () => context.push(AppRoutes.wishlist),
        onOrdersTap: () => context.push(AppRoutes.orders),
        onCartTap: () => context.go(AppRoutes.cart),
        onSpecialOffersTap: () => context.push(AppRoutes.specialOffers),
        onCategoriesTap: () =>
            context.push(AppRoutes.categoryProducts, extra: 'All'),
        onLogoutTap: _confirmLogout,
      ),
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
                    // Top Bar (Future Interior + Menu + Search + Notifications + More)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _BrandTopBar(
                          onSearchTap: () => context.push(AppRoutes.search),
                          onNotificationsTap: () =>
                              context.push(AppRoutes.notifications),
                          onMoreTap: (val) => _handleMoreMenu(context, val),
                        ),
                      ),
                    ),

                    // Hero Banner (Design Your Dream Space - Above Special Offers)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                      sliver: SliverToBoxAdapter(child: _HeroDesignBanner()),
                    ),

                    // Tier / Collection Filter Bar (Basic, Deluxe, Modern, Premium, Luxury)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      sliver: SliverToBoxAdapter(
                        child: _TierCollectionBar(
                          selectedTier: _selectedTier,
                          onTierSelected: (tier) {
                            setState(() {
                              _selectedTier = tier;
                            });
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              tooltip: 'Filter categories',
                              icon: const Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: _showCategoryFilter,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
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

class _HouseBrandLogo extends StatelessWidget {
  const _HouseBrandLogo({this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _HouseIconPainter(color: AppColors.primary),
    );
  }
}

class _HouseIconPainter extends CustomPainter {
  const _HouseIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.105;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final pad = strokeWidth / 2 + 0.6;

    // Outer house outline
    final outerPath = Path();
    outerPath.moveTo(pad, h * 0.44);
    outerPath.lineTo(w / 2, pad + 0.8);
    outerPath.lineTo(w - pad, h * 0.44);
    outerPath.lineTo(w - pad, h - pad);
    outerPath.lineTo(pad, h - pad);
    outerPath.close();

    canvas.drawPath(outerPath, paint);

    // Inner rounded doorway arch
    final innerPath = Path();
    final doorW = w * 0.36;
    final doorLeft = (w - doorW) / 2;
    final doorRight = doorLeft + doorW;
    final doorBottom = h - pad;
    final doorTop = h * 0.54;

    innerPath.moveTo(doorLeft, doorBottom);
    innerPath.lineTo(doorLeft, doorTop + 3.2);
    innerPath.arcToPoint(
      Offset(doorRight, doorTop + 3.2),
      radius: Radius.circular(doorW / 2),
    );
    innerPath.lineTo(doorRight, doorBottom);

    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HouseIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BrandTopBar extends StatelessWidget {
  const _BrandTopBar({
    required this.onSearchTap,
    required this.onNotificationsTap,
    required this.onMoreTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;
  final void Function(String) onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (drawerContext) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              size: 26,
              color: AppColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            tooltip: 'Navigation Menu',
            onPressed: () => Scaffold.of(drawerContext).openDrawer(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: _HouseBrandLogo(size: 26),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Future Interior',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'INTERIOR SOLUTIONS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.textSecondary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            size: 24,
            color: AppColors.textPrimary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          tooltip: 'Search',
          onPressed: onSearchTap,
        ),
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: AppColors.textPrimary,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          tooltip: 'Notifications',
          onPressed: onNotificationsTap,
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            size: 22,
            color: AppColors.textPrimary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 38),
          tooltip: 'More Options',
          color: AppColors.surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          onSelected: onMoreTap,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'cart',
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Text('My Cart'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'wishlist',
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Text('Wishlist'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'orders',
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Text('Orders'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Text('Help Center'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Text('Profile Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroDesignBanner extends StatefulWidget {
  const _HeroDesignBanner();

  @override
  State<_HeroDesignBanner> createState() => _HeroDesignBannerState();
}

class _HeroDesignBannerState extends State<_HeroDesignBanner> {
  final _pageController = PageController();
  late final Timer _slideTimer;
  int _currentPage = 0;
  bool _isAutoSliding = false;

  static const _slidesCount = 4;

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
      final nextPage = (currentPage + 1) % _slidesCount;
      if (!mounted || !_pageController.hasClients) return;
      await _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 380),
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

  Widget _buildHeroSlide({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String buttonText,
    required String imagePath,
    required VoidCallback onTap,
    String? fallbackImagePath,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: const Color(0xFFF7F2EC),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => fallbackImagePath != null
                    ? Image.asset(
                        fallbackImagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      )
                    : const SizedBox.shrink(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.48, 0.74, 1.0],
                    colors: [
                      const Color(0xFFF7F2EB).withValues(alpha: 0.98),
                      const Color(0xFFF7F2EB).withValues(alpha: 0.88),
                      const Color(0xFFF7F2EB).withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2B1E17),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E6862),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: 0.26,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            buttonText,
                            style: GoogleFonts.urbanist(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: [
              // Slide 1: Design Your Dream Space
              _buildHeroSlide(
                context: context,
                title: 'Design Your\nDream Space',
                subtitle: 'Modern | Functional | Timeless',
                buttonText: 'Explore Designs',
                imagePath: AppAssets.heroDreamSpaceCleanHd,
                fallbackImagePath: AppAssets.neutralSofaRoom,
                onTap: () =>
                    context.push(AppRoutes.categoryProducts, extra: 'All'),
              ),
              // Slide 2: Living Room / Sofas
              _buildHeroSlide(
                context: context,
                title: 'Elevate Your\nLiving Room',
                subtitle: 'Crafted for comfort & elegance',
                buttonText: 'Shop Sofas',
                imagePath: AppAssets.neutralSofaRoom,
                fallbackImagePath: AppAssets.livingRoomImage,
                onTap: () =>
                    context.push(AppRoutes.categoryProducts, extra: 'Sofa'),
              ),
              // Slide 3: Bedroom Collection
              _buildHeroSlide(
                context: context,
                title: 'Tranquil & Cozy\nBedrooms',
                subtitle: 'Serene sanctuaries for restful sleep',
                buttonText: 'Explore Beds',
                imagePath: AppAssets.bedroomImage,
                fallbackImagePath: AppAssets.neutralSofaRoom,
                onTap: () =>
                    context.push(AppRoutes.categoryProducts, extra: 'Bed'),
              ),
              // Slide 4: Dining & Gathering
              _buildHeroSlide(
                context: context,
                title: 'Contemporary\nDining Spaces',
                subtitle: 'Gather in style with curated sets',
                buttonText: 'View Dining',
                imagePath: AppAssets.diningCollectionImage,
                fallbackImagePath: AppAssets.table,
                onTap: () =>
                    context.push(AppRoutes.categoryProducts, extra: 'Table'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slidesCount,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == _currentPage ? 22 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == _currentPage
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TierCollectionBar extends StatelessWidget {
  const _TierCollectionBar({
    required this.selectedTier,
    required this.onTierSelected,
  });

  final String selectedTier;
  final ValueChanged<String> onTierSelected;

  static const tiers = ['Basic', 'Deluxe', 'Modern', 'Premium', 'Luxury'];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Row(
          children: [
            for (int i = 0; i < tiers.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _TierItemCard(
                  tier: tiers[i],
                  isSelected: selectedTier == tiers[i],
                  onTap: () => onTierSelected(tiers[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TierItemCard extends StatelessWidget {
  const _TierItemCard({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  final String tier;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? AppColors.primary : const Color(0xFFFAF2EB);
    final iconColor = isSelected ? Colors.white : AppColors.primary;
    final textColor = isSelected ? Colors.white : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 70,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TierIcon(tier: tier, color: iconColor, size: 26),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tier,
                  maxLines: 1,
                  style: GoogleFonts.urbanist(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierIcon extends StatelessWidget {
  const _TierIcon({required this.tier, required this.color, this.size = 26});

  final String tier;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: switch (tier) {
          'Basic' => _SofaIconPainter(color: color),
          'Deluxe' => _CrownIconPainter(color: color),
          'Modern' => _LayersIconPainter(color: color),
          'Premium' => _StarIconPainter(color: color),
          'Luxury' => _DiamondIconPainter(color: color),
          _ => _SofaIconPainter(color: color),
        },
      ),
    );
  }
}

class _SofaIconPainter extends CustomPainter {
  const _SofaIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Backrest (center top)
    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.12, w * 0.68, h * 0.46),
      const Radius.circular(4),
    );
    canvas.drawRRect(backRect, paint);

    // Left armrest
    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.28, w * 0.18, h * 0.50),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftArm, paint);

    // Right armrest
    final rightArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.78, h * 0.28, w * 0.18, h * 0.50),
      const Radius.circular(3),
    );
    canvas.drawRRect(rightArm, paint);

    // Seat cushion between armrests
    final seatRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.52, w * 0.56, h * 0.26),
      const Radius.circular(2),
    );
    canvas.drawRRect(seatRect, paint);

    // Two small legs at bottom
    canvas.drawLine(
      Offset(w * 0.18, h * 0.78),
      Offset(w * 0.14, h * 0.92),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.82, h * 0.78),
      Offset(w * 0.86, h * 0.92),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SofaIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CrownIconPainter extends CustomPainter {
  const _CrownIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    // Crown outline path (matching reference photo: 3 peaks with dots)
    final path = Path()
      ..moveTo(w * 0.12, h * 0.82)
      ..lineTo(w * 0.14, h * 0.38)
      ..lineTo(w * 0.36, h * 0.58)
      ..lineTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.64, h * 0.58)
      ..lineTo(w * 0.86, h * 0.38)
      ..lineTo(w * 0.88, h * 0.82)
      ..close();

    canvas.drawPath(path, paint);

    // Bottom base band line
    canvas.drawLine(
      Offset(w * 0.12, h * 0.74),
      Offset(w * 0.88, h * 0.74),
      paint,
    );

    // Small circles on 3 peak tips
    final r = w * 0.055;
    canvas.drawCircle(Offset(w * 0.14, h * 0.32), r, dotPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.16), r, dotPaint);
    canvas.drawCircle(Offset(w * 0.86, h * 0.32), r, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _CrownIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LayersIconPainter extends CustomPainter {
  const _LayersIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Top rhombus (diamond tilted in isometric view)
    final topRhombus = Path()
      ..moveTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.88, h * 0.32)
      ..lineTo(w * 0.50, h * 0.52)
      ..lineTo(w * 0.12, h * 0.32)
      ..close();
    canvas.drawPath(topRhombus, paint);

    // Middle layer chevron
    final midChevron = Path()
      ..moveTo(w * 0.12, h * 0.50)
      ..lineTo(w * 0.50, h * 0.70)
      ..lineTo(w * 0.88, h * 0.50);
    canvas.drawPath(midChevron, paint);

    // Bottom layer chevron
    final botChevron = Path()
      ..moveTo(w * 0.12, h * 0.68)
      ..lineTo(w * 0.50, h * 0.88)
      ..lineTo(w * 0.88, h * 0.68);
    canvas.drawPath(botChevron, paint);
  }

  @override
  bool shouldRepaint(covariant _LayersIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _StarIconPainter extends CustomPainter {
  const _StarIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final outerR = w * 0.44;
    final innerR = outerR * 0.42;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * 36 - 90) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DiamondIconPainter extends CustomPainter {
  const _DiamondIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Diamond outer outline
    final outer = Path()
      ..moveTo(w * 0.28, h * 0.18)
      ..lineTo(w * 0.72, h * 0.18)
      ..lineTo(w * 0.90, h * 0.44)
      ..lineTo(w * 0.50, h * 0.88)
      ..lineTo(w * 0.10, h * 0.44)
      ..close();
    canvas.drawPath(outer, paint);

    // Inner facet lines: inverted triangle in top half
    final innerTriangle = Path()
      ..moveTo(w * 0.28, h * 0.18)
      ..lineTo(w * 0.50, h * 0.44)
      ..lineTo(w * 0.72, h * 0.18);
    canvas.drawPath(innerTriangle, paint);

    // Lines from facet points
    canvas.drawLine(
      Offset(w * 0.50, h * 0.44),
      Offset(w * 0.50, h * 0.88),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.10, h * 0.44),
      Offset(w * 0.50, h * 0.44),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.90, h * 0.44),
      Offset(w * 0.50, h * 0.44),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiamondIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.userName,
    required this.userPhoto,
    required this.userEmail,
    required this.onProfileTap,
    required this.onHelpTap,
    required this.onWishlistTap,
    required this.onOrdersTap,
    required this.onCartTap,
    required this.onSpecialOffersTap,
    required this.onCategoriesTap,
    required this.onLogoutTap,
  });

  final String userName;
  final String? userPhoto;
  final String? userEmail;
  final VoidCallback onProfileTap;
  final VoidCallback onHelpTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onCartTap;
  final VoidCallback onSpecialOffersTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onLogoutTap;

  Widget _buildAvatar(BuildContext context) {
    ImageProvider? imageProvider;
    if (userPhoto != null && userPhoto!.isNotEmpty) {
      if (!kIsWeb && File(userPhoto!).existsSync()) {
        imageProvider = FileImage(File(userPhoto!));
      } else if (userPhoto!.startsWith('http://') ||
          userPhoto!.startsWith('https://')) {
        imageProvider = NetworkImage(userPhoto!);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: imageProvider != null
              ? Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: Color(0xFF9CA3AF),
                  ),
                )
              : const Icon(
                  Icons.person_rounded,
                  size: 38,
                  color: Color(0xFF9CA3AF),
                ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onProfileTap();
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFE86F2D),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutUs(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              const _HouseBrandLogo(size: 48),
              const SizedBox(height: 12),
              Text(
                'Future Interior',
                style: GoogleFonts.urbanist(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Crafting timeless elegance & personalized spaces for modern living.',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.privacyPolicy);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Privacy & Terms'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Select Theme',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded, color: Color(0xFFD97706)),
                title: Text('Light (Active)', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded, color: Color(0xFF6366F1)),
                title: Text('Dark (Coming Soon)', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 30,
                  color: Color(0xFF9333EA),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Interior Consultations',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Schedule a personalized session with our expert interior architects to design your dream space.',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.estimator);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Book Consultation via Estimator'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = userName.isNotEmpty ? userName : 'Abhijeet Patil';
    final displayEmail = (userEmail != null && userEmail!.isNotEmpty)
        ? userEmail!
        : 'abhijeetpatil@gmail.com';

    return Drawer(
      width: math.min(MediaQuery.sizeOf(context).width * 0.84, 390),
      backgroundColor: const Color(0xFFF7F8FA),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Account & Settings',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(context),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3DE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Gold',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFD4973B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF8C8F99),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Future Interior Member',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE86F2D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ACCOUNT Section
                    const _SectionHeader(title: 'ACCOUNT'),
                    _GroupedCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFFE86F2D),
                          iconBg: const Color(0xFFFFF2E8),
                          title: 'Manage Profile',
                          onTap: () {
                            Navigator.pop(context);
                            onProfileTap();
                          },
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: Icons.notifications_none_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFE8F8F0),
                          title: 'Notifications',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.notificationSettings);
                          },
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF6366F1),
                          iconBg: const Color(0xFFEEF0FE),
                          title: 'Language',
                          trailingText: 'English',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.language);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // PREFERENCES Section
                    const _SectionHeader(title: 'PREFERENCES'),
                    _GroupedCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.article_outlined,
                          iconColor: const Color(0xFF0D9488),
                          iconBg: const Color(0xFFE3F7F6),
                          title: 'About Us',
                          onTap: () {
                            Navigator.pop(context);
                            _showAboutUs(context);
                          },
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: Icons.contrast_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFEF7E6),
                          title: 'Theme',
                          trailingText: 'Light',
                          onTap: () => _showThemeSelector(context),
                        ),
                        const _SettingsDivider(),
                        _SettingsTile(
                          icon: Icons.calendar_month_outlined,
                          iconColor: const Color(0xFF9333EA),
                          iconBg: const Color(0xFFF5E8FF),
                          title: 'Appointments',
                          onTap: () {
                            Navigator.pop(context);
                            _showAppointments(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // SUPPORT Section
                    const _SectionHeader(title: 'SUPPORT'),
                    _GroupedCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xFF0284C7),
                          iconBg: const Color(0xFFE0F2FE),
                          title: 'Help Center',
                          onTap: () {
                            Navigator.pop(context);
                            onHelpTap();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Logout Button
                    Material(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onLogoutTap();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD4D4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFE53935),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Log Out',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App Version Text
                    Center(
                      child: Text(
                        'Future Interior v2.4.1 (iOS)',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF4F5F7),
      indent: 62,
      endIndent: 14,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF23262F),
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: GoogleFonts.urbanist(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFFC4C4C4),
              ),
            ],
          ),
        ),
      ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140D0A08),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
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
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
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
