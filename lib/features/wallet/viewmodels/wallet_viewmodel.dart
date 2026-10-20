import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletState {
  const WalletState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  WalletState copyWith({bool? isLoading, String? error}) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletViewModel extends Notifier<WalletState> {
  @override
  WalletState build() => const WalletState();
}

final walletViewModelProvider =
    NotifierProvider<WalletViewModel, WalletState>(WalletViewModel.new);
