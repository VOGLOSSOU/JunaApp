import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../subscriptions/data/repositories/subscription_repository.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';

class HomeFeed {
  final List<SubscriptionEntity> popular;
  final List<SubscriptionEntity> recent;
  final List<ProviderEntity> providers;

  const HomeFeed({
    this.popular = const [],
    this.recent = const [],
    this.providers = const [],
  });
}

final homeFeedRepositoryProvider = Provider<HomeFeedRepository>((ref) {
  return HomeFeedRepository(dio: ref.read(dioProvider));
});

class HomeFeedRepository {
  final Dio _dio;

  HomeFeedRepository({required Dio dio}) : _dio = dio;

  Future<HomeFeed> getHomeFeed(String cityId, {int limit = 10}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.homeFeed,
        queryParameters: {'cityId': cityId, 'limit': limit},
      );
      final data = response.data['data'] as Map<String, dynamic>;

      return HomeFeed(
        popular: (data['popular'] as List)
            .map((e) => SubscriptionRepository.mapSubscription(
                e as Map<String, dynamic>))
            .toList(),
        recent: (data['recent'] as List)
            .map((e) => SubscriptionRepository.mapSubscription(
                e as Map<String, dynamic>))
            .toList(),
        providers: (data['providers'] as List)
            .map((e) => _mapProvider(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  static ProviderEntity _mapProvider(Map<String, dynamic> json) {
    return ProviderEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: '',
      avatarUrl: json['logo'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: 0,
      isVerified: json['isVerified'] as bool? ?? false,
      acceptsDelivery: false,
      acceptsPickup: false,
      businessAddress: '',
      city: ProviderCity(id: '', name: json['city'] as String? ?? ''),
    );
  }
}
