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

  @override
  void initState() {
    super.initState();
    final currentQuoteName = ref.read(estimatorViewModelProvider).quoteName;
    _quoteNameController = TextEditingController(text: currentQuoteName);
  }

  @override
  void dispose() {
    _quoteNameController.dispose();
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
            await ref
                .read(estimatorViewModelProvider.notifier)
                .saveCurrentQuote(quote);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimatorViewModelProvider);
    final vm = ref.read(estimatorViewModelProvider.notifier);

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
              onTabSelected: (index) => vm.setTab(index),
            ),

            // Body per tab
            Expanded(
              child: IndexedStack(
                index: state.currentTabIndex,
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
                            _showEstimateSummarySheet(quote);
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
                    onPackageSelected: (id) => vm.selectPackage(id),
                    onProductTap: (product) =>
                        context.push(AppRoutes.productDetails, extra: product),
                    onSelectPackage: () {
                      vm.setTab(0);
                      vm.goToPackageSelection();
                    },
                    onAddToCart: (product, quantity) {
                      ref
                          .read(cartViewModelProvider.notifier)
                          .addToCart(product, quantity: quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Text(
                          _tabTitles[index],
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF8C8681),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        height: 2.5,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                      child: Image.asset(
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

  @override
  Widget build(BuildContext context) {
    final packages = PackageConfig.allPackages;

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
                    child: Text(
                      '${packages.length} Packages Available',
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
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
                            Image.asset(
                              imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                    AppAssets.livingRoomImage,
                                    fit: BoxFit.cover,
                                  ),
                            ),

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
                                  children: List.generate(3, (dotIndex) {
                                    final isActive = dotIndex == imageIndex;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      width: isActive ? 12 : 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.45,
                                              ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  }),
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
        quote.purpose.toLowerCase().contains(normalizedQuery);
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
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: Color(0xFFF0D7C8)),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: GoogleFonts.urbanist(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        key: const ValueKey('saved-quotes-search'),
                        onChanged: (value) => setState(() => _query = value),
                        textInputAction: TextInputAction.search,
                        style: GoogleFonts.urbanist(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Search saved quotes',
                          hintStyle: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 17,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _showFilters,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.filter_list_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.quotes.isEmpty
                  ? _emptyQuotes()
                  : filteredQuotes.isEmpty
                  ? Center(
                      child: Text(
                        'No quotes match your search.',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 16),
                      itemCount: filteredQuotes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _quoteCard(filteredQuotes[index]),
                    ),
            ),
            if (widget.quotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                child: SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: _showPdfComingSoon,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                    label: Text(
                      'Generate All Packages PDFs',
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFF0D7C8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            if (selectedQuotes.isNotEmpty) _selectionSummary(selectedQuotes),
            const SizedBox(height: 4),
          ],
        ),
        Positioned(
          right: 12,
          bottom: selectedQuotes.isNotEmpty ? 88 : 12,
          child: FloatingActionButton.extended(
            heroTag: 'my-quotes-add-products',
            onPressed: widget.onAddProductsTap,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
            label: Text(
              'Add Products',
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
              size: 44,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No Saved Quotes Yet',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your flat, select a package, and calculate to save interior estimates.',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: widget.onCreateNewQuoteTap,
              icon: const Icon(Icons.calculate_rounded, size: 17),
              label: const Text('Calculate Cost Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quoteCard(EstimatorQuote quote) {
    final isSelected = _selectedQuoteIds.contains(quote.id);
    final date = quote.createdAt;
    final updatedLabel = 'Updated ${date.month}/${date.day}/${date.year}';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFF0A16B),
          width: isSelected ? 1.3 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(quote),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    quote.quoteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  quote.formattedCostRange,
                  style: GoogleFonts.urbanist(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Quote options',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40),
                  iconSize: 17,
                  onSelected: (value) {
                    if (value == 'delete') {
                      setState(() => _selectedQuoteIds.remove(quote.id));
                      widget.onDeleteQuote(quote.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete quote')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 27),
              child: Text(
                '${quote.bhk} • ${quote.packageTitle}',
                style: GoogleFonts.urbanist(
                  fontSize: 9.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 27, top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${quote.roomBreakdown.length} room categories • ${quote.approxAreaSqFt} sqft',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Text(
                    updatedLabel,
                    style: GoogleFonts.urbanist(
                      fontSize: 8.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _actionButton(
                  icon: Icons.visibility_outlined,
                  label: 'View Details',
                  onPressed: () => widget.onQuoteTap(quote),
                ),
                _actionButton(
                  icon: Icons.compare_arrows_rounded,
                  label: 'Compare',
                  onPressed: () => _toggleSelection(quote),
                ),
                _actionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: () => _shareQuote(quote),
                ),
                _actionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Generate PDF',
                  onPressed: _showPdfComingSoon,
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
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${selectedQuotes.length} selected for comparison',
                  style: GoogleFonts.urbanist(
                    fontSize: 9,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: selectedQuotes.length >= 2 ? _showComparison : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF475569),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: GoogleFonts.urbanist(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Compare Selected'),
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
    required this.onPackageSelected,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onSelectPackage,
  });

  final String selectedPackageId;
  final ValueChanged<String> onPackageSelected;
  final ValueChanged<Product> onProductTap;
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

  List<Product> get _products => Product.sampleProducts.where((product) {
    final matchesQuery =
        _query.trim().isEmpty ||
        product.name.toLowerCase().contains(_query.trim().toLowerCase()) ||
        product.category.toLowerCase().contains(_query.trim().toLowerCase());
    final matchesCategory =
        _selectedCategory == 'All Items' ||
        product.category == _selectedCategory;
    return matchesQuery && matchesCategory;
  }).toList();

  double get _quoteTotal {
    var total = 0.0;
    for (final product in Product.sampleProducts) {
      total += product.price * (_quoteQuantities[product.id] ?? 0);
    }
    return total;
  }

  void _showComparison() {
    final products = Product.sampleProducts
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
    final productCategories =
        Product.sampleProducts
            .map((product) => product.category)
            .toSet()
            .toList()
          ..sort();
    final categories = ['All Items', ...productCategories];
    final selectedPackage = PackageConfig.allPackages.firstWhere(
      (package) => package.id == widget.selectedPackageId,
      orElse: () => PackageConfig.allPackages[1],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    key: const ValueKey('estimator-products-search'),
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.urbanist(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: GoogleFonts.urbanist(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const ValueKey('estimator-products-filter'),
                onPressed: () => setState(() {
                  _selectedCategory = 'All Items';
                  _packageFilter = 'All Packages';
                }),
                icon: const Icon(Icons.tune_rounded, size: 17),
                visualDensity: VisualDensity.compact,
                tooltip: 'Clear filters',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 31,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            children: [
              _catalogChip(
                label: 'All Packages',
                selected: _packageFilter == 'All Packages',
                onTap: () => setState(() => _packageFilter = 'All Packages'),
              ),
              for (final package in PackageConfig.allPackages)
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
        SizedBox(
          height: 31,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            children: [
              for (final category in categories)
                _catalogChip(
                  label: category,
                  selected: _selectedCategory == category,
                  onTap: () => setState(() => _selectedCategory = category),
                  filled: true,
                ),
            ],
          ),
        ),
        if (_comparedProductIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_comparedProductIds.length} selected for comparison',
                    style: GoogleFonts.urbanist(
                      fontSize: 9,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _comparedProductIds.length >= 2
                      ? _showComparison
                      : null,
                  child: const Text('Compare'),
                ),
              ],
            ),
          ),
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Text(
                    'No products found.',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 8),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final quantity = _quantities[product.id] ?? 1;
                    final quoteQuantity = _quoteQuantities[product.id] ?? 0;
                    final isCompared = _comparedProductIds.contains(product.id);
                    return _EstimatorProductCard(
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
                      onAddToQuote: () => setState(() {
                        _quoteQuantities[product.id] = quoteQuantity + quantity;
                      }),
                      onAddToCart: () => widget.onAddToCart(product, quantity),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
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
                      'Total Sale Estimate',
                      style: GoogleFonts.urbanist(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      EstimatorQuote.formatCurrency(_quoteTotal),
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: widget.onSelectPackage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Select ${selectedPackage.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelStyle: GoogleFonts.urbanist(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF475569),
        ),
        backgroundColor: Colors.white,
        selectedColor: filled ? AppColors.primary : AppColors.primary,
        side: BorderSide(
          color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }
}

class _EstimatorProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 72,
                    height: 68,
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFF1F5F9),
                        child: Icon(
                          Icons.chair_alt_outlined,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.urbanist(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          EstimatorQuote.formatCurrency(product.price),
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.description.isEmpty
                          ? product.category
                          : product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 8.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2EB),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        package.title,
                        style: GoogleFonts.urbanist(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          product.category,
                          style: GoogleFonts.urbanist(
                            fontSize: 8,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        _QuantityControl(
                          quantity: quantity,
                          onChanged: onQuantityChanged,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ProductActionButton(
                  label: isCompared ? 'Compared' : 'Compare',
                  onPressed: onCompare,
                  selected: isCompared,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _ProductActionButton(
                  label: quoteQuantity > 0 ? 'Added to Quote' : 'Add to Quote',
                  onPressed: onAddToQuote,
                  selected: quoteQuantity > 0,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _ProductActionButton(
                  label: 'Add to Cart',
                  onPressed: onAddToCart,
                  primary: true,
                ),
              ),
            ],
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
    return Container(
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: GoogleFonts.urbanist(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onTap: () => onChanged(quantity + 1),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 11, color: const Color(0xFF475569)),
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
      height: 25,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 3),
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
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: GoogleFonts.urbanist(
            fontSize: 8,
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
