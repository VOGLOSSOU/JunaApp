import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/enums.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';

class OrdersState {
  final List<OrderEntity> items;
  final bool isLoading;
  final AppException? error;

  const OrdersState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<OrderEntity>? items,
    bool? isLoading,
    AppException? error,
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

  OrdersController(this._repo) : super(const OrdersState());

  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh && state.items.isNotEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _repo.getMyOrders(forceRefresh: forceRefresh);
      state = state.copyWith(items: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractException(e),
      );
    }
  }

  Future<bool> activate(String id) async {
    try {
      await _repo.activateOrder(id);
      await _repo.clearMyOrdersCache();
      state = state.copyWith(
        items: state.items
            .map((o) => o.id == id ? o.copyWith(status: OrderStatus.active) : o)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: extractException(e));
      return false;
    }
  }

  void reset() {
    state = const OrdersState();
  }
}

final ordersControllerProvider =
    StateNotifierProvider<OrdersController, OrdersState>((ref) {
  return OrdersController(ref.read(orderRepositoryProvider));
});

final orderByIdProvider =
    FutureProvider.autoDispose.family<OrderEntity, String>((ref, id) async {
  return ref.read(orderRepositoryProvider).getOrderById(id);
});

final pendingOrdersProvider = Provider<List<OrderEntity>>((ref) {
  return ref
      .watch(ordersControllerProvider)
      .items
      .where((o) =>
          o.status == OrderStatus.pending || o.status == OrderStatus.confirmed)
      .toList();
});

final activeOrdersProvider = Provider<List<OrderEntity>>((ref) {
  return ref
      .watch(ordersControllerProvider)
      .items
      .where((o) => o.status == OrderStatus.active)
      .toList();
});

final hasActiveOrdersProvider = Provider<bool>((ref) {
  return ref.watch(activeOrdersProvider).isNotEmpty;
});
