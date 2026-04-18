class ProviderEntity {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String city;
  final int subscriptionCount;

  const ProviderEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.city,
    this.subscriptionCount = 0,
  });
}
