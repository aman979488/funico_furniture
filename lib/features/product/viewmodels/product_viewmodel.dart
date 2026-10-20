import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductState {
  const ProductState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  ProductState copyWith({bool? isLoading, String? error}) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProductViewModel extends Notifier<ProductState> {
  @override
  ProductState build() => const ProductState();
}

final productViewModelProvider =
    NotifierProvider<ProductViewModel, ProductState>(ProductViewModel.new);
