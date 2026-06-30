import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/utils/enums.dart';
import '../../../subscriptions/domain/entities/meal_entity.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(dio: ref.read(dioProvider));
});

class MealRepository {
  final Dio _dio;

  MealRepository({required Dio dio}) : _dio = dio;

  Future<MealEntity> getMealById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.mealById(id));
      final data = response.data['data'];
      final json = (data is Map && data.containsKey('meal'))
          ? data['meal'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return _mapMeal(json);
    } on DioException catch (e) {
      throw extractException(e);
    } catch (e) {
      throw Exception('Erreur de parsing: $e');
    }
  }

  Future<List<MealEntity>> getOtherMealsByProvider(
    String providerId, {
    required String excludeMealId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.meals,
        queryParameters: {'providerId': providerId, 'limit': 10},
      );
      final data = response.data['data'];
      final list = (data is Map ? data['meals'] : data) as List? ?? [];
      return list
          .map((e) => _mapMeal(e as Map<String, dynamic>))
          .where((m) => m.id != excludeMealId)
          .toList();
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

  static MealEntity _mapMeal(Map<String, dynamic> json) {
    final priceTypeStr = json['priceType'] as String?;
    final priceType = priceTypeStr == 'MULTIPLE'
        ? MealPriceType.multiple
        : priceTypeStr == 'RANGE'
            ? MealPriceType.range
            : MealPriceType.fixed;

    final providerRaw = json['provider'];
    final providerJson = providerRaw is Map
        ? Map<String, dynamic>.from(providerRaw)
        : <String, dynamic>{};

    final provider = providerJson.isEmpty
        ? null
        : ProviderEntity(
            id: _str(providerJson['id']),
            name: _str(providerJson['businessName'] ?? providerJson['name']),
            description: '',
            avatarUrl: _str(providerJson['logo']),
            logo: _str(providerJson['logo']),
            rating: (providerJson['rating'] as num?)?.toDouble() ?? 0.0,
            reviewCount: 0,
            isVerified: providerJson['isVerified'] as bool? ?? false,
            acceptsDelivery: false,
            acceptsPickup: false,
            businessAddress: '',
            city: const ProviderCity(id: '', name: ''),
          );

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
