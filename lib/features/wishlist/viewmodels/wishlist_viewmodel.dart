import 'package:flutter_riverpod/flutter_riverpod.dart';

class WishlistState {
  const WishlistState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  WishlistState copyWith({bool? isLoading, String? error}) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WishlistViewModel extends Notifier<WishlistState> {
  @override
  WishlistState build() => const WishlistState();
}

final wishlistViewModelProvider =
    NotifierProvider<WishlistViewModel, WishlistState>(WishlistViewModel.new);
