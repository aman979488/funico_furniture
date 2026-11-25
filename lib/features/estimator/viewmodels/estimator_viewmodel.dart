import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/product.dart';
import '../models/estimator_model.dart';
import '../repositories/estimator_repository.dart';

class EstimatorState {
  final int currentTabIndex; // 0: CALCULATE, 1: MY QUOTES, 2: PRODUCTS
  final int calculateStep; // 1: Config & Purpose, 2: Select Package
  final String quoteName;
  final String selectedBhk;
  final String selectedPurpose;
  final String selectedPackageId;
  final Map<String, int> packageImageIndices;
  final List<EstimatorQuote> savedQuotes;
  final EstimatorQuote? latestEstimate;
  final bool isLoading;
  final List<PackageConfig> packages;
  final bool packagesLoading;

  const EstimatorState({
    this.currentTabIndex = 0,
    this.calculateStep = 1,
    this.quoteName = 'Quote 1',
    this.selectedBhk = '1BHK',
    this.selectedPurpose = 'Renovate',
    this.selectedPackageId = 'modern',
    this.packageImageIndices = const {
      'basic': 0,
      'modern': 0,
      'deluxe': 0,
      'premium': 0,
      'luxury': 0,
    },
    this.savedQuotes = const [],
    this.latestEstimate,
    this.isLoading = false,
    this.packages = const [],
    this.packagesLoading = true,
  });

  BhkConfig get currentBhkConfig {
    return BhkConfig.allConfigs.firstWhere(
      (c) => c.bhk == selectedBhk,
      orElse: () => BhkConfig.allConfigs.first,
    );
  }

  EstimatorPurposeInfo get currentPurposeInfo {
    return EstimatorPurposeInfo.allPurposes.firstWhere(
      (p) => p.id == selectedPurpose,
      orElse: () => EstimatorPurposeInfo.allPurposes.first,
    );
  }

  PackageConfig get currentPackageConfig {
    return packages.firstWhere(
      (p) => p.id == selectedPackageId,
      orElse: () => packages.isNotEmpty
          ? packages[1 % packages.length]
          : PackageConfig.allPackages[1],
    );
  }

  EstimatorState copyWith({
    int? currentTabIndex,
    int? calculateStep,
    String? quoteName,
    String? selectedBhk,
    String? selectedPurpose,
    String? selectedPackageId,
    Map<String, int>? packageImageIndices,
    List<EstimatorQuote>? savedQuotes,
    EstimatorQuote? latestEstimate,
    bool? isLoading,
    List<PackageConfig>? packages,
    bool? packagesLoading,
  }) {
    return EstimatorState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      calculateStep: calculateStep ?? this.calculateStep,
      quoteName: quoteName ?? this.quoteName,
      selectedBhk: selectedBhk ?? this.selectedBhk,
      selectedPurpose: selectedPurpose ?? this.selectedPurpose,
      selectedPackageId: selectedPackageId ?? this.selectedPackageId,
      packageImageIndices: packageImageIndices ?? this.packageImageIndices,
      savedQuotes: savedQuotes ?? this.savedQuotes,
      latestEstimate: latestEstimate ?? this.latestEstimate,
      isLoading: isLoading ?? this.isLoading,
      packages: packages ?? this.packages,
      packagesLoading: packagesLoading ?? this.packagesLoading,
    );
  }
}

class EstimatorViewModel extends Notifier<EstimatorState> {
  late final EstimatorRepository _repository;

  @override
  EstimatorState build() {
    _repository = ref.watch(estimatorRepositoryProvider);
    _loadQuotes();
    _loadPackages();
    return EstimatorState(
      packages: List<PackageConfig>.from(PackageConfig.allPackages),
    );
  }

  Future<void> _loadQuotes() async {
    final quotes = await _repository.loadSavedQuotes();
    state = state.copyWith(savedQuotes: quotes);
  }

