import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  const ProfileState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  ProfileState copyWith({bool? isLoading, String? error}) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
