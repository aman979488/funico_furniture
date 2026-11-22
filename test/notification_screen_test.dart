import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funica/core/theme/app_colors.dart';
import 'package:funica/features/notifications/views/notification_screen.dart';

void main() {
  testWidgets('NotificationScreen renders with warm theme and visible text', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: NotificationScreen()),
    );
    await tester.pumpAndSettle();

    // Verify AppBar title is present and visible
    final titleFinder = find.text('Notification');
    expect(titleFinder, findsOneWidget);
    final titleWidget = tester.widget<Text>(titleFinder);
    expect(titleWidget.style?.color, equals(AppColors.textPrimary));

    // Verify section titles
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);

    // Verify unread title is present and visible
    final unreadFinder = find.text('35% Special Discount!');
    expect(unreadFinder, findsOneWidget);
    final unreadWidget = tester.widget<Text>(unreadFinder);
    expect(unreadWidget.style?.color, equals(AppColors.textPrimary));

    // Tap on unread notification to mark as read
    await tester.tap(unreadFinder);
    await tester.pumpAndSettle();

    // Scroll to find Earlier section and read notification
    await tester.scrollUntilVisible(find.text('Earlier'), 100);
    expect(find.text('Earlier'), findsOneWidget);

    final readFinder = find.text('Payment Confirmed');
    expect(readFinder, findsOneWidget);
    final readWidget = tester.widget<Text>(readFinder);
    expect(readWidget.style?.color, equals(AppColors.textPrimary));

    // Verify PopupMenu exists and contains options
    final moreButtonFinder = find.byIcon(Icons.more_vert_rounded);
    expect(moreButtonFinder, findsOneWidget);
    await tester.tap(moreButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Mark all as read'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);

    // Tap Clear all
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    // Should now show empty state
    expect(find.text('No Notifications'), findsOneWidget);
  });
}
