import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        type: NotificationType.fromString(type),
        title: title,
        message: message,
        isRead: isRead,
        readAt: readAt != null ? DateTime.tryParse(readAt!) : null,
        createdAt: DateTime.parse(createdAt),
        data: data,
      );
}
