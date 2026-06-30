import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/utils/enums.dart';
import '../../../subscriptions/data/repositories/subscription_repository.dart';
import '../../../subscriptions/domain/entities/meal_entity.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return ProviderRepository(dio: ref.read(dioProvider));
});

class ProviderRepository {
  final Dio _dio;

  ProviderRepository({required Dio dio}) : _dio = dio;

  Future<ProviderEntity> getProviderById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.providerById(id));
      final json = response.data['data'] as Map<String, dynamic>;
      return _mapProvider(json);
    } on DioException catch (e) {
      throw extractException(e);
    } catch (e) {
      throw Exception('Erreur de parsing: $e');
    }
  }

  static String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v;
    if (v is Map) {
      return (v['name'] ?? v['label'] ?? v['id'] ?? fallback).toString();
    }
    return v.toString();
  }

  static ProviderEntity _mapProvider(Map<String, dynamic> json) {
    final cityRaw = json['city'];
    final cityMap =
        cityRaw is Map ? Map<String, dynamic>.from(cityRaw) : <String, dynamic>{};
    final city = ProviderCity(
      id: _str(cityMap['id']),
      name: _str(cityMap['name'] ?? cityRaw),
    );

    final deliveryZones = (json['deliveryZones'] as List?)
            ?.map((e) => _str(e))
            .where((z) => z.isNotEmpty)
            .toList() ??
        [];

    final pickupPoints = (json['pickupPoints'] as List?)
            ?.map((e) {
              final p = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
              return ProviderPickupPoint(
                id: _str(p['id']),
                name: _str(p['name'] ?? e),
              );
            })
            .where((p) => p.name.isNotEmpty)
            .toList() ??
        [];

    // Provider "léger" : injecté dans chaque abonnement/plat enfant pour
    // réutiliser le parsing déjà robuste de SubscriptionRepository.mapSubscription.
    final providerStub = ProviderEntity(
      id: _str(json['id']),
      name: _str(json['businessName'] ?? json['name']),
      description: _str(json['description']),
      avatarUrl: _str(json['logo']),
      logo: _str(json['logo']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      acceptsDelivery: json['acceptsDelivery'] as bool? ?? false,
      acceptsPickup: json['acceptsPickup'] as bool? ?? false,
      businessAddress: _str(json['businessAddress']),
      city: city,
    );

    final subscriptions = (json['subscriptions'] as List? ?? []).map((s) {
      final subJson = Map<String, dynamic>.from(s as Map<String, dynamic>);
      subJson['provider'] = json;
      return SubscriptionRepository.mapSubscription(subJson);
    }).toList();

    final meals = (json['meals'] as List? ?? [])
        .map((m) => _mapMeal(m as Map<String, dynamic>, providerStub))
        .toList();

    return ProviderEntity(
      id: providerStub.id,
      name: providerStub.name,
      description: providerStub.description,
      avatarUrl: providerStub.avatarUrl,
      logo: providerStub.logo,
      rating: providerStub.rating,
      reviewCount: providerStub.reviewCount,
      isVerified: providerStub.isVerified,
      acceptsDelivery: providerStub.acceptsDelivery,
      acceptsPickup: providerStub.acceptsPickup,
      businessAddress: providerStub.businessAddress,
      city: city,
      memberSince: DateTime.tryParse(_str(json['memberSince'])),
      deliveryZones: deliveryZones,
      pickupPoints: pickupPoints,
      subscriptions: subscriptions,
      meals: meals,
    );
  }

  static MealEntity _mapMeal(Map<String, dynamic> json, ProviderEntity provider) {
    final priceTypeStr = json['priceType'] as String?;
    final priceType = priceTypeStr == 'MULTIPLE'
        ? MealPriceType.multiple
        : priceTypeStr == 'RANGE'
            ? MealPriceType.range
            : MealPriceType.fixed;

    return MealEntity(
      id: _str(json['id']),
      name: _str(json['name']),
      description: _str(json['description']),
      imageUrl: _str(json['imageUrl']),
      mealType: _parseMealType(_str(json['mealType'], 'LUNCH')),
      priceType: priceType,
      price: (json['price'] as num?)?.toInt() ?? 0,
      priceMin: (json['priceMin'] as num?)?.toInt(),
      priceMax: (json['priceMax'] as num?)?.toInt(),
      priceGuideline: json['priceGuideline'] as String?,
      pricings: ((json['pricings'] as List?) ?? []).map((p) {
        final pricing = p as Map<String, dynamic>;
        return MealPricing(
          id: pricing['id'] as String? ?? '',
          label: pricing['label'] as String? ?? '',
          price: (pricing['price'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      provider: provider,
    );
  }

  static SubscriptionType _parseMealType(String type) {
    switch (type.toUpperCase()) {
      case 'BREAKFAST':
        return SubscriptionType.breakfast;
      case 'DINNER':
        return SubscriptionType.dinner;
      case 'SNACK':
        return SubscriptionType.snack;
      case 'LUNCH':
      default:
        return SubscriptionType.lunch;
    }
  }
}