  Future<void> _loadPackages() async {
    List<PackageConfig> pkgs;
    try {
      pkgs = await _repository.fetchPackages();
    } catch (error, stackTrace) {
      debugPrint(
        'Estimator package loading failed; using bundled packages: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      pkgs = List<PackageConfig>.from(PackageConfig.allPackages);
    }

    if (pkgs.isEmpty) {
      pkgs = List<PackageConfig>.from(PackageConfig.allPackages);
    }

    // Build default image indices for fetched packages
    final indices = <String, int>{};
    for (final p in pkgs) {
      indices[p.id] = 0;
    }
    state = state.copyWith(
      packages: pkgs,
      packageImageIndices: indices,
      packagesLoading: false,
    );
  }

  void setTab(int index) {
    if (state.currentTabIndex != index) {
      state = state.copyWith(currentTabIndex: index);
    }
  }

  void goToPackageSelection() {
    state = state.copyWith(calculateStep: 2);
  }

  bool handleBackStep() {
    if (state.currentTabIndex == 0 && state.calculateStep == 2) {
      state = state.copyWith(calculateStep: 1);
      return true; // Handled internally
    }
    return false; // Let router/navigator handle
  }

  void setQuoteName(String name) {
    state = state.copyWith(quoteName: name);
  }

  void selectBhk(String bhk) {
    state = state.copyWith(selectedBhk: bhk);
  }

  void nextBhk() {
    final configs = BhkConfig.allConfigs;
    final currentIndex = configs.indexWhere((c) => c.bhk == state.selectedBhk);
    if (currentIndex != -1 && currentIndex < configs.length - 1) {
      state = state.copyWith(selectedBhk: configs[currentIndex + 1].bhk);
    } else {
      state = state.copyWith(selectedBhk: configs.first.bhk);
    }
  }

  void prevBhk() {
    final configs = BhkConfig.allConfigs;
    final currentIndex = configs.indexWhere((c) => c.bhk == state.selectedBhk);
    if (currentIndex > 0) {
      state = state.copyWith(selectedBhk: configs[currentIndex - 1].bhk);
    } else {
      state = state.copyWith(selectedBhk: configs.last.bhk);
    }
  }

  void selectPurpose(String purpose) {
    state = state.copyWith(selectedPurpose: purpose);
  }

  void selectPackage(String packageId) {
    state = state.copyWith(selectedPackageId: packageId);
  }

  void nextPackageImage(String packageId) {
    final pkg = state.packages.firstWhere(
      (p) => p.id == packageId,
      orElse: () => state.packages.isNotEmpty
          ? state.packages.first
          : PackageConfig.allPackages.first,
    );
    if (pkg.images.isEmpty) return;
    final current = state.packageImageIndices[packageId] ?? 0;
    final next = (current + 1) % pkg.images.length;
    final updated = Map<String, int>.from(state.packageImageIndices);
    updated[packageId] = next;
    state = state.copyWith(packageImageIndices: updated);
  }

  void prevPackageImage(String packageId) {
    final pkg = state.packages.firstWhere(
      (p) => p.id == packageId,
      orElse: () => state.packages.isNotEmpty
          ? state.packages.first
          : PackageConfig.allPackages.first,
    );
    if (pkg.images.isEmpty) return;
    final current = state.packageImageIndices[packageId] ?? 0;
    final prev = (current - 1 + pkg.images.length) % pkg.images.length;
    final updated = Map<String, int>.from(state.packageImageIndices);
    updated[packageId] = prev;
    state = state.copyWith(packageImageIndices: updated);
  }

  EstimatorQuote calculateEstimate() {
    final estimate = _repository.calculateEstimate(
      quoteName: state.quoteName,
      bhk: state.selectedBhk,
      purpose: state.selectedPurpose,
      packageId: state.selectedPackageId,
      packages: state.packages,
    );
    state = state.copyWith(latestEstimate: estimate);
    return estimate;
  }

  Future<void> addProductToQuote(Product product, int quantity) async {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be greater than 0');
    }

    const quoteId = 'estimator_product_quote';
    EstimatorQuote? existingQuote;
    for (final quote in state.savedQuotes) {
      if (quote.id == quoteId) {
        existingQuote = quote;
        break;
      }
    }

    final packages = state.packages.isNotEmpty
        ? state.packages
        : PackageConfig.allPackages;
    final package = packages.firstWhere(
      (item) => item.id == product.packageId,
      orElse: () => state.currentPackageConfig,
    );
    final packageTitle = product.packageTitle.isNotEmpty
        ? product.packageTitle
        : package.title;
    final itemKey = '$packageTitle - ${product.name}';
    final breakdown = Map<String, double>.from(
      existingQuote?.roomBreakdown ?? const {},
    );
    breakdown[itemKey] =
        (breakdown[itemKey] ?? 0) + product.price * quantity;

    final packageTitles = breakdown.keys
        .map((item) => item.split(' - ').first)
        .toSet();
    final total = breakdown.values.fold<double>(0, (sum, price) => sum + price);
    final itemNames = breakdown.keys.take(2).join(', ');
    final moreItems = breakdown.length > 2 ? ', ...' : '';
    final quote = EstimatorQuote(
      id: quoteId,
      quoteName: 'Product Quote',
      bhk: state.selectedBhk,
      purpose: state.selectedPurpose,
      packageTitle: packageTitles.length == 1
          ? packageTitles.first
          : 'Multiple Packages',
      ratePerSqFt: package.ratePerSqFt,
      approxAreaSqFt: state.currentBhkConfig.approxAreaSqFt,
      estimatedCostMin: total,
      estimatedCostMax: total,
      createdAt: DateTime.now(),
      itemsSummaryText:
          '${breakdown.length} items ($itemNames$moreItems)',
      roomBreakdown: breakdown,
    );

    await _repository.saveQuote(quote);
    final updatedQuotes = await _repository.loadSavedQuotes();
    state = state.copyWith(savedQuotes: updatedQuotes);
  }

  Future<void> saveCurrentQuote(EstimatorQuote quote) async {
    await _repository.saveQuote(quote);
    final updatedQuotes = await _repository.loadSavedQuotes();
    state = state.copyWith(savedQuotes: updatedQuotes);
  }

  Future<void> deleteQuote(String quoteId) async {
    await _repository.deleteQuote(quoteId);
    final updatedQuotes = await _repository.loadSavedQuotes();
    state = state.copyWith(savedQuotes: updatedQuotes);
  }
}

final estimatorViewModelProvider =
    NotifierProvider<EstimatorViewModel, EstimatorState>(
      EstimatorViewModel.new,
    );
