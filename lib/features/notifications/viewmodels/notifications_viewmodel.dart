import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsState {
  const NotificationsState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  NotificationsState copyWith({bool? isLoading, String? error}) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsViewModel extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();
}

final notificationsViewModelProvider =
    NotifierProvider<NotificationsViewModel, NotificationsState>(NotificationsViewModel.new);
