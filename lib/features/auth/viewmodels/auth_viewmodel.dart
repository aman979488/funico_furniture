import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
