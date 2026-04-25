import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../domain/entities/active_subscription_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../controllers/active_subscriptions_controller.dart';
import '../controllers/orders_controller.dart';

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
    final asyncSubs = ref.watch(activeSubscriptionsProvider);

    final activeSubsCount = asyncSubs.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Mes commandes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: AppTypography.labelLarge,
          tabs: [
            Tab(text: 'Commandes (${ordersState.items.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Abonnements actifs'),
                  if (activeSubsCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$activeSubsCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersTab(state: ordersState),
          _ActiveSubsTab(asyncSubs: asyncSubs),
        ],
      ),
    );
  }
}

// ── Onglet Commandes ──────────────────────────────────────────────────────────

class _OrdersTab extends ConsumerWidget {
  final OrdersState state;
  const _OrdersTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const JunaSkeleton(
            width: double.infinity, height: 140, borderRadius: 16),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Aucune commande',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            const Text('Vos commandes apparaîtront ici.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(ordersControllerProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _OrderCard(order: state.items[i]),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfirmed = order.status == OrderStatus.confirmed;

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : nom + statut ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.subscriptionName ?? order.orderNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (order.providerName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            order.providerName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(status: order.status),
                ],
              ),
            ),

            // ── Infos : livraison + réf + date ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        order.deliveryMethod == DeliveryMethod.delivery
                            ? Icons.delivery_dining_outlined
                            : Icons.storefront_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          order.deliveryMethod == DeliveryMethod.delivery
                              ? order.deliveryAddress ??
                                  order.deliveryCity ??
                                  'Livraison'
                              : order.pickupLocation ?? 'Retrait sur place',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(order.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Pied : montant + bouton activer ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatPrice(order.amount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  if (isConfirmed)
                    _ActivateButton(orderId: order.id)
                  else
                    Text(
                      'Voir →',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Fév','Mar','Avr','Mai','Jun',
                    'Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _ActivateButton extends ConsumerStatefulWidget {
  final String orderId;
  const _ActivateButton({required this.orderId});

  @override
  ConsumerState<_ActivateButton> createState() => _ActivateButtonState();
}

class _ActivateButtonState extends ConsumerState<_ActivateButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: _loading ? null : _activate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('Activer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _activate() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(ordersControllerProvider.notifier)
        .activate(widget.orderId);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        // Rafraîchit aussi les abonnements actifs
        ref.invalidate(activeSubscriptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement activé avec succès !'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'activation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      OrderStatus.pending   => ('En attente', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      OrderStatus.confirmed => ('Confirmée',  const Color(0xFFDCFCE7), const Color(0xFF166534)),
      OrderStatus.active    => ('Active',     AppColors.primarySurface, AppColors.primary),
      OrderStatus.completed => ('Terminée',   const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
      OrderStatus.cancelled => ('Annulée',    const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Onglet Abonnements actifs ─────────────────────────────────────────────────

class _ActiveSubsTab extends ConsumerWidget {
  final AsyncValue<List<ActiveSubscriptionEntity>> asyncSubs;
  const _ActiveSubsTab({required this.asyncSubs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncSubs.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, __) => const JunaSkeleton(
            width: double.infinity, height: 240, borderRadius: 20),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.lg),
            Text('Impossible de charger vos abonnements',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => ref.invalidate(activeSubscriptionsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (subs) => subs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(Icons.card_membership_outlined,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Aucun abonnement actif',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Vos abonnements actifs\napparaîtront ici.',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  ref.invalidate(activeSubscriptionsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: subs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (_, i) => _SubscriberCard(sub: subs[i]),
              ),
            ),
    );
  }
}

// ── Carte d'abonné ────────────────────────────────────────────────────────────

class _SubscriberCard extends StatelessWidget {
  final ActiveSubscriptionEntity sub;
  const _SubscriberCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final isExpiring = sub.isExpiringSoon;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpiring ? const Color(0xFFFEF3C7) : AppColors.border,
          width: isExpiring ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête vert ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CARTE D\'ABONNÉ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub.subscriptionName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.providerName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _CardStatusBadge(isExpiring: isExpiring),
              ],
            ),
          ),

          // ── Corps ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(
                      icon: Icons.tag_rounded,
                      label: 'Réf. ${sub.reference}',
                    ),
                    _InfoChip(
                      icon: sub.deliveryMethod == 'DELIVERY'
                          ? Icons.delivery_dining_outlined
                          : Icons.storefront_outlined,
                      label: sub.deliveryMethod == 'DELIVERY'
                          ? sub.deliveryCity ?? 'Livraison'
                          : 'Retrait sur place',
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaBadge(_typeLabel(sub.subscriptionType)),
                    _MetaBadge(_categoryLabel(sub.subscriptionCategory)),
                    _MetaBadge(_durationLabel(sub.duration)),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _DateBlock(label: 'DÉBUT', date: sub.startedAt)),
                    const SizedBox(width: 10),
                    Expanded(child: _DateBlock(label: 'FIN', date: sub.endsAt)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DaysLeftBlock(
                          daysLeft: sub.daysLeft, isExpiring: isExpiring),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progression',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    Text('${(sub.progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: sub.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isExpiring
                          ? const Color(0xFFF59E0B)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String t) => switch (t.toUpperCase()) {
    'BREAKFAST' => 'Petit-déjeuner',
    'DINNER'    => 'Dîner',
    'SNACK'     => 'Collation',
    _           => 'Déjeuner',
  };

  String _categoryLabel(String c) => switch (c.toUpperCase()) {
    'EUROPEAN'   => 'Européen',
    'ASIAN'      => 'Asiatique',
    'VEGETARIAN' => 'Végétarien',
    'HALAL'      => 'Halal',
    'VEGAN'      => 'Végan',
    _            => 'Africain',
  };

  String _durationLabel(String d) => switch (d.toUpperCase()) {
    'DAY'         => '1 jour',
    'THREE_DAYS'  => '3 jours',
    'WEEKEND'     => 'Week-end',
    'WORK_WEEK'   => 'Semaine (L–V)',
    'WORK_WEEK_2' => '2 sem. (L–V)',
    'WEEK'        => '1 semaine',
    'TWO_WEEKS'   => '2 semaines',
    'WORK_MONTH'  => 'Mois (L–V)',
    'MONTH'       => '1 mois',
    _             => d,
  };
}

// ── Widgets partagés ──────────────────────────────────────────────────────────

class _CardStatusBadge extends StatelessWidget {
  final bool isExpiring;
  const _CardStatusBadge({required this.isExpiring});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isExpiring
            ? const Color(0xFFFEF3C7)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isExpiring
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isExpiring ? 'Expire bientôt' : 'Actif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isExpiring ? const Color(0xFF92400E) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  const _MetaBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary)),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String label;
  final DateTime date;
  const _DateBlock({required this.label, required this.date});

  static const _months = ['Jan','Fév','Mar','Avr','Mai','Jun',
                           'Jul','Aoû','Sep','Oct','Nov','Déc'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(
            '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DaysLeftBlock extends StatelessWidget {
  final int daysLeft;
  final bool isExpiring;
  const _DaysLeftBlock({required this.daysLeft, required this.isExpiring});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: isExpiring
            ? const Color(0xFFFFFBEB)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RESTE',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isExpiring
                      ? const Color(0xFFB45309)
                      : AppColors.primary)),
          const SizedBox(height: 4),
          Text('$daysLeft j.',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isExpiring
                      ? const Color(0xFFB45309)
                      : AppColors.primary)),
        ],
      ),
    );
  }
}
