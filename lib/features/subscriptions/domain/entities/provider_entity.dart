import 'meal_entity.dart';
import 'subscription_entity.dart';

class ProviderEntity {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String logo;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool acceptsDelivery;
  final bool acceptsPickup;
  final String businessAddress;
  final ProviderCity city;
  final DateTime? memberSince;
  final List<String> deliveryZones;
  final List<ProviderPickupPoint> pickupPoints;
  final List<SubscriptionEntity> subscriptions;
  final List<MealEntity> meals;

  const ProviderEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarUrl,
    required this.logo,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.acceptsDelivery,
    required this.acceptsPickup,
    required this.businessAddress,
    required this.city,
    this.memberSince,
    this.deliveryZones = const [],
    this.pickupPoints = const [],
    this.subscriptions = const [],
    this.meals = const [],
  });
}

class ProviderCity {
  final String id;
  final String name;

  const ProviderCity({
    required this.id,
    required this.name,
  });
}

class ProviderPickupPoint {
  final String id;
  final String name;

  const ProviderPickupPoint({
    required this.id,
    required this.name,
  });
}
