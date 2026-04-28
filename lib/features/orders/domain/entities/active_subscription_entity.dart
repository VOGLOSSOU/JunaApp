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

  // Comparaison par jours calendaires (minuit → minuit) pour éviter
  // que 23h restantes affiche "0 jours"
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endsAt.year, endsAt.month, endsAt.day);
    return end.difference(today).inDays.clamp(0, 9999);
  }

  int get totalDays {
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    final end = DateTime(endsAt.year, endsAt.month, endsAt.day);
    return end.difference(start).inDays.clamp(1, 9999);
  }

  double get progress =>
      ((totalDays - daysLeft) / totalDays).clamp(0.0, 1.0);

  bool get isExpiringSoon => daysLeft <= 3;
}
