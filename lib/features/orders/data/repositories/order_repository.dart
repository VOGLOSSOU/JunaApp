import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/order_entity.dart';
import '../../../subscriptions/data/repositories/subscription_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    dio: ref.read(dioProvider),
    subRepo: ref.read(subscriptionRepositoryProvider),
  );
});

class OrderRepository {
  final Dio _dio;
  final SubscriptionRepository _subRepo;

  OrderRepository({required Dio dio, required SubscriptionRepository subRepo})
      : _dio = dio,
        _subRepo = subRepo;

  Future<OrderEntity> createOrder({
    required String subscriptionId,
    required String deliveryMethod,
    String? deliveryAddress,
    String? landmarkId,
    String? notes,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.orders, data: {
        'subscriptionId': subscriptionId,
        'deliveryMethod': deliveryMethod,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
        if (landmarkId != null) 'landmarkId': landmarkId,
        if (notes != null) 'notes': notes,
        'paymentMethod': paymentMethod,
      });
      return _mapOrder(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<List<OrderEntity>> getMyOrders({String? status}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.myOrders,
        queryParameters: {
          if (status != null) 'status': status,
          'limit': 50,
        },
      );
      final data = response.data['data'];
      final list = data is List ? data : data['orders'] as List;
      return list
          .map((e) => _mapOrder(e as Map<String, dynamic>))
          .toList();
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
      await _dio.put(ApiEndpoints.cancelOrder(id));
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  OrderEntity _mapOrder(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>?;

    return OrderEntity(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? '#${json['id'].toString().substring(0, 8).toUpperCase()}',
      status: _parseStatus(json['status'] as String? ?? 'PENDING'),
      deliveryMethod: _parseDelivery(json['deliveryMethod'] as String? ?? 'PICKUP'),
      deliveryAddress: json['deliveryAddress'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: _parsePayment(json['paymentMethod'] as String? ?? 'CASH'),
      qrCode: json['qrCode'] as String? ?? json['id'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      subscription: sub != null ? _subRepo._mapSubscription(sub) : null,
    );
  }

  OrderStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED': return OrderStatus.confirmed;
      case 'PREPARING': return OrderStatus.preparing;
      case 'READY': return OrderStatus.ready;
      case 'DELIVERED': return OrderStatus.delivered;
      case 'CANCELLED': return OrderStatus.cancelled;
      case 'PENDING':
      default: return OrderStatus.pending;
    }
  }

  DeliveryMethod _parseDelivery(String method) {
    switch (method.toUpperCase()) {
      case 'DELIVERY': return DeliveryMethod.delivery;
      case 'PICKUP':
      default: return DeliveryMethod.pickup;
    }
  }

  PaymentMethod _parsePayment(String method) {
    switch (method.toUpperCase()) {
      case 'MOBILE_MONEY_WAVE': return PaymentMethod.wave;
      case 'MOBILE_MONEY_MTN': return PaymentMethod.mtn;
      case 'MOBILE_MONEY_MOOV': return PaymentMethod.moov;
      case 'MOBILE_MONEY_ORANGE': return PaymentMethod.orange;
      case 'CARD': return PaymentMethod.card;
      case 'CASH':
      default: return PaymentMethod.cash;
    }
  }
}
