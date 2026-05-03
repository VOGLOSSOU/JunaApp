enum NotificationType {
  system,
  orderConfirmation,
  proposalValidated,
  proposalRejected,
  unknown;

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'SYSTEM':             return NotificationType.system;
      case 'ORDER_CONFIRMATION': return NotificationType.orderConfirmation;
      case 'PROPOSAL_VALIDATED': return NotificationType.proposalValidated;
      case 'PROPOSAL_REJECTED':  return NotificationType.proposalRejected;
      default:                   return NotificationType.unknown;
    }
  }
}

class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  NotificationEntity copyWith({bool? isRead, DateTime? readAt}) =>
      NotificationEntity(
        id: id,
        type: type,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
        data: data,
      );
}
