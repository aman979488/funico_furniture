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
  final List<BhkConfig> bhkConfigs;

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
    this.bhkConfigs = const [],
  });

  BhkConfig get currentBhkConfig {
    final list = bhkConfigs.isNotEmpty ? bhkConfigs : BhkConfig.allConfigs;
    return list.firstWhere(
      (c) => c.bhk == selectedBhk,
      orElse: () => list.first,
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
    List<BhkConfig>? bhkConfigs,
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
      bhkConfigs: bhkConfigs ?? this.bhkConfigs,
    );
  }
}

class EstimatorViewModel extends Notifier<EstimatorState> {
  late final EstimatorRepository _repository;
  int _productQuoteSequence = 0;

  @override
  EstimatorState build() {
    _repository = ref.watch(estimatorRepositoryProvider);
    _loadQuotes();
    _loadPackages();
    _loadBhkConfigs();
    return EstimatorState(
      packages: List<PackageConfig>.from(PackageConfig.allPackages),
      bhkConfigs: List<BhkConfig>.from(BhkConfig.allConfigs),
    );
  }

  Future<void> _loadBhkConfigs() async {
    try {
      final configs = await _repository.fetchBhkConfigs();
      if (configs.isNotEmpty) {
        state = state.copyWith(bhkConfigs: configs);
      }
    } catch (e) {
      debugPrint('Failed to load BHK 3D configs: $e');
    }
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
    final configs =
        state.bhkConfigs.isNotEmpty ? state.bhkConfigs : BhkConfig.allConfigs;
    final currentIndex = configs.indexWhere((c) => c.bhk == state.selectedBhk);
    if (currentIndex != -1 && currentIndex < configs.length - 1) {
      state = state.copyWith(selectedBhk: configs[currentIndex + 1].bhk);
    } else {
      state = state.copyWith(selectedBhk: configs.first.bhk);
    }
  }

  void prevBhk() {
    final configs =
        state.bhkConfigs.isNotEmpty ? state.bhkConfigs : BhkConfig.allConfigs;
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

    final savedQuotes = await _repository.loadSavedQuotes();
    EstimatorQuote? legacyProductQuote;
    for (final quote in savedQuotes) {
      if (quote.id == EstimatorQuote.productQuoteId) {
        legacyProductQuote = quote;
        break;
      }
    }
    final productQuotes = <EstimatorQuote>[];

    if (legacyProductQuote != null) {
      for (final entry in legacyProductQuote.roomBreakdown.entries) {
        final productName = legacyProductQuote.productNameForBreakdownKey(
          entry.key,
        );
        productQuotes.add(
          _createProductQuote(
            productName,
            entry.value,
            createdAt: legacyProductQuote.createdAt,
          ),
        );
      }
    }

    productQuotes.add(
      _createProductQuote(product.name, product.price * quantity),
    );
    await _repository.saveProductQuotes(
      productQuotes,
      removeQuoteId: legacyProductQuote?.id,
    );
    final updatedQuotes = await _repository.loadSavedQuotes();
    state = state.copyWith(savedQuotes: updatedQuotes);
  }

  EstimatorQuote _createProductQuote(
    String productName,
    double total, {
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    final id =
        '${EstimatorQuote.productQuoteIdPrefix}${now.microsecondsSinceEpoch}_${_productQuoteSequence++}';
    return EstimatorQuote(
      id: id,
      quoteName: productName,
      bhk: '',
      purpose: '',
      packageTitle: '',
      ratePerSqFt: 0,
      approxAreaSqFt: 0,
      estimatedCostMin: total,
      estimatedCostMax: total,
      createdAt: createdAt ?? now,
      roomBreakdown: {productName: total},
    );
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
