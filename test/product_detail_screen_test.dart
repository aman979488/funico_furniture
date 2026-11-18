import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/features/product/views/product_detail_screen.dart';
import 'package:funica/shared/models/product.dart';

void main() {
  testWidgets('selecting a color updates the selected swatch', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(product: Product.sampleProducts.first),
      ),
    );
    await tester.pumpAndSettle();

    final firstSwatch = find.byKey(const ValueKey('color-swatch-0'));
    final secondSwatch = find.byKey(const ValueKey('color-swatch-1'));
    await tester.ensureVisible(firstSwatch);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: firstSwatch, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: secondSwatch, matching: find.byIcon(Icons.check)),
      findsNothing,
    );

    await tester.tap(secondSwatch);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: firstSwatch, matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(
      find.descendant(of: secondSwatch, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
  });

  testWidgets('sofa details show scrollable sofa options below', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(product: Product.sampleProducts.first),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available colors'), findsNothing);
    await tester.ensureVisible(find.text('Sofa options'));
    await tester.pumpAndSettle();

    expect(find.text('Sofa options'), findsOneWidget);
    expect(find.text('2 Seater Sofa'), findsOneWidget);
    expect(
      tester
          .widget<GridView>(find.byKey(const ValueKey('sofa-options-list')))
          .gridDelegate,
      isA<SliverGridDelegateWithFixedCrossAxisCount>().having(
        (delegate) => delegate.crossAxisCount,
        'crossAxisCount',
        2,
      ),
    );
    expect(find.text('3 Seater Sofa'), findsOneWidget);
    expect(find.text('Loveseat Sofa'), findsOneWidget);
  });
}
