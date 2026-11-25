import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:funica/core/theme/app_colors.dart';
import 'package:funica/core/theme/app_theme.dart';
import 'package:funica/features/profile/views/address_list_screen.dart';
import 'package:funica/features/profile/views/edit_profile_screen.dart';
import 'package:funica/features/profile/views/invite_friends_screen.dart';
import 'package:funica/features/profile/views/language_screen.dart';
import 'package:funica/features/profile/views/notification_settings_screen.dart';
import 'package:funica/features/profile/views/payment_settings_screen.dart';
import 'package:funica/features/profile/views/privacy_policy_screen.dart';
import 'package:funica/features/profile/views/profile_screen.dart';
import 'package:funica/features/profile/views/security_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  testWidgets('ProfileScreen renders with warm background and menu tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const ProfileScreen()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.background);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets(
    'EditProfileScreen renders with visible title and update button',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const EditProfileScreen()));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.background);

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    },
  );

  testWidgets('SecurityScreen renders action buttons and switches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const SecurityScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
  });

  testWidgets('LanguageScreen renders language options', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const LanguageScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsAtLeastNWidgets(1));
    expect(find.text('English (US)'), findsOneWidget);
  });

  testWidgets('NotificationSettingsScreen renders switches', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestWidget(const NotificationSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification'), findsOneWidget);
    expect(find.text('General Notification'), findsOneWidget);
  });

  testWidgets('PaymentSettingsScreen renders with payment options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const PaymentSettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Add New Card'), findsOneWidget);
  });

  testWidgets('AddressListScreen renders address UI and Add button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const AddressListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Add New Address'), findsOneWidget);
  });

  testWidgets('InviteFriendsScreen renders contacts with Invite buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const InviteFriendsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Invite Friends'), findsOneWidget);
    expect(find.text('Invite Friends & Get ₹20 OFF'), findsOneWidget);
  });

  testWidgets('PrivacyPolicyScreen renders headers and policy text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget(const PrivacyPolicyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('1. Types of Data We Collect'), findsOneWidget);
  });
}
