import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/features/product/views/product_detail_screen.dart';
import 'package:funica/shared/models/product.dart';

void main() {
  testWidgets('sofa details show scrollable sofa options below', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(product: Product.sampleProducts.first),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sofa options'));
    await tester.pumpAndSettle();

    expect(find.text('Sofa options'), findsOneWidget);
    expect(find.text('2 Seater Sofa'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('sofa-options-list')),
      const Offset(-1000, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loveseat Sofa'), findsOneWidget);
  });
}
