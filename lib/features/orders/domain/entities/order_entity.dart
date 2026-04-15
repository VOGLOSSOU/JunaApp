import '../../../../core/utils/enums.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';

class OrderEntity {
  final String id;
  final String orderNumber;
  final SubscriptionEntity? subscription;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final String? deliveryAddress;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final String qrCode;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    this.subscription,
    required this.status,
    required this.deliveryMethod,
    this.deliveryAddress,
    required this.totalAmount,
    required this.paymentMethod,
    required this.qrCode,
    required this.createdAt,
  });
}
