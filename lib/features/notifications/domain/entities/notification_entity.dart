enum NotificationType { order, promo, system, review, delivery }

class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}
