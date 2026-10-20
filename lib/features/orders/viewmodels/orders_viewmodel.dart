import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdersState {
  const OrdersState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  OrdersState copyWith({bool? isLoading, String? error}) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrdersViewModel extends Notifier<OrdersState> {
  @override
  OrdersState build() => const OrdersState();
}

final ordersViewModelProvider =
    NotifierProvider<OrdersViewModel, OrdersState>(OrdersViewModel.new);
