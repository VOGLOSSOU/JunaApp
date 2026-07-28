import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/order_entity.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    dio: ref.read(dioProvider),
    cacheService: ref.read(cacheServiceProvider),
  );
});

class OrderRepository {
  final Dio _dio;
  final CacheService _cacheService;

  OrderRepository({required Dio dio, required CacheService cacheService})
      : _dio = dio,
        _cacheService = cacheService;

  Future<List<OrderEntity>> getMyOrders({bool forceRefresh = false}) async {
    const cacheKey = 'my_orders';
    final stale = await _readCachedOrders(cacheKey);
    if (!forceRefresh) {
      final fresh = await _cacheService.get(
        cacheKey,
        maxAge: const Duration(minutes: 5),
      );
      final cached = _mapOrderList(fresh);
      if (cached != null) return cached;
    }

    try {
      final response = await _dio.get(ApiEndpoints.myOrders);
      final list = _extractList(response.data, const ['orders', 'items']);
      await _cacheService.save(cacheKey, list);
      return list.map((e) => _mapOrder(e as Map<String, dynamic>)).toList();
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
      throw AppException(
        message: 'Impossible de lire les commandes reçues.',
        code: 'PARSING_ERROR',
      );
    }
  }

  Future<List<OrderEntity>?> _readCachedOrders(String key) async {
    return _mapOrderList(await _cacheService.get(key));
  }

  static List<OrderEntity>? _mapOrderList(dynamic value) {
    if (value is! List) return null;
    try {
      return value
          .map((e) => _mapOrder(Map<String, dynamic>.from(e as Map)))
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
      message: 'Format de commandes inattendu.',
      code: 'PARSING_ERROR',
    );
  }

  Future<void> clearMyOrdersCache() => _cacheService.clear('my_orders');

  Future<OrderEntity> getOrderById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.orderById(id));
      return _mapOrder(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<void> activateOrder(String id) async {
    try {
      await _dio.put(ApiEndpoints.activateOrder(id));
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  static OrderEntity _mapOrder(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>?;
    final provider = sub?['provider'] as Map<String, dynamic>?;

    return OrderEntity(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ??
          '#${(json['id'] as String).substring(0, 8).toUpperCase()}',
      status: _parseStatus(json['status'] as String? ?? 'PENDING'),
      deliveryMethod:
          _parseDelivery(json['deliveryMethod'] as String? ?? 'PICKUP'),
      deliveryAddress: json['deliveryAddress'] as String?,
      deliveryCity: json['deliveryCity'] as String?,
      pickupLocation: json['pickupLocation'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      qrCode: json['qrCode'] as String? ?? json['id'] as String,
      scheduledFor: DateTime.tryParse(json['scheduledFor'] as String? ?? ''),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      subscriptionId: sub?['id'] as String?,
      subscriptionName: sub?['name'] as String?,
      providerName: provider?['businessName'] as String?,
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'ACTIVE':
        return OrderStatus.active;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PENDING':
      default:
        return OrderStatus.pending;
    }
  }

  static DeliveryMethod _parseDelivery(String method) {
    switch (method.toUpperCase()) {
      case 'DELIVERY':
        return DeliveryMethod.delivery;
      case 'PICKUP':
      default:
        return DeliveryMethod.pickup;
    }
  }
}
