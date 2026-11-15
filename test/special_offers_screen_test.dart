import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/features/home/views/special_offers_screen.dart';

void main() {
  testWidgets('shows all special offers in a scrollable list', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SpecialOffersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Special Offers'), findsOneWidget);
    expect(find.text('25% OFF'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('40% OFF'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('40% OFF'), findsOneWidget);
  });
}
