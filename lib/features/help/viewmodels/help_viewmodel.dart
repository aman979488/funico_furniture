import 'package:flutter_riverpod/flutter_riverpod.dart';

class HelpState {
  const HelpState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  HelpState copyWith({bool? isLoading, String? error}) {
    return HelpState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HelpViewModel extends Notifier<HelpState> {
  @override
  HelpState build() => const HelpState();
}

final helpViewModelProvider =
    NotifierProvider<HelpViewModel, HelpState>(HelpViewModel.new);
