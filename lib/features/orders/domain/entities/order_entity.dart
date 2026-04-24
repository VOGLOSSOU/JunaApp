import '../../../../core/utils/enums.dart';

class OrderEntity {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? pickupLocation;
  final double amount;
  final String qrCode;
  final DateTime? scheduledFor;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? subscriptionId;
  final String? subscriptionName;
  final String? providerName;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.deliveryCity,
    this.pickupLocation,
    required this.amount,
    required this.qrCode,
    this.scheduledFor,
    this.completedAt,
    required this.createdAt,
    this.subscriptionId,
    this.subscriptionName,
    this.providerName,
  });

  OrderEntity copyWith({OrderStatus? status}) => OrderEntity(
        id: id,
        orderNumber: orderNumber,
        status: status ?? this.status,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        deliveryCity: deliveryCity,
        pickupLocation: pickupLocation,
        amount: amount,
        qrCode: qrCode,
        scheduledFor: scheduledFor,
        completedAt: completedAt,
        createdAt: createdAt,
        subscriptionId: subscriptionId,
        subscriptionName: subscriptionName,
        providerName: providerName,
      );
}
