import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/provider_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../../../core/utils/enums.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(dio: ref.read(dioProvider));
});

class SubscriptionRepository {
  final Dio _dio;

  SubscriptionRepository({required Dio dio}) : _dio = dio;

  Future<({List<SubscriptionEntity> items, int total, int totalPages})>
      getSubscriptions({
    int page = 1,
    int limit = 20,
    String? cityId,
    String? landmarkId,
    String? category,
    String? type,
    String? duration,
    String sort = 'popular',
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.subscriptions,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': sort,
          if (cityId != null) 'cityId': cityId,
          if (landmarkId != null) 'landmarkId': landmarkId,
          if (category != null) 'category': category,
          if (type != null) 'type': type,
          if (duration != null) 'duration': duration,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = response.data['data'];
      final items = (data['subscriptions'] as List)
          .map((e) => mapSubscription(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      return (
        items: items,
        total: pagination['total'] as int,
        totalPages: pagination['totalPages'] as int,
      );
    } on DioException catch (e) {
      throw extractException(e);
    } catch (e) {
      throw Exception('Erreur de parsing: $e');
    }
  }

  Future<SubscriptionEntity> getSubscriptionById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.subscriptionById(id));
      final data = response.data['data'];
      final json = (data is Map && data.containsKey('subscription'))
          ? data['subscription'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return mapSubscription(json);
    } on DioException catch (e) {
      throw extractException(e);
    } catch (e) {
      throw Exception('Erreur de parsing: $e');
    }
  }

