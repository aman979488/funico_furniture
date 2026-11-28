import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order.dart';
import '../repositories/orders_repository.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AppOrder> orders;
  final bool isLoading;
  final String? error;

  OrdersState copyWith({
    List<AppOrder>? orders,
    bool? isLoading,
    String? error,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrdersViewModel extends Notifier<OrdersState> {
  late final OrdersRepository _repository;

  @override
  OrdersState build() {
    _repository = ref.watch(ordersRepositoryProvider);
    return OrdersState(orders: _repository.getOrders());
  }

  void addOrder(AppOrder order) {
    _repository.addOrder(order);
    state = state.copyWith(orders: _repository.getOrders());
  }
}

final ordersViewModelProvider = NotifierProvider<OrdersViewModel, OrdersState>(
  OrdersViewModel.new,
);
