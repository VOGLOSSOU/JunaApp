enum MealPriceType { fixed, multiple, range }

class MealPricing {
  final String id;
  final String label;
  final int price;

  const MealPricing({
    required this.id,
    required this.label,
    required this.price,
  });
}

class MealEntity {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final MealPriceType priceType;
  final int price;
  final int? priceMin;
  final int? priceMax;
  final String? priceGuideline;
  final List<MealPricing> pricings;

  const MealEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.priceType = MealPriceType.fixed,
    this.price = 0,
    this.priceMin,
    this.priceMax,
    this.priceGuideline,
    this.pricings = const [],
  });
}
