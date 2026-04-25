class ActiveSubscriptionEntity {
  final String id;
  final String orderId;
  final String subscriptionId;
  final String subscriptionName;
  final String subscriptionType;
  final String subscriptionCategory;
  final String duration;
  final String providerName;
  final DateTime startedAt;
  final DateTime endsAt;
  final String deliveryMethod;
  final String? deliveryCity;

  const ActiveSubscriptionEntity({
    required this.id,
    required this.orderId,
    required this.subscriptionId,
    required this.subscriptionName,
    required this.subscriptionType,
    required this.subscriptionCategory,
    required this.duration,
    required this.providerName,
    required this.startedAt,
    required this.endsAt,
    required this.deliveryMethod,
    this.deliveryCity,
  });

  String get reference => id.substring(0, 8).toUpperCase();

  int get daysLeft => endsAt.difference(DateTime.now()).inDays.clamp(0, 9999);

  int get totalDays => endsAt.difference(startedAt).inDays.clamp(1, 9999);

  double get progress =>
      ((totalDays - daysLeft) / totalDays).clamp(0.0, 1.0);

  bool get isExpiringSoon => daysLeft <= 3;
}
