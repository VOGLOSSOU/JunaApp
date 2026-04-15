import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/provider_entity.dart';
import '../../domain/entities/meal_entity.dart';
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
          .map((e) => _mapSubscription(e as Map<String, dynamic>))
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
      final response =
          await _dio.get(ApiEndpoints.subscriptionById(id));
      return _mapSubscription(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  SubscriptionEntity _mapSubscription(Map<String, dynamic> json) {
    final provider = json['provider'] as Map<String, dynamic>;
    final meals = (json['meals'] as List? ?? [])
        .map((m) => MealEntity(
              id: m['id'] as String,
              name: m['name'] as String,
              description: m['description'] as String? ?? '',
              imageUrl: m['imageUrl'] as String? ?? '',
            ))
        .toList();

    return SubscriptionEntity(
      id: json['id'] as String,
      title: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: (json['images'] as List?)?.isNotEmpty == true
          ? json['images'][0] as String
          : '',
      type: _parseType(json['type'] as String? ?? 'LUNCH'),
      duration: _parseDuration(json['duration'] as String? ?? 'WORK_WEEK'),
      categories: [_parseCategory(json['category'] as String? ?? 'AFRICAN')],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      provider: ProviderEntity(
        id: provider['id'] as String,
        name: provider['name'] as String,
        description: '',
        avatarUrl: provider['logo'] as String? ?? '',
        rating: 0.0,
        reviewCount: 0,
        isVerified: provider['isVerified'] as bool? ?? false,
        city: '',
      ),
      meals: meals,
      deliveryZones: [],
    );
  }

  SubscriptionType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'BREAKFAST': return SubscriptionType.breakfast;
      case 'DINNER': return SubscriptionType.dinner;
      case 'SNACK': return SubscriptionType.snack;
      case 'LUNCH':
      default: return SubscriptionType.lunch;
    }
  }

  SubscriptionDuration _parseDuration(String duration) {
    switch (duration.toUpperCase()) {
      case 'DAY': return SubscriptionDuration.day;
      case 'THREE_DAYS': return SubscriptionDuration.threeDays;
      case 'WEEK': return SubscriptionDuration.week;
      case 'TWO_WEEKS': return SubscriptionDuration.twoWeeks;
      case 'MONTH': return SubscriptionDuration.month;
      case 'WEEKEND': return SubscriptionDuration.weekend;
      case 'WORK_WEEK_2': return SubscriptionDuration.workWeek2;
      case 'WORK_MONTH': return SubscriptionDuration.workMonth;
      case 'WORK_WEEK':
      default: return SubscriptionDuration.workWeek;
    }
  }

  SubscriptionCategory _parseCategory(String category) {
    switch (category.toUpperCase()) {
      case 'EUROPEAN': return SubscriptionCategory.european;
      case 'ASIAN': return SubscriptionCategory.asian;
      case 'VEGETARIAN': return SubscriptionCategory.vegetarian;
      case 'HALAL': return SubscriptionCategory.halal;
      case 'VEGAN': return SubscriptionCategory.vegan;
      case 'AFRICAN':
      default: return SubscriptionCategory.african;
    }
  }
}
