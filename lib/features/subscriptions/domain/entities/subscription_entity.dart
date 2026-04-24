import '../../../../core/utils/enums.dart';
import 'provider_entity.dart';
import 'meal_entity.dart';

class SubscriptionEntity {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> images;
  final String currency;
  final int mealCount;
  final ProviderEntity provider;
  final double price;
  final SubscriptionType type;
  final SubscriptionDuration duration;
  final List<SubscriptionCategory> categories;
  final double rating;
  final int reviewCount;
  final List<MealEntity> meals;
  final List<String> deliveryZones;
  final List<String> pickupPoints;
  final bool isAvailable;
  final List<SubscriptionEntity> providerSubscriptions;

  const SubscriptionEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.images = const [],
    this.currency = 'XOF',
    this.mealCount = 0,
    required this.provider,
    required this.price,
    required this.type,
    required this.duration,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    required this.meals,
    required this.deliveryZones,
    required this.pickupPoints,
    required this.isAvailable,
    this.providerSubscriptions = const [],
  });
}
