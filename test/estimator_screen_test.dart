import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/features/estimator/views/estimator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Estimator screen displays step 1 and transitions to packages step 2',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: EstimatorScreen())),
      );
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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

      // Verify Calculate button
      expect(find.text('Calculate Est. Cost'), findsOneWidget);

      // 6. Tap Calculate Est. Cost
      final calcCostFinder = find.text('Calculate Est. Cost');
      await tester.tap(calcCostFinder);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears
      expect(find.text('TOTAL ESTIMATED COST'), findsOneWidget);
      expect(find.text('Estimated Room-Wise Breakdown'), findsOneWidget);
      expect(find.text('Save Quote'), findsOneWidget);
    },
  );

  testWidgets('My Quotes tab shows searchable quote cards', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: EstimatorScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MY QUOTES'));
    await tester.pumpAndSettle();

    expect(find.text('Search saved quotes'), findsOneWidget);
    expect(find.text('Dream 2BHK Renovation'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Generate All Packages PDFs'), findsOneWidget);
    expect(find.text('Add Products'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('saved-quotes-search')),
      'not a saved quote',
    );
    await tester.pumpAndSettle();
    expect(find.text('No quotes match your search.'), findsOneWidget);
  });

  testWidgets('Products tab shows package filters and selectable products', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: EstimatorScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('PRODUCTS'));
    await tester.pumpAndSettle();

    expect(find.text('View our products'), findsOneWidget);
    expect(find.text('Search products...'), findsOneWidget);
    expect(find.text('All Packages'), findsOneWidget);
    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Mid Century Sofa'), findsOneWidget);
    expect(find.text('Add to Quote'), findsWidgets);
    expect(find.text('Add to Cart'), findsWidgets);
    expect(find.text('Total Sale Estimate'), findsOneWidget);

    await tester.tap(find.text('Add to Quote').first);
    await tester.pumpAndSettle();
    expect(find.text('₹280'), findsWidgets);
  });
}
