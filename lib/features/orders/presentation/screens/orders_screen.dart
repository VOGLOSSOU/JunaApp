import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
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
    final orders = ordersState.items;
    final active = orders.where((o) =>
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled).toList();
    final history = orders.where((o) =>
        o.status == OrderStatus.completed ||
        o.status == OrderStatus.cancelled).toList();

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
            Tab(text: 'En cours (${active.length})'),
            Tab(text: 'Historique (${history.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(orders: active, emptyMessage: 'Aucune commande en cours'),
          _OrdersList(
              orders: history, emptyMessage: 'Aucune commande terminée'),
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
            Text(
              emptyMessage,
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _OrderCard(order: orders[i]),
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
                    order.subscription?.title ?? order.orderNumber,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                JunaBadge.orderStatus(order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  order.subscription?.provider.name ?? '',
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary),
                ),
                if (order.subscription?.provider.isVerified == true) ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.verified, color: Colors.blue, size: 12),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (order.subscription != null) Text(
              '${order.subscription!.type.label} · ${order.subscription!.duration.label}',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary),
            ),
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
                Text(
                  order.deliveryAddress ?? '',
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatPrice(order.totalAmount),
                  style: AppTypography.labelLarge.copyWith(
                      color: AppColors.accent),
                ),
                Row(
                  children: [
                    Text(
                      'Voir →',
                      style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
