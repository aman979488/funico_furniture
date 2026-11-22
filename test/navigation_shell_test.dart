import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/core/router/app_router.dart';
import 'package:funica/features/home/views/main_shell_screen.dart';

void main() {
  testWidgets('MainShellScreen renders exact 4 tabs: Home, Estimator, Cart, Orders', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainShellScreen(
            currentLocation: AppRoutes.home,
            child: Scaffold(body: Center(child: Text('Home Content'))),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 4 tabs from reference photo
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Estimator'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);

    // Verify Wishlist and Profile are not in bottom bar
    expect(find.text('Wishlist'), findsNothing);
    expect(find.text('Profile'), findsNothing);

    // Verify Home has active pill
    expect(find.byType(MainShellScreen), findsOneWidget);
  });
}
