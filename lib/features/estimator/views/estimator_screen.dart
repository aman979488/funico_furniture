import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/product.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../models/estimator_model.dart';
import '../viewmodels/estimator_viewmodel.dart';

class EstimatorScreen extends ConsumerStatefulWidget {
  const EstimatorScreen({super.key});

  @override
  ConsumerState<EstimatorScreen> createState() => _EstimatorScreenState();
}

class _EstimatorScreenState extends ConsumerState<EstimatorScreen> {
  late final TextEditingController _quoteNameController;
  late final PageController _tabPageController;

  @override
  void initState() {
    super.initState();
    final currentQuoteName = ref.read(estimatorViewModelProvider).quoteName;
    _quoteNameController = TextEditingController(text: currentQuoteName);
    _tabPageController = PageController(
      initialPage: ref.read(estimatorViewModelProvider).currentTabIndex,
    );
  }

  @override
  void dispose() {
    _quoteNameController.dispose();
    _tabPageController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    final vm = ref.read(estimatorViewModelProvider.notifier);
    if (vm.handleBackStep()) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _showEstimateSummarySheet(EstimatorQuote quote) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _EstimateResultBottomSheet(
          quote: quote,
          onSaveQuote: () async {
            try {
              await ref
                  .read(estimatorViewModelProvider.notifier)
                  .saveCurrentQuote(quote);
            } catch (error, stackTrace) {
              debugPrint('Failed to save estimator quote: $error');
              debugPrintStack(stackTrace: stackTrace);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not save this quote.')),
              );
              return;
            }
            if (!mounted) return;
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            ref.read(estimatorViewModelProvider.notifier).setTab(1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Quote "${quote.quoteName}" saved successfully!',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          onExploreProducts: () {
            Navigator.of(sheetContext).pop();
            ref.read(estimatorViewModelProvider.notifier).setTab(2);
          },
        );
      },
    );
  }

  Future<void> _addProductToQuote(Product product, int quantity) async {
    try {
      await ref
          .read(estimatorViewModelProvider.notifier)
          .addProductToQuote(product, quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added to My Quotes.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to add product to estimator quote: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add product to My Quotes.')),
      );
    }
  }

  void _openEstimateDetailsScreen({
    required EstimatorQuote quote,
    required PackageConfig package,
    required String imageAsset,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _EstimateDetailsScreen(
          quote: quote,
          package: package,
          imageAsset: imageAsset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimatorViewModelProvider);
    final vm = ref.read(estimatorViewModelProvider.notifier);
    ref.listen(
      estimatorViewModelProvider.select((value) => value.currentTabIndex),
      (_, nextIndex) {
        if (!_tabPageController.hasClients) return;
        final currentPage = _tabPageController.page;
        if (currentPage == null || currentPage.round() != nextIndex) {
          _tabPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          );
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: Color(0xFF1E293B),
            ),
            onPressed: _handleBackNavigation,
          ),
          title: Text(
            state.currentTabIndex == 2
                ? 'View our products'
                : 'Calculate Your Interior Cost',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
          titleSpacing: 0,
          actions: state.currentTabIndex == 2
              ? [
                  IconButton(
                    tooltip: 'Wishlist',
                    onPressed: () => context.go(AppRoutes.wishlist),
                    icon: const Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share products',
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: 'Explore furniture products in Funica.',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product link copied to clipboard.'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                ]
              : null,
        ),
        body: Column(
          children: [
            // Top Navigation Tabs: CALCULATE | MY QUOTES | PRODUCTS
            _EstimatorTabsBar(
              activeTabIndex: state.currentTabIndex,
              onTabSelected: vm.setTab,
            ),

            // Body per tab
            Expanded(
              child: PageView(
                key: const ValueKey('estimator-tab-pages'),
                controller: _tabPageController,
                physics: const _EstimatorTabSwipePhysics(),
                onPageChanged: vm.setTab,
                children: [
                  // Tab 0: CALCULATE (Step 1 vs Step 2)
                  state.calculateStep == 1
                      ? _CalculateStep1Content(
                          quoteNameController: _quoteNameController,
                          state: state,
                          onBhkSelected: (bhk) => vm.selectBhk(bhk),
                          onPrevBhk: () => vm.prevBhk(),
                          onNextBhk: () => vm.nextBhk(),
                          onPurposeSelected: (purpose) =>
                              vm.selectPurpose(purpose),
                          onQuoteNameChanged: (name) => vm.setQuoteName(name),
                          onNextStepTap: () => vm.goToPackageSelection(),
                        )
                      : _CalculateStep2PackagesContent(
                          state: state,
                          onSelectPackage: (id) => vm.selectPackage(id),
                          onPrevImage: (id) => vm.prevPackageImage(id),
                          onNextImage: (id) => vm.nextPackageImage(id),
                          onCalculateCostTap: () {
                            final quote = vm.calculateEstimate();
                            final package = state.currentPackageConfig;
                            final images = package.images.isNotEmpty
                                ? package.images
                                : [package.imageAsset];
                            final imageIndex =
                                state.packageImageIndices[package.id] ?? 0;
                            _openEstimateDetailsScreen(
                              quote: quote,
                              package: package,
                              imageAsset: images[imageIndex % images.length],
                            );
                          },
                        ),

                  // Tab 1: MY QUOTES
                  _MyQuotesTabContent(
                    quotes: state.savedQuotes,
                    onDeleteQuote: (id) => vm.deleteQuote(id),
                    onQuoteTap: (quote) => _showEstimateSummarySheet(quote),
                    onCreateNewQuoteTap: () {
                      vm.setTab(0);
                    },
                    onAddProductsTap: () => vm.setTab(2),
                  ),

                  // Tab 2: PRODUCTS
                  _ProductsTabContent(
                    selectedPackageId: state.selectedPackageId,
                    packages: state.packages,
                    onPackageSelected: (id) => vm.selectPackage(id),
                    onProductTap: (product) =>
                        context.push(AppRoutes.productDetails, extra: product),
                    onAddToQuote: _addProductToQuote,
                    onSelectPackage: () {
                      vm.setTab(0);
                      vm.goToPackageSelection();
                    },
                    onAddToCart: (product, quantity) {
                      ref
                          .read(cartViewModelProvider.notifier)
                          .addToCart(product, quantity: quantity);
                      context.push(AppRoutes.cart);
                    },
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

class _EstimatorTabSwipePhysics extends PageScrollPhysics {
  const _EstimatorTabSwipePhysics({super.parent});

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 1, stiffness: 700, damping: 54);

  @override
  _EstimatorTabSwipePhysics applyTo(ScrollPhysics? ancestor) {
    return _EstimatorTabSwipePhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.viewportDimension <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final page = position.pixels / position.viewportDimension;
    final lowerPage = page.floorToDouble();
    final upperPage = page.ceilToDouble();
    late final double targetPage;

    if (velocity > 0) {
      targetPage = lowerPage + 1;
    } else if (velocity < 0) {
      targetPage = upperPage - 1;
    } else {
      targetPage = page.roundToDouble();
    }

    final targetPixels = (targetPage * position.viewportDimension)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (targetPixels == position.pixels) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

// -----------------------------------------------------------------------------
// Top Tabs Bar: CALCULATE | MY QUOTES | PRODUCTS
// -----------------------------------------------------------------------------
class _EstimatorTabsBar extends StatelessWidget {
  const _EstimatorTabsBar({
    required this.activeTabIndex,
    required this.onTabSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int> onTabSelected;

  static const _tabTitles = ['CALCULATE', 'MY QUOTES', 'PRODUCTS'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(_tabTitles.length, (index) {
              final isSelected = activeTabIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _tabTitles[index],
                          style: GoogleFonts.urbanist(
                            fontSize: 13.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF8C8681),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Container(
                        height: 3.0,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1EDE9)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 0 - Step 1: Configuration & Purpose
// -----------------------------------------------------------------------------
class _CalculateStep1Content extends StatelessWidget {
  const _CalculateStep1Content({
    required this.quoteNameController,
    required this.state,
    required this.onBhkSelected,
    required this.onPrevBhk,
    required this.onNextBhk,
    required this.onPurposeSelected,
    required this.onQuoteNameChanged,
    required this.onNextStepTap,
  });

  final TextEditingController quoteNameController;
  final EstimatorState state;
  final ValueChanged<String> onBhkSelected;
  final VoidCallback onPrevBhk;
  final VoidCallback onNextBhk;
  final ValueChanged<String> onPurposeSelected;
  final ValueChanged<String> onQuoteNameChanged;
  final VoidCallback onNextStepTap;

  static const _bhkList = ['1BHK', '2BHK', '3BHK', '4BHK', '5BHK'];

  static const _purposeRow1 = ['Renovate', 'New Home', 'Custom Design'];
  static const _purposeRow2 = ['Civil Work', 'Others'];

  @override
  Widget build(BuildContext context) {
    final bhkConfig = state.currentBhkConfig;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Name of the Quote
          _SectionTitle(title: 'Name of the Quote'),
          const SizedBox(height: 8),
          TextField(
            controller: quoteNameController,
            onChanged: onQuoteNameChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: GoogleFonts.urbanist(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: 'Enter quote name',
              hintStyle: GoogleFonts.urbanist(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Select Configuration (1BHK - 5BHK)
          _SectionTitle(title: 'Select Configuration (1BHK - 5BHK)'),
          const SizedBox(height: 10),

          // 3D Floor Plan Card
          Container(
            height: 175,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 12, 40, 22),
                      child:
                          bhkConfig.imageAsset.startsWith('http://') ||
                              bhkConfig.imageAsset.startsWith('https://')
                          ? CachedNetworkImage(
                              imageUrl: bhkConfig.imageAsset,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                AppAssets.floorplanSample,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.asset(
                              bhkConfig.imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                    AppAssets.floorplanSample,
                                    fit: BoxFit.contain,
                                  ),
                            ),
                    ),
                  ),

                  // Left arrow
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CircleArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: onPrevBhk,
                      ),
                    ),
                  ),

                  // Right arrow
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CircleArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: onNextBhk,
                      ),
                    ),
                  ),

                  // Watermark / Plan text
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Text(
                      bhkConfig.samplePlanText,
                      style: GoogleFonts.urbanist(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // BHK Selector Row: 1BHK | 2BHK | 3BHK | 4BHK | 5BHK
          Row(
            children: _bhkList.map((bhk) {
              final isSelected = state.selectedBhk == bhk;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => onBhkSelected(bhk),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF9F5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Text(
                        bhk,
                        style: GoogleFonts.urbanist(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // 3. Select Purpose
          _SectionTitle(title: 'Select Purpose'),
          const SizedBox(height: 10),

          // Row 1: Renovate | New Home | Custom Design
          Row(
            children: _purposeRow1.map((purpose) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _PurposeChip(
                    label: purpose,
                    isSelected: state.selectedPurpose == purpose,
                    onTap: () => onPurposeSelected(purpose),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Row 2: Civil Work | Others
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _PurposeChip(
                    label: _purposeRow2[0],
                    isSelected: state.selectedPurpose == _purposeRow2[0],
                    onTap: () => onPurposeSelected(_purposeRow2[0]),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _PurposeChip(
                    label: _purposeRow2[1],
                    isSelected: state.selectedPurpose == _purposeRow2[1],
                    onTap: () => onPurposeSelected(_purposeRow2[1]),
                  ),
                ),
              ),
              const Expanded(flex: 1, child: SizedBox()),
            ],
          ),

          const SizedBox(height: 32),

          // Next Step > Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNextStepTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next Step',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 0 - Step 2: Select Package (Matches User's Reference Image)
// -----------------------------------------------------------------------------
class _CalculateStep2PackagesContent extends StatelessWidget {
  const _CalculateStep2PackagesContent({
    required this.state,
    required this.onSelectPackage,
    required this.onPrevImage,
    required this.onNextImage,
    required this.onCalculateCostTap,
  });

  final EstimatorState state;
  final ValueChanged<String> onSelectPackage;
  final ValueChanged<String> onPrevImage;
  final ValueChanged<String> onNextImage;
  final VoidCallback onCalculateCostTap;

  Widget _packageImage(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ColoredBox(
          color: Color(0xFFE2E8F0),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Failed to load estimator image $url: $error');
          return Image.asset(AppAssets.livingRoomImage, fit: BoxFit.cover);
        },
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(AppAssets.livingRoomImage, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packages = state.packages.isNotEmpty
        ? state.packages
        : PackageConfig.allPackages;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            physics: const BouncingScrollPhysics(),
            children: [
              // Header: 4. Select Package & 5 Packages Available badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '4. Select Package',
                        style: GoogleFonts.urbanist(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD4B8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${packages.length} Packages Available',
                          style: GoogleFonts.urbanist(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (state.packagesLoading) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 5 Package Cards (Vertical list)
              ...packages.map((pkg) {
                final isSelected = state.selectedPackageId == pkg.id;
                final imageIndex = state.packageImageIndices[pkg.id] ?? 0;
                final imageAsset = pkg.images[imageIndex % pkg.images.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () => onSelectPackage(pkg.id),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 168,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background package image
                            _packageImage(imageAsset),

                            // Top subtle dark gradient for badges
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.55),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.45),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),

                            // Top-Left Badge: Package Title
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  pkg.title,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),

                            // Top-Right Badge: Rate /sqft
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  pkg.formattedRate,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),

                            // Left circular arrow button
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _CircleArrowButton(
                                  icon: Icons.chevron_left_rounded,
                                  onTap: () => onPrevImage(pkg.id),
                                ),
                              ),
                            ),

                            // Right circular arrow button
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _CircleArrowButton(
                                  icon: Icons.chevron_right_rounded,
                                  onTap: () => onNextImage(pkg.id),
                                ),
                              ),
                            ),

                            // Bottom-Left 3-Dots Carousel Indicator
                            Positioned(
                              bottom: 10,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${imageIndex + 1}/${pkg.images.length}',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Selected Checkmark Badge (Bottom-Right)
                            if (isSelected)
                              Positioned(
                                bottom: 10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Bottom Fixed Container with "Calculate Est. Cost" Button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1EDE9), width: 1)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onCalculateCostTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Calculate Est. Cost',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Section Title Helper (matches bullet/dot design in screenshot)
// -----------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Circular Arrow Navigation Button
// -----------------------------------------------------------------------------
class _CircleArrowButton extends StatelessWidget {
  const _CircleArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 19, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Purpose Chip
// -----------------------------------------------------------------------------
class _PurposeChip extends StatelessWidget {
  const _PurposeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5EE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.urbanist(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class _EstimateDetailsScreen extends StatelessWidget {
  const _EstimateDetailsScreen({
    required this.quote,
    required this.package,
    required this.imageAsset,
  });

  final EstimatorQuote quote;
  final PackageConfig package;
  final String imageAsset;

  Widget _buildImage() {
    if (imageAsset.startsWith('http://') || imageAsset.startsWith('https://')) {
      return CachedNetworkImage(
        key: const ValueKey('estimate-selected-package-image'),
        imageUrl: imageAsset,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ColoredBox(
          color: Color(0xFFE2E8F0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) =>
            Image.asset(AppAssets.livingRoomImage, fit: BoxFit.cover),
      );
    }

    return Image.asset(
      imageAsset,
      key: const ValueKey('estimate-selected-package-image'),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(AppAssets.livingRoomImage, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('estimate-details-screen'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Estimate Details',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          key: const ValueKey('estimate-details-back'),
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImage(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  package.title,
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                package.formattedRate,
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            package.description,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Estimate details',
            style: GoogleFonts.urbanist(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          _EstimateDetailRow(label: 'Quote name', value: quote.quoteName),
          _EstimateDetailRow(label: 'Configuration', value: quote.bhk),
          _EstimateDetailRow(label: 'Purpose', value: quote.purpose),
          _EstimateDetailRow(
            label: 'Area',
            value: '${quote.approxAreaSqFt} sq.ft',
          ),
          _EstimateDetailRow(
            label: 'Estimated cost',
            value: quote.formattedCostRange,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _EstimateDetailRow extends StatelessWidget {
  const _EstimateDetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.primary : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1: MY QUOTES Content
// -----------------------------------------------------------------------------
class _MyQuotesTabContent extends StatefulWidget {
  const _MyQuotesTabContent({
    required this.quotes,
    required this.onDeleteQuote,
    required this.onQuoteTap,
    required this.onCreateNewQuoteTap,
    required this.onAddProductsTap,
  });

  final List<EstimatorQuote> quotes;
  final ValueChanged<String> onDeleteQuote;
  final ValueChanged<EstimatorQuote> onQuoteTap;
  final VoidCallback onCreateNewQuoteTap;
  final VoidCallback onAddProductsTap;

  @override
  State<_MyQuotesTabContent> createState() => _MyQuotesTabContentState();
}

class _MyQuotesTabContentState extends State<_MyQuotesTabContent> {
  String _query = '';
  String _bhkFilter = 'All';
  final Set<String> _selectedQuoteIds = {};

  List<EstimatorQuote> get _filteredQuotes => widget.quotes.where((quote) {
    final normalizedQuery = _query.trim().toLowerCase();
    final matchesQuery =
        normalizedQuery.isEmpty ||
        quote.quoteName.toLowerCase().contains(normalizedQuery) ||
        quote.bhk.toLowerCase().contains(normalizedQuery) ||
        quote.packageTitle.toLowerCase().contains(normalizedQuery) ||
        quote.purpose.toLowerCase().contains(normalizedQuery) ||
        quote.itemsSummary.toLowerCase().contains(normalizedQuery);
    final matchesBhk = _bhkFilter == 'All' || quote.bhk == _bhkFilter;
    return matchesQuery && matchesBhk;
  }).toList();

  List<EstimatorQuote> get _selectedQuotes => widget.quotes
      .where((quote) => _selectedQuoteIds.contains(quote.id))
      .toList();

  Future<void> _showFilters() async {
    final bhkOptions = [
      'All',
      ...widget.quotes.map((quote) => quote.bhk).toSet().toList()..sort(),
    ];
    final selectedFilter = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by configuration',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: bhkOptions.map((option) {
                  final selected = option == _bhkFilter;
                  return ChoiceChip(
                    label: Text(option),
                    selected: selected,
                    onSelected: (_) => Navigator.of(context).pop(option),
                    selectedColor: AppColors.accentLight,
                    labelStyle: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF475569),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selectedFilter != null && mounted) {
      setState(() => _bhkFilter = selectedFilter);
    }
  }

  void _toggleSelection(EstimatorQuote quote) {
    setState(() {
      if (!_selectedQuoteIds.add(quote.id)) {
        _selectedQuoteIds.remove(quote.id);
      }
    });
  }

  void _showComparison() {
    final quotes = _selectedQuotes;
    if (quotes.length < 2) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compare quotes'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: quotes
                .map(
                  (quote) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(quote.quoteName),
                    subtitle: Text(
                      '${quote.bhk} • ${quote.packageTitle} • ${quote.purpose}',
                    ),
                    trailing: Text(
                      quote.formattedCostRange,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareQuote(EstimatorQuote quote) {
    final text = [
      quote.quoteName,
      '${quote.bhk} • ${quote.packageTitle} • ${quote.purpose}',
      'Estimated cost: ${quote.formattedCostRange}',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote details copied to clipboard.')),
    );
  }

  void _showPdfComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF export is coming soon.')));
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: Color(0xFFF0D7C8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _generateAllPackagesButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: _showPdfComingSoon,
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          label: Text(
            'Generate All Packages PDFs',
            style: GoogleFonts.urbanist(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFFFD4B8), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuotes = _filteredQuotes;
    final selectedQuotes = _selectedQuotes;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextField(
                        key: const ValueKey('saved-quotes-search'),
                        onChanged: (value) => setState(() => _query = value),
                        textInputAction: TextInputAction.search,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search saved quotes',
                          hintStyle: GoogleFonts.urbanist(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 21,
                            color: Color(0xFF94A3B8),
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _showFilters,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        size: 22,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.quotes.isEmpty
                  ? _emptyQuotes()
                  : filteredQuotes.isEmpty
                  ? Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'No quotes match your search.',
                              style: GoogleFonts.urbanist(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        _generateAllPackagesButton(),
                        if (selectedQuotes.isNotEmpty)
                          _selectionSummary(selectedQuotes),
                        const SizedBox(height: 4),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                      children: [
                        for (
                          var index = 0;
                          index < filteredQuotes.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: 14),
                          _quoteCard(filteredQuotes[index]),
                        ],
                        _generateAllPackagesButton(),
                        if (selectedQuotes.isNotEmpty)
                          _selectionSummary(selectedQuotes),
                        const SizedBox(height: 4),
                      ],
                    ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: selectedQuotes.isNotEmpty ? 92 : 16,
          child: FloatingActionButton.extended(
            heroTag: 'my-quotes-add-products',
            onPressed: widget.onAddProductsTap,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Add Products',
              style: GoogleFonts.urbanist(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyQuotes() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Quotes Yet',
              style: GoogleFonts.urbanist(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your flat, select a package, and calculate to save interior estimates.',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onCreateNewQuoteTap,
              icon: const Icon(Icons.calculate_rounded, size: 19),
              label: Text(
                'Calculate Cost Now',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quoteCard(EstimatorQuote quote) {
    final isSelected = _selectedQuoteIds.contains(quote.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Checkbox, Title, Price & Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(quote),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.quoteName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${quote.bhk} • ${quote.packageTitle}',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          quote.formattedCostRange,
                          style: GoogleFonts.urbanist(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Quote options',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40),
                          iconSize: 18,
                          onSelected: (value) {
                            if (value == 'delete') {
                              setState(
                                () => _selectedQuoteIds.remove(quote.id),
                              );
                              widget.onDeleteQuote(quote.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete quote'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      quote.formattedUpdatedTime,
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle Pill Container: items breakdown & detailed
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      quote.itemsSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => widget.onQuoteTap(quote),
                    child: Text(
                      'Detailed',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons Row: [View Details] [Compare] [Share] [Generate PDF]
            Row(
              children: [
                Expanded(
                  flex: 12,
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => widget.onQuoteTap(quote),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'View Details',
                        maxLines: 1,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 9,
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _toggleSelection(quote),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isSelected
                            ? AppColors.primary
                            : const Color(0xFF475569),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Compare',
                        maxLines: 1,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 8,
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () => _shareQuote(quote),
                      icon: const Icon(Icons.share_outlined, size: 14),
                      label: Text(
                        'Share',
                        maxLines: 1,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 13,
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: _showPdfComingSoon,
                      icon: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Generate PDF',
                        maxLines: 1,
                        style: GoogleFonts.urbanist(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFFFD4B8),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionSummary(List<EstimatorQuote> selectedQuotes) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.quotes.length} Saved Quotes',
                  style: GoogleFonts.urbanist(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${selectedQuotes.length} Selected for Comparison',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF9F1C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: selectedQuotes.length >= 2 ? _showComparison : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF334155),
              disabledForegroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Get all Packages Quote → 5 Tiers >',
              style: GoogleFonts.urbanist(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 2: PRODUCTS Content
// -----------------------------------------------------------------------------
class _ProductsTabContent extends StatefulWidget {
  const _ProductsTabContent({
    required this.selectedPackageId,
    required this.packages,
    required this.onPackageSelected,
    required this.onProductTap,
    required this.onAddToQuote,
    required this.onAddToCart,
    required this.onSelectPackage,
  });

  final String selectedPackageId;
  final List<PackageConfig> packages;
  final ValueChanged<String> onPackageSelected;
  final ValueChanged<Product> onProductTap;
  final Future<void> Function(Product product, int quantity) onAddToQuote;
  final void Function(Product product, int quantity) onAddToCart;
  final VoidCallback onSelectPackage;

  @override
  State<_ProductsTabContent> createState() => _ProductsTabContentState();
}

class _ProductsTabContentState extends State<_ProductsTabContent> {
  String _query = '';
  String _selectedCategory = 'All Items';
  String _packageFilter = 'All Packages';
  final Map<String, int> _quantities = {};
  final Map<String, int> _quoteQuantities = {};
  final Set<String> _comparedProductIds = {};

  List<Product> get _allProducts => Product.estimatorProducts;

  List<Product> get _products => _allProducts.where((product) {
    final matchesQuery =
        _query.trim().isEmpty ||
        product.name.toLowerCase().contains(_query.trim().toLowerCase()) ||
        product.category.toLowerCase().contains(_query.trim().toLowerCase());
    final matchesCategory =
        _selectedCategory == 'All Items' ||
        product.category.toLowerCase() == _selectedCategory.toLowerCase();
    final matchesPackage =
        _packageFilter == 'All Packages' ||
        product.packageId.toLowerCase() == _packageFilter.toLowerCase();
    return matchesQuery && matchesCategory && matchesPackage;
  }).toList();

  double get _currentEstimateTotal {
    var total = 0.0;
    for (final product in _allProducts) {
      final qty = _quoteQuantities[product.id] ?? 0;
      total += product.price * qty;
    }
    return total;
  }

  void _showComparison() {
    final products = _allProducts
        .where((product) => _comparedProductIds.contains(product.id))
        .toList();
    if (products.length < 2) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compare products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: products
              .map(
                (product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text(product.category),
                  trailing: Text(EstimatorQuote.formatCurrency(product.price)),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    const categories = [
      'All Items',
      'TV Unit',
      'Sofa',
      'Bed',
      'Kitchen Cabinet',
      'Dinning Table',
      'Wardrobe',
      'Temple',
      'Center Table',
      'Dressing Table',
    ];
    final packages = widget.packages.isNotEmpty
        ? widget.packages
        : PackageConfig.allPackages;
    final selectedPackage = packages.firstWhere(
      (package) => package.id == widget.selectedPackageId,
      orElse: () => packages.length > 1 ? packages[1] : packages.first,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey('estimator-products-scroll'),
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: TextField(
                          key: const ValueKey('estimator-products-search'),
                          onChanged: (value) => setState(() => _query = value),
                          textInputAction: TextInputAction.search,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: GoogleFonts.urbanist(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 21,
                              color: Color(0xFF94A3B8),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: OutlinedButton(
                        key: const ValueKey('estimator-products-filter'),
                        onPressed: () => setState(() {
                          _selectedCategory = 'All Items';
                          _packageFilter = 'All Packages';
                        }),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Row 1: Package Filters
              SizedBox(
                height: 38,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _catalogChip(
                      label: 'All Packages',
                      selected: _packageFilter == 'All Packages',
                      showCheckmarkOnSelected: true,
                      onTap: () =>
                          setState(() => _packageFilter = 'All Packages'),
                    ),
                    for (final package in packages)
                      _catalogChip(
                        label: package.title,
                        selected: _packageFilter == package.id,
                        onTap: () {
                          setState(() => _packageFilter = package.id);
                          widget.onPackageSelected(package.id);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 2: Category Filters
              SizedBox(
                height: 38,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final category in categories)
                      _catalogChip(
                        label: category,
                        selected: _selectedCategory == category,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        filled: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_comparedProductIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_comparedProductIds.length} selected for comparison',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _comparedProductIds.length >= 2
                            ? _showComparison
                            : null,
                        child: Text(
                          'Compare',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (products.isEmpty)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No products found.',
                      style: GoogleFonts.urbanist(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
              else
                ...products.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  final quantity = _quantities[product.id] ?? 1;
                  final quoteQuantity = _quoteQuantities[product.id] ?? 0;
                  final isCompared = _comparedProductIds.contains(product.id);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 4 : 0,
                      16,
                      index == products.length - 1 ? 16 : 12,
                    ),
                    child: _EstimatorProductCard(
                      product: product,
                      package: selectedPackage,
                      quantity: quantity,
                      quoteQuantity: quoteQuantity,
                      isCompared: isCompared,
                      onTap: () => widget.onProductTap(product),
                      onQuantityChanged: (value) =>
                          setState(() => _quantities[product.id] = value),
                      onCompare: () => setState(() {
                        if (!_comparedProductIds.add(product.id)) {
                          _comparedProductIds.remove(product.id);
                        }
                      }),
                      onAddToQuote: () {
                        setState(() {
                          _quoteQuantities[product.id] =
                              quoteQuantity + quantity;
                        });
                        widget.onAddToQuote(product, quantity);
                      },
                      onAddToCart: () => widget.onAddToCart(product, quantity),
                    ),
                  );
                }),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1EDE9))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Rate Estimate',
                      style: GoogleFonts.urbanist(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${EstimatorQuote.formatCurrency(_currentEstimateTotal)} / sq.ft',
                      style: GoogleFonts.urbanist(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.onSelectPackage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 1,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _packageFilter == 'All Packages'
                                ? 'Select ${selectedPackage.title}'
                                : 'Select ${packages.firstWhere((p) => p.id == _packageFilter, orElse: () => selectedPackage).title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
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
    );
  }

  Widget _catalogChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool filled = false,
    bool showCheckmarkOnSelected = false,
  }) {
    final isFilledStyle = filled && selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isFilledStyle
                ? AppColors.primary
                : (selected ? const Color(0xFFFFF7F2) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected && showCheckmarkOnSelected) ...[
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: isFilledStyle
                      ? Colors.white
                      : (selected
                            ? AppColors.primary
                            : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstimatorProductCard extends StatefulWidget {
  const _EstimatorProductCard({
    required this.product,
    required this.package,
    required this.quantity,
    required this.quoteQuantity,
    required this.isCompared,
    required this.onTap,
    required this.onQuantityChanged,
    required this.onCompare,
    required this.onAddToQuote,
    required this.onAddToCart,
  });

  final Product product;
  final PackageConfig package;
  final int quantity;
  final int quoteQuantity;
  final bool isCompared;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onCompare;
  final VoidCallback onAddToQuote;
  final VoidCallback onAddToCart;

  @override
  State<_EstimatorProductCard> createState() => _EstimatorProductCardState();
}

class _EstimatorProductCardState extends State<_EstimatorProductCard> {
  int _imageIndex = 0;
  bool _dimensionsSwapped = false;
  late final TextEditingController _dimensionController;

  String get _productDimensions => widget.product.dimensions.isNotEmpty
      ? widget.product.dimensions
      : '(L × H) 8.5 ft × 4.0 ft';

  @override
  void initState() {
    super.initState();
    _dimensionController = TextEditingController(
      text: _dimensionValue(_productDimensions),
    );
  }

  @override
  void didUpdateWidget(covariant _EstimatorProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _dimensionsSwapped = false;
      _dimensionController.text = _dimensionValue(_productDimensions);
    }
  }

  @override
  void dispose() {
    _dimensionController.dispose();
    super.dispose();
  }

  List<String> get _images {
    if (widget.product.images.isNotEmpty) {
      return widget.product.images;
    }
    return [widget.product.image];
  }

  void _nextImage() {
    if (_images.length <= 1) return;
    setState(() {
      _imageIndex = (_imageIndex + 1) % _images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final package = widget.package;
    final quantity = widget.quantity;
    final quoteQuantity = widget.quoteQuantity;
    final isCompared = widget.isCompared;

    final materialText = product.material.isNotEmpty
        ? product.material
        : (product.description.isNotEmpty
              ? product.description
              : product.category);
    final dimensionLabel = _dimensionLabel(_productDimensions);
    final displayedDimensionLabel = _dimensionsSwapped
        ? _swapDimensionParts(dimensionLabel)
        : dimensionLabel;

    final images = _images;
    final currentImageUrl = images[_imageIndex % images.length];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Thumbnail Image
              InkWell(
                onTap: images.length > 1 ? _nextImage : widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 86,
                    height: 86,
                    child:
                        currentImageUrl.startsWith('http://') ||
                            currentImageUrl.startsWith('https://')
                        ? CachedNetworkImage(
                            imageUrl: currentImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ColoredBox(
                              color: Color(0xFFF1F5F9),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              AppAssets.livingRoomImage,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            currentImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFFF1F5F9),
                              child: Icon(
                                Icons.chair_alt_outlined,
                                size: 34,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              EstimatorQuote.formatCurrency(
                                product.price * quantity,
                              ),
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (quantity > 1)
                              Text(
                                '${EstimatorQuote.formatCurrency(product.price)} each',
                                style: GoogleFonts.urbanist(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Material / Subtitle
                    Text(
                      materialText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Package Title tag
                    Text(
                      product.packageTitle.isNotEmpty
                          ? product.packageTitle
                          : package.title,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Dimensions and quantity controls
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: _DimensionControl(
                            key: ValueKey(
                              'estimator-product-dimensions-${product.id}',
                            ),
                            label: displayedDimensionLabel,
                            controller: _dimensionController,
                            onSwap: () {
                              setState(() {
                                _dimensionsSwapped = !_dimensionsSwapped;
                                final swappedValue = _swapDimensionParts(
                                  _dimensionController.text,
                                );
                                _dimensionController.value = TextEditingValue(
                                  text: swappedValue,
                                  selection: TextSelection.collapsed(
                                    offset: swappedValue.length,
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QuantityControl(
                          quantity: quantity,
                          onChanged: widget.onQuantityChanged,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Buttons: [Compare] [Add to Quote v] [Add to Cart]
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: widget.onCompare,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isCompared
                          ? AppColors.primary
                          : const Color(0xFF475569),
                      backgroundColor: isCompared
                          ? const Color(0xFFFFF7F2)
                          : Colors.white,
                      side: BorderSide(
                        color: isCompared
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isCompared ? 'Compared' : 'Compare',
                      maxLines: 1,
                      style: GoogleFonts.urbanist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: widget.onAddToQuote,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFFFFD4B8),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            quoteQuantity > 0
                                ? 'Added ($quoteQuantity)'
                                : 'Add to Quote',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: widget.onAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      maxLines: 1,
                      style: GoogleFonts.urbanist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _swapDimensionParts(String value) {
  final parts = value.split(RegExp(r'\s*[×xX]\s*'));
  return parts.length == 2 ? '${parts[1]} × ${parts[0]}' : value;
}

String _dimensionLabel(String dimensions) {
  final match = RegExp(r'^\((.*?)\)\s*(.*)$').firstMatch(dimensions);
  return match?.group(1) ?? 'L × H';
}

String _dimensionValue(String dimensions) {
  final match = RegExp(r'^\((.*?)\)\s*(.*)$').firstMatch(dimensions);
  return match?.group(2) ?? dimensions;
}

class _DimensionControl extends StatelessWidget {
  const _DimensionControl({
    super.key,
    required this.label,
    required this.controller,
    required this.onSwap,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 7, right: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 8,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 26,
                    child: IconButton(
                      tooltip: 'Swap dimensions',
                      onPressed: onSwap,
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.sync_rounded,
                        size: 15,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              color: Colors.white,
              child: Text(
                '($label)',
                style: GoogleFonts.urbanist(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$quantity',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add,
                    onTap: () => onChanged(quantity + 1),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              color: Colors.white,
              child: Text(
                'Qty',
                style: GoogleFonts.urbanist(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          icon,
          size: 13,
          color: onTap != null
              ? const Color(0xFF475569)
              : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _ProductActionButton extends StatelessWidget {
  const _ProductActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: primary || selected
              ? Colors.white
              : const Color(0xFF334155),
          backgroundColor: primary || selected
              ? AppColors.primary
              : const Color(0xFFF8FAFC),
          side: BorderSide(
            color: primary || selected
                ? AppColors.primary
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: FittedBox(child: Text(label, maxLines: 1)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Interactive Estimate Result Bottom Sheet
// -----------------------------------------------------------------------------
class _EstimateResultBottomSheet extends StatelessWidget {
  const _EstimateResultBottomSheet({
    required this.quote,
    required this.onSaveQuote,
    required this.onExploreProducts,
  });

  final EstimatorQuote quote;
  final VoidCallback onSaveQuote;
  final VoidCallback onExploreProducts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.quoteName,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${quote.bhk} • ${quote.packageTitle} • ${quote.purpose}',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Estimated Cost Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3EB), Color(0xFFFFE8D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD4B8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL ESTIMATED COST',
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '₹${quote.ratePerSqFt.toInt()}/sqft',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quote.formattedCostRange,
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF24211F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '*Approximate interior estimate for ${quote.approxAreaSqFt} sq.ft (${quote.bhk}) with ${quote.packageTitle}.',
                  style: GoogleFonts.urbanist(
                    fontSize: 10.5,
                    color: const Color(0xFF756F69),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Estimated Room-Wise Breakdown',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          // Breakdown list
          ...quote.roomBreakdown.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    EstimatorQuote.formatCurrency(entry.value),
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Action buttons: Save Quote & Explore Products
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSaveQuote,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    'Save Quote',
                    style: GoogleFonts.urbanist(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onExploreProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    'Browse Products',
                    style: GoogleFonts.urbanist(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
