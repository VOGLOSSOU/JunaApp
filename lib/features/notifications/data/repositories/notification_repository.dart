import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(dio: ref.read(dioProvider));
});

typedef NotificationsPage = ({
  List<NotificationEntity> notifications,
  int unreadCount,
  bool hasMore,
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository({required Dio dio}) : _dio = dio;

  Future<NotificationsPage> getNotifications({
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = response.data['data'] as Map<String, dynamic>;
      final list = (body['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      final unreadCount = body['unreadCount'] as int? ?? 0;
      final hasMore = list.length >= limit;
      return (notifications: list, unreadCount: unreadCount, hasMore: hasMore);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch(ApiEndpoints.markNotificationRead(id));
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch(ApiEndpoints.markAllNotificationsRead);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete(ApiEndpoints.deleteNotification(id));
    } on DioException catch (e) {
      throw extractException(e);
    }
  }
}
