import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/features/cart/views/cart_screen.dart';
import 'package:funica/features/estimator/models/estimator_model.dart';
import 'package:funica/features/estimator/repositories/estimator_repository.dart';
import 'package:funica/features/estimator/viewmodels/estimator_viewmodel.dart';
import 'package:funica/features/estimator/views/estimator_screen.dart';
import 'package:funica/shared/models/product.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PackageConfig reads image paths from Firestore data', () {
    final package = PackageConfig.fromFirestore('modern', {
      'title': 'Modern Package',
      'ratePerSqFt': 1500,
      'coverImagePath': 'estimator_packages/modern/Sofa/cover.webp',
      'imagePaths': [
        'estimator_packages/modern/Sofa/cover.webp',
        'estimator_packages/modern/Bed/bedroom.png',
      ],
      'description': 'Modern interiors',
      'order': 1,
    });

    expect(package.imageAsset, 'estimator_packages/modern/Sofa/cover.webp');
    expect(package.images, [
      'estimator_packages/modern/Sofa/cover.webp',
      'estimator_packages/modern/Bed/bedroom.png',
    ]);
    expect(package.ratePerSqFt, 1500);
    expect(package.order, 1);
  });

  test('estimate calculation uses the fetched package configuration', () {
    const package = PackageConfig(
      id: 'custom',
      title: 'Custom Package',
      ratePerSqFt: 1750,
      imageAsset: 'estimator_packages/custom/cover.jpg',
      images: ['estimator_packages/custom/cover.jpg'],
      description: '',
    );

    final quote = EstimatorRepository().calculateEstimate(
      quoteName: 'Custom estimate',
      bhk: '1BHK',
      purpose: 'Renovate',
      packageId: package.id,
      packages: [package],
    );

    expect(quote.packageTitle, package.title);
    expect(quote.ratePerSqFt, package.ratePerSqFt);
  });

  test('product quotes show selected products without package names', () {
    final quote = EstimatorQuote(
      id: EstimatorQuote.productQuoteId,
      quoteName: 'Product Quote',
      bhk: '1BHK',
      purpose: 'Renovate',
      packageTitle: 'Basic Package',
      estimatedCostMin: 18500,
      estimatedCostMax: 18500,
      createdAt: DateTime(2026),
      roomBreakdown: const {'Basic Package - Wall Mount TV Unit': 18500.0},
    );

    expect(quote.displayName, 'Wall Mount TV Unit');
    expect(quote.itemsSummary, '1 product added to My Quotes');
    expect(quote.productNames, ['Wall Mount TV Unit']);
  });

  test('each Add to Quote action creates a separate product quote', () async {
    const firstProduct = Product(
      id: 'quote-product-one',
      name: 'Oak Shelf',
      category: 'Storage',
      price: 1800,
      image: '',
    );
    const secondProduct = Product(
      id: 'quote-product-two',
      name: 'Desk Lamp',
      category: 'Lighting',
      price: 2200,
      image: '',
    );
    final container = ProviderContainer(
      overrides: [
        estimatorRepositoryProvider.overrideWithValue(
          _TestEstimatorRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final viewModel = container.read(estimatorViewModelProvider.notifier);

    await viewModel.addProductToQuote(firstProduct, 2);
    await viewModel.addProductToQuote(secondProduct, 1);

    final productQuotes = container
        .read(estimatorViewModelProvider)
        .savedQuotes
        .where((quote) => quote.isProductQuote)
        .toList();
    expect(productQuotes, hasLength(2));
    expect(productQuotes.map((quote) => quote.displayName), [
      'Oak Shelf',
      'Desk Lamp',
    ]);
    expect(productQuotes[0].roomBreakdown.keys, ['Oak Shelf']);
    expect(productQuotes[1].roomBreakdown.keys, ['Desk Lamp']);
    expect(productQuotes[0].id, isNot(productQuotes[1].id));
    expect(
      container.read(estimatorViewModelProvider).savedQuotes.last.id,
      productQuotes.last.id,
    );
  });

  test(
    'splits a previously combined product quote on the next addition',
    () async {
      final repository = _TestEstimatorRepository();
      await repository.saveQuote(
        EstimatorQuote(
          id: EstimatorQuote.productQuoteId,
          quoteName: 'Product Quote',
          bhk: '1BHK',
          purpose: 'Renovate',
          packageTitle: 'Basic Package',
          estimatedCostMin: 5000,
          estimatedCostMax: 5000,
          createdAt: DateTime(2026),
          roomBreakdown: const {
            'Basic Package - Wall Mount TV Unit': 3000,
            'Basic Package - Coffee Table': 2000,
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [estimatorRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(estimatorViewModelProvider.notifier)
          .addProductToQuote(
            const Product(
              id: 'quote-product-three',
              name: 'Oak Shelf',
              category: 'Storage',
              price: 1800,
              image: '',
            ),
            1,
          );

      final productQuotes = container
          .read(estimatorViewModelProvider)
          .savedQuotes
          .where((quote) => quote.isProductQuote)
          .toList();
      expect(productQuotes.map((quote) => quote.displayName), [
        'Wall Mount TV Unit',
        'Coffee Table',
        'Oak Shelf',
      ]);
      expect(
        productQuotes.every((quote) => quote.roomBreakdown.length == 1),
        isTrue,
      );
    },
  );

  testWidgets('Estimator screen shows selected package and estimate details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          estimatorRepositoryProvider.overrideWithValue(
            _TestEstimatorRepository(),
          ),
        ],
        child: const MaterialApp(home: EstimatorScreen()),
      ),
    );
    await _pumpEstimator(tester);

    // 1. App Bar Title
    expect(find.text('Calculate Your Interior Cost'), findsOneWidget);

    // 2. Tabs
    expect(find.text('CALCULATE'), findsOneWidget);
    expect(find.text('MY QUOTES'), findsOneWidget);
    expect(find.text('PRODUCTS'), findsOneWidget);

    // 3. Step 1 sections
    expect(find.text('Name of the Quote'), findsOneWidget);
    expect(find.text('Select Configuration (1BHK - 5BHK)'), findsOneWidget);
    expect(find.text('Select Purpose'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    final quoteNameField = tester.widget<TextField>(find.byType(TextField));
    expect(quoteNameField.decoration?.prefixIcon, isA<Icon>());

    // 4. Tap Next Step -> Should navigate to Step 2: Select Package
    final nextStepFinder = find.text('Next Step');
    await tester.ensureVisible(nextStepFinder);
    await tester.tap(nextStepFinder);
    await _pumpEstimator(tester);

    // 5. Verify Step 2 UI (Matching reference image)
    expect(find.text('4. Select Package'), findsOneWidget);
    expect(find.text('5 Packages Available'), findsOneWidget);

    // Verify all 5 packages are present
    expect(find.text('Basic Package'), findsOneWidget);
    expect(find.text('₹1,000 /sqft'), findsOneWidget);

    expect(find.text('Modern Package'), findsOneWidget);
    expect(find.text('₹1,500 /sqft'), findsOneWidget);

    expect(find.text('Deluxe Package'), findsOneWidget);
    expect(find.text('₹2,000 /sqft'), findsOneWidget);

    expect(find.text('Premium Package'), findsOneWidget);
    expect(find.text('₹2,500 /sqft'), findsOneWidget);

    expect(find.text('Luxury Package'), findsOneWidget);
    expect(find.text('₹3,000 /sqft'), findsOneWidget);

    await tester.tap(find.text('Basic Package'));
    await _pumpEstimator(tester);

    // Verify Calculate button
    expect(find.text('Calculate Est. Cost'), findsOneWidget);

    // 6. Tap Calculate Est. Cost
    final calcCostFinder = find.text('Calculate Est. Cost');
    await tester.tap(calcCostFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('estimate-details-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('estimate-selected-package-image')),
      findsOneWidget,
    );
    expect(find.text('Basic Package'), findsOneWidget);
    expect(find.text('₹1,000 /sqft'), findsOneWidget);
    expect(find.text('Quote 1'), findsOneWidget);
    expect(find.text('1BHK'), findsOneWidget);
    expect(find.text('Renovate'), findsOneWidget);
    expect(find.text('Estimated cost'), findsOneWidget);
    expect(find.text('TOTAL ESTIMATED COST'), findsNothing);
    expect(find.text('Estimated Room-Wise Breakdown'), findsNothing);
    expect(find.text('Save Quote'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('estimate-details-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Calculate Est. Cost'), findsOneWidget);
  });

  testWidgets('Estimator tabs navigate with a horizontal swipe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          estimatorRepositoryProvider.overrideWithValue(
            _TestEstimatorRepository(),
          ),
        ],
        child: const MaterialApp(home: EstimatorScreen()),
      ),
    );
    await _pumpEstimator(tester);

    final tabPagesFinder = find.byKey(const ValueKey('estimator-tab-pages'));
    final pageController = tester.widget<PageView>(tabPagesFinder).controller!;

    await tester.timedDrag(
      tabPagesFinder,
      const Offset(-40, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    expect(pageController.page, 1);
    expect(find.text('Search saved quotes'), findsOneWidget);

    await tester.timedDrag(
      tabPagesFinder,
      const Offset(40, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    expect(pageController.page, 0);
    expect(find.text('Name of the Quote'), findsOneWidget);
  });

  testWidgets('falls back to bundled packages if package loading throws', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          estimatorRepositoryProvider.overrideWithValue(
            _FailingEstimatorRepository(),
          ),
        ],
        child: const MaterialApp(home: EstimatorScreen()),
      ),
    );
    await _pumpEstimator(tester);

    await tester.tap(find.text('Next Step'));
    await _pumpEstimator(tester);

    expect(find.text('5 Packages Available'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('My Quotes tab shows searchable quote cards', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          estimatorRepositoryProvider.overrideWithValue(
            _TestEstimatorRepository(),
          ),
        ],
        child: const MaterialApp(home: EstimatorScreen()),
      ),
    );
    await _pumpEstimator(tester);

    await tester.tap(find.text('MY QUOTES'));
    await _pumpEstimator(tester);

    expect(find.text('Search saved quotes'), findsOneWidget);
    expect(find.text('Dream 2BHK Renovation'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Generate All Packages PDFs'), findsOneWidget);
    expect(find.text('Add Products'), findsOneWidget);

    final quotesList = find.ancestor(
      of: find.text('Dream 2BHK Renovation'),
      matching: find.byType(ListView),
    );
    expect(
      find.descendant(
        of: quotesList,
        matching: find.text('Generate All Packages PDFs'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('saved-quotes-search')),
      'not a saved quote',
    );
    await _pumpEstimator(tester);
    expect(find.text('No quotes match your search.'), findsOneWidget);
  });

  testWidgets('Products tab shows package filters and selectable products', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          estimatorRepositoryProvider.overrideWithValue(
            _TestEstimatorRepository(),
          ),
        ],
        child: const MaterialApp(home: EstimatorScreen()),
      ),
    );
    await _pumpEstimator(tester);

    await tester.tap(find.text('PRODUCTS'));
    await _pumpEstimator(tester);

    expect(find.text('View our products'), findsOneWidget);
    expect(find.text('Search products...'), findsOneWidget);
    expect(find.text('All Packages'), findsOneWidget);
    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('1BHK'), findsNothing);
    expect(find.text('2BHK'), findsNothing);
    expect(find.text('3BHK'), findsNothing);
    expect(find.text('Qty'), findsWidgets);
    expect(find.text('(L × H)'), findsWidgets);
    expect(find.byTooltip('Swap dimensions'), findsWidgets);
    expect(find.text('Wall Mount TV Unit'), findsOneWidget);
    expect(find.text('Add to Quote'), findsWidgets);
    expect(find.text('Add to Cart'), findsWidgets);
    expect(find.text('Total Rate Estimate'), findsOneWidget);

    final productsScroll = find.byKey(
      const ValueKey('estimator-products-scroll'),
    );
    expect(
      find.descendant(
        of: productsScroll,
        matching: find.text('Search products...'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: productsScroll, matching: find.text('All Packages')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: productsScroll, matching: find.text('All Items')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: productsScroll,
        matching: find.text('Total Rate Estimate'),
      ),
      findsNothing,
    );
    expect(find.text('₹0 / sq.ft'), findsOneWidget);
    final verticalScrollable = tester.state<ScrollableState>(
      find
          .descendant(of: productsScroll, matching: find.byType(Scrollable))
          .first,
    );

    await tester.drag(productsScroll, const Offset(0, -100));
    await _pumpEstimator(tester);

    expect(verticalScrollable.position.pixels, greaterThan(0));
    expect(find.text('Total Rate Estimate'), findsOneWidget);

    final dimensionField = find.descendant(
      of: find.byKey(
        const ValueKey('estimator-product-dimensions-basic-tv-unit'),
      ),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(dimensionField);
    await tester.enterText(dimensionField, '9.0 ft × 5.0 ft');
    await _pumpEstimator(tester);
    expect(
      tester.widget<TextField>(dimensionField).controller!.text,
      '9.0 ft × 5.0 ft',
    );

    final dimensionSwap = find.descendant(
      of: find.byKey(
        const ValueKey('estimator-product-dimensions-basic-tv-unit'),
      ),
      matching: find.byTooltip('Swap dimensions'),
    );
    await tester.ensureVisible(dimensionSwap);
    await tester.tap(dimensionSwap);
    await _pumpEstimator(tester);
    expect(find.text('(H × L)'), findsWidgets);
    expect(
      tester.widget<TextField>(dimensionField).controller!.text,
      '5.0 ft × 9.0 ft',
    );

    await tester.ensureVisible(find.text('Add to Quote').first);
    await tester.tap(find.text('Add to Quote').first);
    await _pumpEstimator(tester);
    expect(find.text('₹18,500 / sq.ft'), findsOneWidget);

    await tester.tap(find.text('MY QUOTES'));
    await _pumpEstimator(tester);
    expect(find.text('Wall Mount TV Unit'), findsOneWidget);
    expect(find.text('Selected product'), findsOneWidget);
    expect(find.text('1 product added to My Quotes'), findsOneWidget);
    expect(find.text('1BHK • Basic Package'), findsNothing);
    expect(find.text('₹18,500'), findsOneWidget);

    await tester.tap(find.text('Detailed'));
    await _pumpEstimator(tester);
    expect(find.text('Products in this quote'), findsOneWidget);
    expect(find.text('1BHK • Basic Package • Renovate'), findsNothing);
  });

  testWidgets('Adding an estimator product opens the cart', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = GoRouter(
      initialLocation: '/estimator',
      routes: [
        GoRoute(path: '/estimator', builder: (_, _) => const EstimatorScreen()),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          estimatorRepositoryProvider.overrideWithValue(
            _TestEstimatorRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await _pumpEstimator(tester);

    await tester.tap(find.text('PRODUCTS'));
    await _pumpEstimator(tester);
    await tester.ensureVisible(find.text('Add to Cart').first);
    await tester.tap(find.text('Add to Cart').first);
    await tester.pumpAndSettle();

    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('Wall Mount TV Unit'), findsOneWidget);
    expect(find.text('Buy Now'), findsOneWidget);
  });
}

Future<void> _pumpEstimator(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _TestEstimatorRepository extends EstimatorRepository {
  @override
  Future<List<PackageConfig>> fetchPackages() async =>
      PackageConfig.allPackages;
}

class _FailingEstimatorRepository extends EstimatorRepository {
  @override
  Future<List<PackageConfig>> fetchPackages() async {
    throw StateError('package fetch failed');
  }
}
