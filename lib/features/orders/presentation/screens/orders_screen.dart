import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_badge.dart';
import '../controllers/orders_controller.dart';
import '../../domain/entities/order_entity.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersControllerProvider);

    if (ordersState.isLoading && ordersState.items.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final orders = ordersState.items;
    final active = orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.confirmed)
        .toList();
    final running = orders.where((o) => o.status == OrderStatus.active).toList();
    final history =
        orders.where((o) => o.status == OrderStatus.cancelled).toList();

    final inProgress = [...active, ...running];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Mes commandes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: AppTypography.labelLarge,
          tabs: [
            Tab(text: 'En cours (${inProgress.length})'),
            Tab(text: 'Historique (${history.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(
              orders: inProgress,
              emptyMessage: 'Aucune commande en cours'),
          _OrdersList(
              orders: history,
              emptyMessage: 'Aucune commande annulée'),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderEntity> orders;
  final String emptyMessage;

  const _OrdersList({required this.orders, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.lg),
            Text(emptyMessage,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.subscriptionName ?? order.orderNumber,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                JunaBadge.orderStatus(order.status),
              ],
            ),
            if (order.providerName != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                order.providerName!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  order.deliveryMethod == DeliveryMethod.delivery
                      ? Icons.delivery_dining_outlined
                      : Icons.store_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    order.deliveryMethod == DeliveryMethod.delivery
                        ? order.deliveryAddress ?? ''
                        : order.pickupLocation ?? 'Retrait sur place',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatPrice(order.amount),
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.accent),
                ),
                Text('Voir →',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
