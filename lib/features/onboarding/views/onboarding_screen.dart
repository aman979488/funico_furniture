import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  Timer? _autoTimer;

  static const int _lastIndex = 3;

  static const _slides = [
    _SlideData(AppAssets.onboarding1, AppStrings.onboardingTitle1),
    _SlideData(AppAssets.onboarding2, AppStrings.onboardingTitle2),
    _SlideData(AppAssets.onboarding3, AppStrings.onboardingTitle3),
  ];

  @override
  void initState() {
    super.initState();
    // Welcome page 3 sec baad khud aage badhega (agar user ne swipe nahi kiya)
    _autoTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_controller.hasClients) return;
      if ((_controller.page ?? 0) == 0) _goToNextPage();
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    final current = _controller.page?.round() ?? 0;

    if (current >= _lastIndex) {
      await ref.read(onboardingViewModelProvider).completeOnboarding();
      if (!mounted) return;
      context.go('/lets-you-in');
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _controller,
        children: [
          const _WelcomePage(),
          for (final slide in _slides)
            _SlidePage(data: slide, onNext: _goToNextPage),
        ],
      ),
    );
  }
}

class _SlideData {
  const _SlideData(this.image, this.title);
  final String image;
  final String title;
}

/// Photo load karta hai, na mile toh grey fallback dikhata hai
class _Photo extends StatelessWidget {
  const _Photo(this.path);
  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => Container(color: AppColors.card),
    );
  }
}

/// Page 1: full screen photo + neeche left mein Welcome text
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _Photo(AppAssets.welcomeBg),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.4, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.welcomeTo,
                  style: GoogleFonts.urbanist(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.urbanist(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.welcomeSubtitle,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Page 2, 3, 4: upar photo (neeche fade), beech mein title, neeche Next button
class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.data, required this.onNext});

  final _SlideData data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Photo(data.image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.background],
                    stops: [0.6, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(text: AppStrings.next, onPressed: onNext),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
