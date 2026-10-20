import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutState {
  const CheckoutState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  CheckoutState copyWith({bool? isLoading, String? error}) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CheckoutViewModel extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();
}

final checkoutViewModelProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);
