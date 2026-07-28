import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/cache_service.dart';
import '../../domain/entities/active_subscription_entity.dart';

final activeSubscriptionRepositoryProvider =
    Provider<ActiveSubscriptionRepository>((ref) {
  return ActiveSubscriptionRepository(
    dio: ref.read(dioProvider),
    cacheService: ref.read(cacheServiceProvider),
  );
});

class ActiveSubscriptionRepository {
  final Dio _dio;
  final CacheService _cacheService;

  ActiveSubscriptionRepository({
    required Dio dio,
    required CacheService cacheService,
  })  : _dio = dio,
        _cacheService = cacheService;

  Future<List<ActiveSubscriptionEntity>> getActiveSubscriptions({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'active_subscriptions';
    final stale = _mapList(await _cacheService.get(cacheKey));
    if (!forceRefresh) {
      final fresh = await _cacheService.get(
        cacheKey,
        maxAge: const Duration(minutes: 5),
      );
      final cached = _mapList(fresh);
      if (cached != null) return cached;
    }

    try {
      final response = await _dio.get(ApiEndpoints.activeSubscriptions);
      final list = _extractList(
        response.data,
        const ['activeSubscriptions', 'subscriptions', 'items'],
      );
      await _cacheService.save(cacheKey, list);
      return list
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      final exception = extractException(e);
      if ((exception.isNetworkError ||
              (exception.statusCode != null && exception.statusCode! >= 500)) &&
          stale != null) {
        return stale;
      }
      throw exception;
    } catch (e) {
      if (stale != null) return stale;
      if (e is AppException) rethrow;
      throw const AppException(
        message: 'Impossible de lire les abonnements reçus.',
        code: 'PARSING_ERROR',
      );
    }
  }

  static List<ActiveSubscriptionEntity>? _mapList(dynamic value) {
    if (value is! List) return null;
    try {
      return value
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static List _extractList(dynamic body, List<String> collectionKeys) {
    dynamic value = body is Map ? body['data'] : body;
    if (value is List) return value;
    if (value is Map) {
      for (final key in collectionKeys) {
        final candidate = value[key];
        if (candidate is List) return candidate;
      }
      final nested = value['data'];
      if (nested is List) return nested;
    }
    throw const AppException(
      message: 'Format d’abonnements inattendu.',
      code: 'PARSING_ERROR',
    );
  }

  Future<void> clearCache() => _cacheService.clear('active_subscriptions');

  static ActiveSubscriptionEntity _map(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>? ?? {};
    final provider = sub['provider'] as Map<String, dynamic>? ?? {};
    final order = json['order'] as Map<String, dynamic>? ?? {};

    return ActiveSubscriptionEntity(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      subscriptionId:
          json['subscriptionId'] as String? ?? sub['id'] as String? ?? '',
      subscriptionName: sub['name'] as String? ?? '',
      subscriptionType: sub['type'] as String? ?? '',
      subscriptionCategory: sub['category'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      providerName: provider['businessName'] as String? ??
          provider['name'] as String? ??
          '',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['endsAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      deliveryMethod: order['deliveryMethod'] as String? ??
          json['deliveryMethod'] as String? ??
          'PICKUP',
      deliveryCity:
          order['deliveryCity'] as String? ?? json['deliveryCity'] as String?,
    );
  }
}
