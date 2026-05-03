import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  final NotificationRepository _repository;

  NotificationsController(this._repository) : super(const NotificationsState()) {
    load();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getNotifications(page: 1);
      state = state.copyWith(
        isLoading: false,
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        hasMore: result.hasMore,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repository.getNotifications(page: nextPage);
      state = state.copyWith(
        isLoadingMore: false,
        notifications: [...state.notifications, ...result.notifications],
        unreadCount: result.unreadCount,
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id != id || n.isRead) return n;
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }).toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, 9999),
    );
    try {
      await _repository.markAsRead(id);
    } catch (_) {
      await load();
    }
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.isRead ? n : n.copyWith(isRead: true, readAt: now))
          .toList(),
      unreadCount: 0,
    );
    try {
      await _repository.markAllAsRead();
    } catch (_) {
      await load();
    }
  }

  Future<void> delete(String id) async {
    final wasUnread =
        state.notifications.any((n) => n.id == id && !n.isRead);
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
      unreadCount: wasUnread
          ? (state.unreadCount - 1).clamp(0, 9999)
          : state.unreadCount,
    );
    try {
      await _repository.deleteNotification(id);
    } catch (_) {
      await load();
    }
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref.read(notificationRepositoryProvider));
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsControllerProvider).unreadCount;
});
