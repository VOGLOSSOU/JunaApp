import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../core/utils/mock_data.dart';
import '../../../../core/utils/enums.dart';

class OrdersController extends StateNotifier<List<OrderEntity>> {
  OrdersController() : super(MockData.orders);

  void addOrder(OrderEntity order) {
    state = [order, ...state];
  }
}

final ordersControllerProvider =
    StateNotifierProvider<OrdersController, List<OrderEntity>>(
  (ref) => OrdersController(),
);

final activeOrdersProvider = Provider<List<OrderEntity>>((ref) {
  final orders = ref.watch(ordersControllerProvider);
  return orders.where((o) =>
    o.status != OrderStatus.completed &&
    o.status != OrderStatus.cancelled
  ).toList();
});

final hasActiveOrdersProvider = Provider<bool>((ref) {
  return ref.watch(activeOrdersProvider).isNotEmpty;
});

// Provider pour le checkout en cours
class CheckoutState {
  final String? subscriptionId;
  final DeliveryMethod? deliveryMethod;
  final String? deliveryLocation;
  final PaymentMethod? paymentMethod;

  const CheckoutState({
    this.subscriptionId,
    this.deliveryMethod,
    this.deliveryLocation,
    this.paymentMethod,
  });

  CheckoutState copyWith({
    String? subscriptionId,
    DeliveryMethod? deliveryMethod,
    String? deliveryLocation,
    PaymentMethod? paymentMethod,
  }) {
    return CheckoutState(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController() : super(const CheckoutState());

  void setSubscription(String id) =>
      state = state.copyWith(subscriptionId: id);

  void setDelivery(DeliveryMethod method, String location) =>
      state = state.copyWith(deliveryMethod: method, deliveryLocation: location);

  void setPaymentMethod(PaymentMethod method) =>
      state = state.copyWith(paymentMethod: method);

  void reset() => state = const CheckoutState();
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>(
  (ref) => CheckoutController(),
);
