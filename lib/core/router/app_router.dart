import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/fill_profile_screen.dart';
import '../../features/auth/views/create_pin_screen.dart';
import '../../features/auth/views/enter_pin_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/lets_you_in_screen.dart';
import '../../features/auth/views/signup_screen.dart';
import '../../features/help/views/help_center_screen.dart';
import '../../features/estimator/views/estimator_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/home/views/main_shell_screen.dart';
import '../../features/home/views/special_offers_screen.dart';
import '../../features/notifications/views/notification_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/onboarding/views/splash_screen.dart';
import '../../features/cart/views/cart_screen.dart';
import '../../features/orders/views/my_orders_screen.dart';
import '../../features/product/views/category_list_screen.dart';
import '../../features/product/views/product_detail_screen.dart';
import '../../features/profile/views/add_address_screen.dart';
import '../../features/profile/views/add_card_screen.dart';
import '../../features/profile/views/address_list_screen.dart';
import '../../features/profile/views/edit_profile_screen.dart';
import '../../features/profile/views/invite_friends_screen.dart';
import '../../features/profile/views/language_screen.dart';
import '../../features/profile/views/notification_settings_screen.dart';
import '../../features/profile/views/payment_settings_screen.dart';
import '../../features/profile/views/privacy_policy_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/security_screen.dart';
import '../../features/search/views/search_screen.dart';
import '../../features/wishlist/views/wishlist_screen.dart';
import '../../shared/models/address.dart';
import '../../shared/models/product.dart';
import '../services/pin_session.dart';

/// Saare route paths ek jagah. Navigate karne ke liye:
/// context.go(AppRoutes.login);   (replace)
/// context.push(AppRoutes.signup); (upar stack karna)
///
///
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const letsYouIn = '/lets-you-in';
  static const signup = '/signup';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const fillProfile = '/fill-profile';
  static const createPin = '/create-pin';
  static const enterPin = '/enter-pin';
  static const home = '/home';
  static const estimator = '/estimator';
  static const search = '/search';
  static const categoryProducts = '/category-products';
  static const productDetails = '/product-details';
  static const specialOffers = '/special-offers';
  static const wishlist = '/wishlist';
  static const cart = '/cart';
  static const orders = '/orders';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const address = '/address';
  static const addAddress = '/add-address';
  static const notificationSettings = '/notification-settings';
  static const paymentSettings = '/payment-settings';
  static const addCard = '/add-card';
  static const security = '/security';
  static const language = '/language';
  static const privacyPolicy = '/privacy-policy';
  static const helpCenter = '/help-center';
  static const inviteFriends = '/invite-friends';
  static const notifications = '/notifications';
}


final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: PinSession.refreshListenable,
  redirect: (context, state) async {
    final isSignedIn =
        Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
    final user = isSignedIn ? FirebaseAuth.instance.currentUser : null;
    final authRoutes = {
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.letsYouIn,
      AppRoutes.signup,
      AppRoutes.login,
      AppRoutes.forgotPassword,
    };

    final setupRoutes = {AppRoutes.fillProfile};

    if (isSignedIn && user != null) {
      // 1. Agar user Enter PIN screen par hai, wahi rehne do
      if (state.matchedLocation == AppRoutes.enterPin) return null;

      if (state.matchedLocation == AppRoutes.createPin) {
        return state.extra == true ? null : AppRoutes.enterPin;
      }

      if (state.matchedLocation == AppRoutes.fillProfile &&
          state.extra is! Map<String, String>) {
        return AppRoutes.enterPin;
      }

      // 2. Agar new user signup ke steps complete kar raha hai, uninterrupted aage badhne do
      if (setupRoutes.contains(state.matchedLocation)) return null;

      // 3. Har locked session ko PIN verification se guzarna hoga.
      if (!PinSession.isUnlockedFor(user.uid)) {
        return AppRoutes.enterPin;
      }

      // 4. Session unlocked hai aur user login/signup par wapas ja raha hai, toh Home bhejo
      if (authRoutes.contains(state.matchedLocation)) {
        return AppRoutes.home;
      }

      return null;
    }

    if (!isSignedIn) {
      if ({
            AppRoutes.home,
            AppRoutes.search,
            AppRoutes.categoryProducts,
            AppRoutes.productDetails,
            AppRoutes.specialOffers,
            AppRoutes.wishlist,
            AppRoutes.cart,
            AppRoutes.orders,
            AppRoutes.profile,
          }.contains(state.matchedLocation) ||
          state.matchedLocation == AppRoutes.enterPin ||
          state.matchedLocation == AppRoutes.createPin ||
          setupRoutes.contains(state.matchedLocation)) {
        return AppRoutes.letsYouIn;
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.letsYouIn,
      builder: (context, state) => const LetsYouInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.fillProfile,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, String>) {
          return FillProfileScreen(name: extra['name'], email: extra['email']);
        }
        return FillProfileScreen(email: extra is String ? extra : null);
      },
    ),
    GoRoute(
      path: AppRoutes.createPin,
      builder: (context, state) => const CreatePinScreen(),
    ),
    GoRoute(
      path: AppRoutes.enterPin,
      builder: (context, state) => const EnterPinScreen(),
    ),
    GoRoute(
      path: AppRoutes.specialOffers,
      builder: (context, state) => const SpecialOffersScreen(),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.categoryProducts,
      builder: (context, state) {
        final category = state.extra;
        return CategoryListScreen(
          category: category is String ? category : 'All',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.productDetails,
      builder: (context, state) {
        final product = state.extra;
        if (product is Product) {
          return ProductDetailScreen(product: product);
        }
        return const Scaffold(
          body: Center(child: Text('Product details are unavailable.')),
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) =>
          MainShellScreen(currentLocation: state.matchedLocation, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.estimator,
          builder: (context, state) => const EstimatorScreen(),
        ),
        GoRoute(
          path: AppRoutes.wishlist,
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(
          path: AppRoutes.cart,
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (context, state) => const MyOrdersScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.address,
      builder: (context, state) => const AddressListScreen(),
    ),
    GoRoute(
      path: AppRoutes.addAddress,
      builder: (context, state) =>
          AddAddressScreen(existingAddress: state.extra as Address?),
    ),
    GoRoute(
      path: AppRoutes.notificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentSettings,
      builder: (context, state) => const PaymentSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.addCard,
      builder: (context, state) => const AddCardScreen(),
    ),
    GoRoute(
      path: AppRoutes.security,
      builder: (context, state) => const SecurityScreen(),
    ),
    GoRoute(
      path: AppRoutes.language,
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: AppRoutes.privacyPolicy,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: AppRoutes.helpCenter,
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: AppRoutes.inviteFriends,
      builder: (context, state) => const InviteFriendsScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationScreen(),
    ),
  ],
);