  Future<List<ReviewEntity>> getReviews(String subscriptionId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.reviewsBySubscription(subscriptionId),
      );
      final data = response.data['data'];
      final list = data is Map
          ? (data['reviews'] as List? ?? [])
          : (data as List? ?? []);
      return list.map((e) => _mapReview(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // Extrait une String d'un champ qui peut être une String ou un objet {id, name}
  static String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v;
    if (v is Map)
      return (v['name'] ?? v['label'] ?? v['id'] ?? fallback).toString();
    return v.toString();
  }

  // Parse une zone de livraison : { city, country, cost } → "Cotonou · 500 FCFA"
  static String _strZone(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    if (v is Map) {
      final city = (v['city'] ?? v['name'] ?? v['label'] ?? v['zone'] ??
              v['zoneName'] ?? v['address'] ?? v['title'] ?? v['id'])
          ?.toString()
          .trim();
      if (city == null || city.isEmpty) {
        for (final val in v.values) {
          if (val is String && val.trim().isNotEmpty) return val.trim();
        }
        return '';
      }
      final cost = v['cost'] ?? v['price'] ?? v['deliveryCost'];
      if (cost != null) return '$city · $cost FCFA';
      return city;
    }
    return v.toString().trim();
  }

  static SubscriptionEntity mapSubscription(Map<String, dynamic> json) {
    final providerRaw = json['provider'];
    final providerJson = (providerRaw is Map)
        ? Map<String, dynamic>.from(providerRaw as Map)
        : <String, dynamic>{};

    final imgs = (json['images'] as List?)
            ?.map((e) => e is String ? e : _str(e))
            .toList() ??
        [];

    final meals = (json['meals'] as List? ?? []).map((m) {
      final meal = m as Map<String, dynamic>;
      return MealEntity(
        id: _str(meal['id']),
        name: _str(meal['name']),
        description: _str(meal['description']),
        imageUrl: _str(meal['imageUrl']),
      );
    }).toList();

    final deliveryZones = (json['deliveryZones'] as List?)
            ?.map((e) => _strZone(e))
            .where((z) => z.isNotEmpty)
            .toList() ??
        [];
    final pickupPoints = (json['pickupPoints'] as List?)
            ?.map((e) => _strZone(e))
            .where((z) => z.isNotEmpty)
            .toList() ??
        [];

    final categoryRaw = json['category'];
    final categoryStr = categoryRaw is List
        ? _str(categoryRaw.isNotEmpty ? categoryRaw[0] : 'AFRICAN')
        : _str(categoryRaw, 'AFRICAN');

    return SubscriptionEntity(
      id: _str(json['id']),
      title: _str(json['name']),
      description: _str(json['description']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: _str(json['currency'], 'XOF'),
      mealCount: json['mealCount'] as int? ?? meals.length,
      imageUrl: imgs.isNotEmpty ? imgs[0] : '',
      images: imgs,
      type: _parseType(_str(json['type'], 'LUNCH')),
      duration: _parseDuration(_str(json['duration'], 'WORK_WEEK')),
      categories: [_parseCategory(categoryStr)],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      provider: ProviderEntity(
        id: _str(providerJson['id']),
        name: _str(providerJson['name'] ?? providerJson['businessName']),
        description: _str(providerJson['description']),
        avatarUrl: _str(providerJson['logo'] ?? providerJson['avatar']),
        logo: _str(providerJson['logo'] ?? providerJson['avatar']),
        rating: (providerJson['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: providerJson['reviewCount'] as int? ?? 0,
        isVerified: providerJson['isVerified'] as bool? ?? false,
        acceptsDelivery: providerJson['acceptsDelivery'] as bool? ?? false,
        acceptsPickup: providerJson['acceptsPickup'] as bool? ?? false,
        businessAddress: _str(providerJson['businessAddress']),
        city: () {
          final cityRaw = providerJson['city'];
          final cityMap = cityRaw is Map
              ? Map<String, dynamic>.from(cityRaw as Map)
              : <String, dynamic>{};
          return ProviderCity(
            id: _str(cityMap['id']),
            name: _str(cityMap['name'] ?? cityRaw),
          );
        }(),
      ),
      meals: meals,
      deliveryZones: deliveryZones,
      pickupPoints: pickupPoints,
      isAvailable: json['isActive'] as bool? ?? true,
      providerSubscriptions: (json['providerSubscriptions'] as List? ?? [])
          .map((e) => _mapProviderSubscription(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Mapper léger pour les abonnements du provider (sans récursion)
  static SubscriptionEntity _mapProviderSubscription(Map<String, dynamic> json) {
    final imgs = (json['images'] as List?)
            ?.map((e) => e is String ? e : _str(e))
            .toList() ??
        [];
    final categoryRaw = json['category'];
    final categoryStr = categoryRaw is List
        ? _str(categoryRaw.isNotEmpty ? categoryRaw[0] : 'AFRICAN')
        : _str(categoryRaw, 'AFRICAN');
    return SubscriptionEntity(
      id: _str(json['id']),
      title: _str(json['name']),
      description: _str(json['description']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: _str(json['currency'], 'XOF'),
      imageUrl: imgs.isNotEmpty ? imgs[0] : '',
      images: imgs,
      type: _parseType(_str(json['type'], 'LUNCH')),
      duration: _parseDuration(_str(json['duration'], 'WORK_WEEK')),
      categories: [_parseCategory(categoryStr)],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      provider: ProviderEntity(
        id: '', name: '', description: '', avatarUrl: '', logo: '',
        rating: 0, reviewCount: 0, isVerified: false,
        acceptsDelivery: false, acceptsPickup: false, businessAddress: '',
        city: const ProviderCity(id: '', name: ''),
      ),
      meals: const [],
      deliveryZones: const [],
      pickupPoints: const [],
      isAvailable: json['isActive'] as bool? ?? true,
    );
  }

  static ReviewEntity _mapReview(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return ReviewEntity(
      id: json['id'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      userName: user['name'] as String? ?? 'Utilisateur',
      userAvatar: user['avatar'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static SubscriptionType _parseType(String type) {
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

  static SubscriptionDuration _parseDuration(String duration) {
    switch (duration.toUpperCase()) {
      case 'DAY':
        return SubscriptionDuration.day;
      case 'THREE_DAYS':
        return SubscriptionDuration.threeDays;
      case 'WEEK':
        return SubscriptionDuration.week;
      case 'TWO_WEEKS':
        return SubscriptionDuration.twoWeeks;
      case 'MONTH':
        return SubscriptionDuration.month;
      case 'WEEKEND':
        return SubscriptionDuration.weekend;
      case 'WORK_WEEK_2':
        return SubscriptionDuration.workWeek2;
      case 'WORK_MONTH':
        return SubscriptionDuration.workMonth;
      case 'WORK_WEEK':
      default:
        return SubscriptionDuration.workWeek;
    }
  }

  static SubscriptionCategory _parseCategory(String category) {
    switch (category.toUpperCase()) {
      case 'EUROPEAN':
        return SubscriptionCategory.european;
      case 'ASIAN':
        return SubscriptionCategory.asian;
      case 'VEGETARIAN':
        return SubscriptionCategory.vegetarian;
      case 'HALAL':
        return SubscriptionCategory.halal;
      case 'VEGAN':
        return SubscriptionCategory.vegan;
      case 'AFRICAN':
      default:
        return SubscriptionCategory.african;
    }
  }
}
