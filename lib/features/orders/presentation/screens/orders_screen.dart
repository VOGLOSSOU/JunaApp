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
import '../../../auth/presentation/controllers/auth_controller.dart';
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

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: AppColors.textLight),
              const SizedBox(height: AppSpacing.lg),
              Text(state.error!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(ordersControllerProvider.notifier).load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
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
    final user = ref.watch(authControllerProvider).user;
    final userName = user?.name ?? '';
    final userEmail = user?.email ?? '';

    return asyncSubs.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, __) => const JunaSkeleton(
            width: double.infinity, height: 200, borderRadius: 16),
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
                      borderRadius: BorderRadius.circular(AppRadius.full),
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
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(activeSubscriptionsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: subs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (_, i) => _SubscriberCard(
                  sub: subs[i],
                  userName: userName,
                  userEmail: userEmail,
                ),
              ),
            ),
    );
  }
}

// ── Carte d'abonné ────────────────────────────────────────────────────────────

// Couleurs carte (spec design)
const _kGreen       = Color(0xFF1A5C2A);
const _kGreen2      = Color(0xFF2D7A3A);
const _kOrange      = Color(0xFFF97316);
const _kOrangeLight = Color(0xFFFB923C);
const _kSepColor    = Color(0x1A1A5C2A);   // rgba(26,92,42,0.10)
const _kAvatarBg    = Color(0x1F1A5C2A);   // rgba(26,92,42,0.12)
const _kChipBg      = Color(0x1A1A5C2A);   // rgba(26,92,42,0.10)
const _kTextMain    = Color(0xFF1C1C1C);
const _kTextSub     = Color(0xFF757575);
const _kTextLabel   = Color(0xFF9E9E9E);

const _kFullMonths = [
  'janvier','février','mars','avril','mai','juin',
  'juillet','août','septembre','octobre','novembre','décembre',
];

String _cardDateFmt(DateTime d) => '${d.day} ${_kFullMonths[d.month - 1]} ${d.year}';

String _initials(String name) {
  final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words[0][0].toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

String _typeLbl(String t) => switch (t.toUpperCase()) {
  'BREAKFAST' => 'Petit-déjeuner',
  'DINNER'    => 'Dîner',
  'SNACK'     => 'Collation',
  _           => 'Déjeuner',
};

String _durLbl(String d) => switch (d.toUpperCase()) {
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

class _SubscriberCard extends StatelessWidget {
  final ActiveSubscriptionEntity sub;
  final String userName;
  final String userEmail;
  const _SubscriberCard({
    required this.sub,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final exp = sub.isExpiringSoon;
    final pct = sub.progress;
    final initials = _initials(userName.isNotEmpty ? userName : 'U');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1A5C2A),
            blurRadius: 32,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x121A5C2A), Color(0x211A5C2A)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              children: [
                // ── Zone 1 : Header ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo_green_orange.png',
                      width: 56,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: exp
                                ? _kOrangeLight
                                : const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exp ? 'EXPIRE BIENTÔT' : 'ACTIF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: exp ? _kOrange : _kGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                const Divider(color: _kSepColor, height: 1, thickness: 1),
                const SizedBox(height: 6),

                // ── Zone 2 : Corps ───────────────────────────────────
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Colonne gauche 62%
                      Expanded(
                        flex: 62,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bloc abonné
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kAvatarBg,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('ABONNÉ',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: _kTextLabel,
                                              letterSpacing: 0.8)),
                                      Text(
                                        userName.isNotEmpty
                                            ? userName
                                            : 'Abonné',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _kTextMain),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (userEmail.isNotEmpty)
                                        Text(
                                          userEmail,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: _kTextSub),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // Bloc abonnement
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ABONNEMENT',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextLabel,
                                        letterSpacing: 0.8)),
                                const SizedBox(height: 1),
                                Text(
                                  sub.subscriptionName,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _kTextMain),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    _CardChip(_durLbl(sub.duration)),
                                    const SizedBox(width: 4),
                                    _CardChip(_typeLbl(sub.subscriptionType)),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // Bloc fournisseur
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FOURNISSEUR',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextLabel,
                                        letterSpacing: 0.8)),
                                const SizedBox(height: 1),
                                Text(
                                  sub.providerName,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _kTextMain),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Séparateur vertical
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: VerticalDivider(
                            color: _kSepColor, width: 1, thickness: 1),
                      ),

                      // Colonne droite 38%
                      Expanded(
                        flex: 38,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Début
                            _CardDateBloc(
                                label: 'DÉBUT', date: sub.startedAt),
                            const SizedBox(height: 5),
                            // Fin
                            _CardDateBloc(label: 'FIN', date: sub.endsAt),

                            const Spacer(),

                            // Réf.
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('RÉF.',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextLabel,
                                        letterSpacing: 0.8)),
                                const SizedBox(height: 1),
                                Text(
                                  sub.reference,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: _kTextSub,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            // ✓ JUNA
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '✓ JUNA',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _kGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
                const Divider(color: _kSepColor, height: 1, thickness: 1),
                const SizedBox(height: 5),

                // ── Zone 3 : Barre de progression ────────────────────
                LayoutBuilder(builder: (_, constraints) {
                  final filled = constraints.maxWidth * pct;
                  return Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: _kChipBg,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          Container(
                            height: 5,
                            width: filled,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: LinearGradient(
                                colors: exp
                                    ? [_kOrange, _kOrangeLight]
                                    : [_kGreen, _kGreen2],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(pct * 100).round()}% écoulé',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kTextLabel),
                          ),
                          Text(
                            sub.daysLeft == 0
                                ? 'Expire aujourd\'hui'
                                : '${sub.daysLeft}j restants',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: exp ? _kOrange : _kGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final String label;
  const _CardChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _kGreen,
        ),
      ),
    );
  }
}

class _CardDateBloc extends StatelessWidget {
  final String label;
  final DateTime date;
  const _CardDateBloc({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kTextLabel,
                letterSpacing: 0.8)),
        const SizedBox(height: 1),
        Text(
          _cardDateFmt(date),
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _kTextMain),
        ),
      ],
    );
  }
}
