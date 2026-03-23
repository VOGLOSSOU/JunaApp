import '../../../../core/utils/enums.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';

class OrderEntity {
  final String id;
  final String orderNumber;
  final SubscriptionEntity subscription;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final String deliveryLocation;
  final double totalAmount;
  final double deliveryFee;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.subscription,
    required this.status,
    required this.deliveryMethod,
    required this.deliveryLocation,
    required this.totalAmount,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.createdAt,
  });
}
