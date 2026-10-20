import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  const OnboardingState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  OnboardingState copyWith({bool? isLoading, String? error}) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(OnboardingViewModel.new);
