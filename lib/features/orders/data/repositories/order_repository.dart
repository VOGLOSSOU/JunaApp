import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/order_entity.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(dio: ref.read(dioProvider));
});

class OrderRepository {
  final Dio _dio;

  OrderRepository({required Dio dio}) : _dio = dio;

  Future<List<OrderEntity>> getMyOrders() async {
    try {
      final response = await _dio.get(ApiEndpoints.myOrders);
      final data = response.data['data'];
      final list = data is List ? data : (data['orders'] as List? ?? []);
      return list.map((e) => _mapOrder(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<OrderEntity> getOrderById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.orderById(id));
      return _mapOrder(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<void> cancelOrder(String id) async {
    try {
      await _dio.delete(ApiEndpoints.orderById(id));
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
      scheduledFor:
          DateTime.tryParse(json['scheduledFor'] as String? ?? ''),
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
      subscriptionId: sub?['id'] as String?,
      subscriptionName: sub?['name'] as String?,
      providerName: provider?['businessName'] as String?,
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED': return OrderStatus.confirmed;
      case 'ACTIVE':    return OrderStatus.active;
      case 'CANCELLED': return OrderStatus.cancelled;
      case 'PENDING':
      default:          return OrderStatus.pending;
    }
  }

  static DeliveryMethod _parseDelivery(String method) {
    switch (method.toUpperCase()) {
      case 'DELIVERY': return DeliveryMethod.delivery;
      case 'PICKUP':
      default:         return DeliveryMethod.pickup;
    }
  }
}
