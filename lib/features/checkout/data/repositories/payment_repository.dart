import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(dio: ref.read(dioProvider));
});

class InitiatePaymentResult {
  final String paymentId;
  final String status;
  final String message;
  const InitiatePaymentResult({
    required this.paymentId,
    required this.status,
    required this.message,
  });
}

class PaymentStatusResult {
  final String paymentId;
  final String orderId;
  final double amount;
  final String status;
  const PaymentStatusResult({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.status,
  });
}

class OrderCreatedResult {
  final String orderId;
  final String orderNumber;
  final double amount;
  const OrderCreatedResult({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
  });
}

class PaymentRepository {
  final Dio _dio;
  PaymentRepository({required Dio dio}) : _dio = dio;

  Future<OrderCreatedResult> createOrder({
    required String subscriptionId,
    required String deliveryMethod,
    String? deliveryAddress,
    String? deliveryCity,
    String? pickupLocation,
    bool startAsap = true,
  }) async {
    try {
      final body = <String, dynamic>{
        'subscriptionId': subscriptionId,
        'deliveryMethod': deliveryMethod,
        'startAsap': startAsap,
      };
      if (deliveryAddress != null) body['deliveryAddress'] = deliveryAddress;
      if (deliveryCity != null)    body['deliveryCity']    = deliveryCity;
      if (pickupLocation != null)  body['pickupLocation']  = pickupLocation;

      final response = await _dio.post(ApiEndpoints.orders, data: body);
      final data = response.data['data'] as Map<String, dynamic>;
      return OrderCreatedResult(
        orderId:     data['id'] as String,
        orderNumber: data['orderNumber'] as String? ?? '',
        amount:      (data['amount'] as num?)?.toDouble() ?? 0.0,
      );
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<InitiatePaymentResult> initiatePayment({
    required String orderId,
    required String phoneNumber,
    required String provider,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.initiatePayment,
        data: {
          'orderId':     orderId,
          'phoneNumber': phoneNumber,
          'provider':    provider,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return InitiatePaymentResult(
        paymentId: data['paymentId'] as String,
        status:    data['status']    as String? ?? 'PROCESSING',
        message:   data['message']   as String? ?? '',
      );
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<PaymentStatusResult> getPaymentStatus(String paymentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.paymentStatus(paymentId));
      final data = response.data['data'] as Map<String, dynamic>;
      return PaymentStatusResult(
        paymentId: data['id']      as String? ?? paymentId,
        orderId:   data['orderId'] as String? ?? '',
        amount:    (data['amount'] as num?)?.toDouble() ?? 0.0,
        status:    data['status']  as String? ?? 'PROCESSING',
      );
    } on DioException catch (e) {
      throw extractException(e);
    }
  }
}
