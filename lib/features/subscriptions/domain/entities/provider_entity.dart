import '../../../../core/utils/enums.dart';

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
