import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartState {
  const CartState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  CartState copyWith({bool? isLoading, String? error}) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CartViewModel extends Notifier<CartState> {
  @override
  CartState build() => const CartState();
}

final cartViewModelProvider =
    NotifierProvider<CartViewModel, CartState>(CartViewModel.new);
