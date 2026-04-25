import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_badge.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart'
    show CheckoutMobileExtra;
import '../../domain/entities/order_entity.dart';
import '../controllers/orders_controller.dart';
import 'orders_screen.dart' show showActivationSheet;

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cherche d'abord dans le cache, sinon fetch directement par ID
    final ordersState = ref.watch(ordersControllerProvider);
    final cached = ordersState.items.where((o) => o.id == orderId).firstOrNull;

    if (cached != null) {
      return _buildScaffold(context, ref, cached);
    }

    // Fallback : fetch direct (ex: redirection post-paiement)
    final asyncOrder = ref.watch(orderByIdProvider(orderId));
    return asyncOrder.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/orders'))),
        body: const Center(child: Text('Commande introuvable')),
      ),
      data: (order) => _buildScaffold(context, ref, order),
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, OrderEntity order) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/orders'),
        ),
        title: Text(order.orderNumber),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Statut ──────────────────────────────────────────────────────
            JunaBadge.orderStatus(order.status),
            const SizedBox(height: AppSpacing.lg),

            // ── Infos abonnement ─────────────────────────────────────────────
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.subscriptionName ?? order.orderNumber,
                      style: AppTypography.titleLarge),
                  if (order.providerName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('par ${order.providerName}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(
                    icon: order.deliveryMethod == DeliveryMethod.delivery
                        ? Icons.delivery_dining_outlined
                        : Icons.store_outlined,
                    text: order.deliveryMethod == DeliveryMethod.delivery
                        ? 'Livraison — ${order.deliveryAddress ?? ""}'
                            '${order.deliveryCity != null ? ", ${order.deliveryCity}" : ""}'
                        : 'Retrait — ${order.pickupLocation ?? "Adresse du prestataire"}',
                  ),
                  if (order.scheduledFor != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      text: 'Prévu le ${formatDate(order.scheduledFor!)}',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    text: 'Passée le ${formatDate(order.createdAt)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Montant ──────────────────────────────────────────────────────
            _Section(
              title: 'Montant',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTypography.bodyMedium),
                  Text(
                    formatPrice(order.amount),
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),


            // ── Payer ─────────────────────────────────────────────────────────
            if (order.status.isPending) ...[
              JunaButton(
                label: 'Payer maintenant',
                icon: Icons.payment_outlined,
                onPressed: () => context.push(
                  '/checkout/mobile-money',
                  extra: CheckoutMobileExtra(
                    orderId: order.id,
                    amount: order.amount,
                    subscriptionName:
                        order.subscriptionName ?? order.orderNumber,
                    subscriptionImageUrl: '',
                    paymentMethod: 'MOBILE_MONEY',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Votre commande est en attente de paiement. Réglez-la maintenant pour qu\'elle soit confirmée.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Activer ──────────────────────────────────────────────────────
            if (order.status.canActivate) ...[
              JunaButton(
                label: 'Activer mon abonnement',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => _activate(context, ref, order),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Activez votre abonnement une fois que vous avez reçu ou récupéré votre première commande.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _activate(
      BuildContext context, WidgetRef ref, OrderEntity order) async {
    final confirmed =
        await showActivationSheet(context, order.deliveryMethod);
    if (confirmed != true) return;
    final ok =
        await ref.read(ordersControllerProvider.notifier).activate(order.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Abonnement activé avec succès !'
            : 'Erreur lors de l\'activation'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }

}

class _Section extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Section({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.bodyMedium)),
      ],
    );
  }
}
