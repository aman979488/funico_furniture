import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/features/home/views/home_screen.dart';
import 'package:funica/features/help/views/help_center_screen.dart';

void main() {
  testWidgets('HomeScreen renders with top bar and hero banner above special offers', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify Brand Top Bar
    expect(find.text('Future Interior'), findsOneWidget);
    expect(find.text('INTERIOR SOLUTIONS'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);

    // Verify Hero Banner above Special Offers
    expect(find.text('Design Your\nDream Space'), findsOneWidget);
    expect(find.text('Modern | Functional | Timeless'), findsOneWidget);
    expect(find.text('Explore Designs'), findsOneWidget);

    // Verify Tier Collection Bar above Special Offers
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Deluxe'), findsOneWidget);
    expect(find.text('Modern'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Luxury'), findsOneWidget);

    // Verify Special Offers is present
    expect(find.text('Special Offers'), findsOneWidget);

    // Verify relative vertical position: Hero banner < Tier bar < Special Offers
    final heroLocation = tester.getTopLeft(find.text('Design Your\nDream Space'));
    final tierLocation = tester.getTopLeft(find.text('Basic'));
    final specialOffersLocation = tester.getTopLeft(find.text('Special Offers'));
    expect(heroLocation.dy, lessThan(tierLocation.dy));
    expect(tierLocation.dy, lessThan(specialOffersLocation.dy));

    // Tap Deluxe tier button
    await tester.tap(find.text('Deluxe'));
    await tester.pumpAndSettle();
    expect(find.text('Deluxe'), findsOneWidget);
  });

  testWidgets('HelpCenterScreen renders with warm theme', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HelpCenterScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Contact Us'), findsOneWidget);
    expect(find.text('Search FAQ...'), findsOneWidget);

    // Tap on Contact Us tab
    await tester.tap(find.text('Contact Us'));
    await tester.pumpAndSettle();

    expect(find.text('Customer Service'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });
}
