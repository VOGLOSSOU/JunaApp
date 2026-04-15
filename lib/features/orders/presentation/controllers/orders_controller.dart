import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_entity.dart';
import '../../data/repositories/order_repository.dart';
import '../../../../core/utils/enums.dart';

// ── Orders list ───────────────────────────────────────────────────────────────

class OrdersState {
  final List<OrderEntity> items;
  final bool isLoading;
  final String? error;

  const OrdersState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<OrderEntity>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OrdersState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrdersController extends StateNotifier<OrdersState> {
  final OrderRepository _repo;

  OrdersController(this._repo) : super(const OrdersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _repo.getMyOrders();
      state = state.copyWith(items: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createOrder({
    required String subscriptionId,
    required String deliveryMethod,
    String? deliveryAddress,
    String? landmarkId,
    String? notes,
    required String paymentMethod,
  }) async {
    try {
      final order = await _repo.createOrder(
        subscriptionId: subscriptionId,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        landmarkId: landmarkId,
        notes: notes,
        paymentMethod: paymentMethod,
      );
      state = state.copyWith(items: [order, ...state.items]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cancel(String id) async {
    try {
      await _repo.cancelOrder(id);
      final updated = state.items.map((o) {
        if (o.id == id) {
          return OrderEntity(
            id: o.id,
            orderNumber: o.orderNumber,
            subscription: o.subscription,
            status: OrderStatus.cancelled,
            deliveryMethod: o.deliveryMethod,
            deliveryAddress: o.deliveryAddress,
            totalAmount: o.totalAmount,
            paymentMethod: o.paymentMethod,
            qrCode: o.qrCode,
            createdAt: o.createdAt,
          );
        }
        return o;
      }).toList();
      state = state.copyWith(items: updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final ordersControllerProvider =
    StateNotifierProvider<OrdersController, OrdersState>((ref) {
  return OrdersController(ref.read(orderRepositoryProvider));
});

final activeOrdersProvider = Provider<List<OrderEntity>>((ref) {
  final state = ref.watch(ordersControllerProvider);
  return state.items.where((o) =>
    o.status != OrderStatus.completed &&
    o.status != OrderStatus.cancelled
  ).toList();
});

final hasActiveOrdersProvider = Provider<bool>((ref) {
  return ref.watch(activeOrdersProvider).isNotEmpty;
});

// ── Checkout ──────────────────────────────────────────────────────────────────

class CheckoutState {
  final String? subscriptionId;
  final DeliveryMethod? deliveryMethod;
  final String? deliveryLocation;
  final String? landmarkId;
  final PaymentMethod? paymentMethod;

  const CheckoutState({
    this.subscriptionId,
    this.deliveryMethod,
    this.deliveryLocation,
    this.landmarkId,
    this.paymentMethod,
  });

  CheckoutState copyWith({
    String? subscriptionId,
    DeliveryMethod? deliveryMethod,
    String? deliveryLocation,
    String? landmarkId,
    PaymentMethod? paymentMethod,
  }) {
    return CheckoutState(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      landmarkId: landmarkId ?? this.landmarkId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController() : super(const CheckoutState());

  void setSubscription(String id) =>
      state = state.copyWith(subscriptionId: id);

  void setDelivery(DeliveryMethod method, {String? address, String? landmarkId}) =>
      state = state.copyWith(
        deliveryMethod: method,
        deliveryLocation: address,
        landmarkId: landmarkId,
      );

  void setPaymentMethod(PaymentMethod method) =>
      state = state.copyWith(paymentMethod: method);

  void reset() => state = const CheckoutState();
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>(
  (ref) => CheckoutController(),
);
