import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  const HomeState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  HomeState copyWith({bool? isLoading, String? error}) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();
}

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
