import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/active_subscription_entity.dart';

final activeSubscriptionRepositoryProvider =
    Provider<ActiveSubscriptionRepository>((ref) {
  return ActiveSubscriptionRepository(dio: ref.read(dioProvider));
});

class ActiveSubscriptionRepository {
  final Dio _dio;
  ActiveSubscriptionRepository({required Dio dio}) : _dio = dio;

  Future<List<ActiveSubscriptionEntity>> getActiveSubscriptions() async {
    final response = await _dio.get(ApiEndpoints.activeSubscriptions);
    final data = response.data['data'];
    final list = data is List ? data : (data['activeSubscriptions'] ?? data['items'] ?? []) as List;
    return list
        .map((e) => _map(e as Map<String, dynamic>))
        .toList();
  }

  static ActiveSubscriptionEntity _map(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>? ?? {};
    final provider = sub['provider'] as Map<String, dynamic>? ?? {};
    final order = json['order'] as Map<String, dynamic>? ?? {};

    return ActiveSubscriptionEntity(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      subscriptionId: json['subscriptionId'] as String? ?? sub['id'] as String? ?? '',
      subscriptionName: sub['name'] as String? ?? '',
      subscriptionType: sub['type'] as String? ?? '',
      subscriptionCategory: sub['category'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      providerName: provider['businessName'] as String? ??
          provider['name'] as String? ?? '',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['endsAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      deliveryMethod: order['deliveryMethod'] as String? ??
          json['deliveryMethod'] as String? ?? 'PICKUP',
      deliveryCity: order['deliveryCity'] as String? ??
          json['deliveryCity'] as String?,
    );
  }
}
