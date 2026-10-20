import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchState {
  const SearchState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  SearchState copyWith({bool? isLoading, String? error}) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchViewModel extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();
}

final searchViewModelProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);
