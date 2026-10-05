import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_skeleton.dart';
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
    // La liste (GET /orders/me) sert juste à affichage instantané pendant
    // le chargement — elle ne contient pas certains champs détail-only
    // (ex: le téléphone du prestataire, renvoyé uniquement par
    // GET /orders/:id). On affiche donc toujours la version fraîche de
    // orderByIdProvider une fois disponible, jamais la version en cache
    // seule, pour ne pas perdre ces champs.
    final ordersState = ref.watch(ordersControllerProvider);
    final cached = ordersState.items.where((o) => o.id == orderId).firstOrNull;

    final asyncOrder = ref.watch(orderByIdProvider(orderId));
    return asyncOrder.when(
      loading: () => cached != null
          ? _buildScaffold(context, ref, cached)
          : Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.go('/orders'),
                ),
                title: const JunaSkeleton.line(width: 160, height: 16),
              ),
              body: const SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JunaSkeleton(
                        width: 90, height: 26, borderRadius: AppRadius.full),
                    SizedBox(height: AppSpacing.lg),
                    JunaSkeleton(
                        width: double.infinity,
                        height: 160,
                        borderRadius: AppRadius.lg),
                    SizedBox(height: AppSpacing.md),
                    JunaSkeleton(
                        width: double.infinity,
                        height: 64,
                        borderRadius: AppRadius.lg),
                    SizedBox(height: AppSpacing.md),
                    JunaSkeleton(
                        width: double.infinity,
                        height: 80,
                        borderRadius: AppRadius.lg),
                  ],
                ),
              ),
            ),
      error: (e, _) => cached != null
          ? _buildScaffold(context, ref, cached)
          : Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.go('/orders'),
                ),
              ),
              body: const Center(child: Text('Commande introuvable')),
            ),
      data: (order) => _buildScaffold(context, ref, order),
    );
  }

  Widget _buildScaffold(
      BuildContext context, WidgetRef ref, OrderEntity order) {
    final beninPhone = toBeninE164(order.providerPhone);
    final statusAllowsContact =
        order.status.canActivate || order.status.isActive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/orders'),
        ),
        title: Text(order.subscriptionName ?? 'Détail de la commande'),
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
                  if (order.subscriptionId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    GestureDetector(
                      onTap: () => context
                          .push('/subscriptions/${order.subscriptionId}'),
                      child: Row(
                        children: [
                          const Icon(Icons.open_in_new_rounded,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Voir l\'abonnement',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  const Text('Total', style: AppTypography.bodyMedium),
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
                'Activez dès que vous avez reçu votre premier repas. Cela démarre officiellement votre abonnement à partir de maintenant — le paiement est alors transmis au prestataire.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Contacter le prestataire ────────────────────────────────────
            if (statusAllowsContact && beninPhone != null) ...[
              _Section(
                title: 'Contacter le prestataire',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contactez le prestataire dès maintenant pour '
                      'convenir du démarrage de votre abonnement. Vous '
                      'pouvez appeler directement ou laisser un message '
                      'WhatsApp avec, si possible, une capture de votre '
                      'carte d\'abonné (onglet "Abonnements" de la page '
                      'Commandes).',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ContactButton(
                      icon: Icons.call_rounded,
                      color: AppColors.primary,
                      phoneDisplay: order.providerPhone ?? beninPhone,
                      onPressed: () => _call(context, beninPhone),
                      onCopy: () => _copyPhone(
                          context, order.providerPhone ?? beninPhone),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ContactButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: const Color(0xFF25D366),
                      phoneDisplay: order.providerPhone ?? beninPhone,
                      onPressed: () => _whatsapp(context, order, beninPhone),
                      onCopy: () => _copyPhone(
                          context, order.providerPhone ?? beninPhone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context, String phoneE164) async {
    final uri = Uri.parse('tel:$phoneE164');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application téléphone.')),
      );
    }
  }

  Future<void> _whatsapp(
      BuildContext context, OrderEntity order, String phoneE164) async {
    final digits = phoneE164.replaceFirst('+', '');
    final message = Uri.encodeComponent(
      'Bonjour, je viens de confirmer ma commande ${order.orderNumber} '
      'sur Juna, quand puis-je récupérer mon premier repas ?',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('WhatsApp n\'est pas installé sur cet appareil.')),
      );
    }
  }

  Future<void> _copyPhone(BuildContext context, String phoneDisplay) async {
    await Clipboard.setData(ClipboardData(text: phoneDisplay));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro copié')),
      );
    }
  }

  Future<void> _activate(
      BuildContext context, WidgetRef ref, OrderEntity order) async {
    final confirmed = await showActivationSheet(context, order.deliveryMethod);
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

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String phoneDisplay;
  final VoidCallback onPressed;
  final VoidCallback onCopy;

  const _ContactButton({
    required this.icon,
    required this.color,
    required this.phoneDisplay,
    required this.onPressed,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                phoneDisplay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onCopy,
              child: Icon(Icons.copy_rounded, size: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
