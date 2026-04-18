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
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.subscriptions,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (cityId != null) 'cityId': cityId,
          if (landmarkId != null) 'landmarkId': landmarkId,
          if (category != null) 'category': category,
          if (type != null) 'type': type,
          if (duration != null) 'duration': duration,
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
    }
  }

  Future<SubscriptionEntity> getSubscriptionById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.subscriptionById(id));
      return mapSubscription(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<List<ReviewEntity>> getReviews(String subscriptionId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.reviewsBySubscription(subscriptionId),
      );
      final data = response.data['data'];
      final list = data is Map ? (data['reviews'] as List? ?? []) : (data as List? ?? []);
      return list.map((e) => _mapReview(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  static SubscriptionEntity mapSubscription(Map<String, dynamic> json) {
    final providerJson = json['provider'] as Map<String, dynamic>;
    final imgs = (json['images'] as List?)?.cast<String>() ?? [];

    final meals = (json['meals'] as List? ?? [])
        .map((m) => MealEntity(
              id: m['id'] as String,
              name: m['name'] as String,
              description: m['description'] as String? ?? '',
              imageUrl: m['imageUrl'] as String? ?? '',
            ))
        .toList();

    final deliveryZones =
        (json['deliveryZones'] as List?)?.cast<String>() ?? [];
    final pickupPoints =
        (json['pickupPoints'] as List?)?.cast<String>() ?? [];

    return SubscriptionEntity(
      id: json['id'] as String,
      title: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'XOF',
      mealCount: json['mealCount'] as int? ?? meals.length,
      imageUrl: imgs.isNotEmpty ? imgs[0] : '',
      images: imgs,
      type: _parseType(json['type'] as String? ?? 'LUNCH'),
      duration: _parseDuration(json['duration'] as String? ?? 'WORK_WEEK'),
      categories: [_parseCategory(json['category'] as String? ?? 'AFRICAN')],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      provider: ProviderEntity(
        id: providerJson['id'] as String,
        name: providerJson['name'] as String,
        description: providerJson['description'] as String? ?? '',
        avatarUrl: providerJson['logo'] as String? ?? '',
        rating: (providerJson['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: providerJson['reviewCount'] as int? ?? 0,
        isVerified: providerJson['isVerified'] as bool? ?? false,
        city: providerJson['city'] as String? ?? '',
      ),
      meals: meals,
      deliveryZones: deliveryZones,
      pickupPoints: pickupPoints,
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
      case 'BREAKFAST': return SubscriptionType.breakfast;
      case 'DINNER':    return SubscriptionType.dinner;
      case 'SNACK':     return SubscriptionType.snack;
      case 'LUNCH':
      default:          return SubscriptionType.lunch;
    }
  }

  static SubscriptionDuration _parseDuration(String duration) {
    switch (duration.toUpperCase()) {
      case 'DAY':        return SubscriptionDuration.day;
      case 'THREE_DAYS': return SubscriptionDuration.threeDays;
      case 'WEEK':       return SubscriptionDuration.week;
      case 'TWO_WEEKS':  return SubscriptionDuration.twoWeeks;
      case 'MONTH':      return SubscriptionDuration.month;
      case 'WEEKEND':    return SubscriptionDuration.weekend;
      case 'WORK_WEEK_2':return SubscriptionDuration.workWeek2;
      case 'WORK_MONTH': return SubscriptionDuration.workMonth;
      case 'WORK_WEEK':
      default:           return SubscriptionDuration.workWeek;
    }
  }

  static SubscriptionCategory _parseCategory(String category) {
    switch (category.toUpperCase()) {
      case 'EUROPEAN':   return SubscriptionCategory.european;
      case 'ASIAN':      return SubscriptionCategory.asian;
      case 'VEGETARIAN': return SubscriptionCategory.vegetarian;
      case 'HALAL':      return SubscriptionCategory.halal;
      case 'VEGAN':      return SubscriptionCategory.vegan;
      case 'AFRICAN':
      default:           return SubscriptionCategory.african;
    }
  }
}
