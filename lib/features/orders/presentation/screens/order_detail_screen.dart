import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_badge.dart';
import '../../../../core/widgets/juna_button.dart';
import '../controllers/orders_controller.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    final order = orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => orders.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Commande #${order.orderNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            JunaBadge.orderStatus(order.status),
            const SizedBox(height: AppSpacing.lg),

            // Infos commande
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.subscription.title, style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        'par ${order.subscription.provider.name}',
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary),
                      ),
                      if (order.subscription.provider.isVerified) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified, color: Colors.blue, size: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(
                    icon: Icons.restaurant_outlined,
                    text: '${order.subscription.type.label} · ${order.subscription.duration.label}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: order.deliveryMethod == DeliveryMethod.delivery
                        ? Icons.delivery_dining_outlined
                        : Icons.store_outlined,
                    text: order.deliveryMethod == DeliveryMethod.delivery
                        ? 'Livraison — ${order.deliveryLocation}'
                        : 'Retrait — ${order.deliveryLocation}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    text: 'Passée le ${formatDate(order.createdAt)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Prix
            _Section(
              title: 'Montant payé',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTypography.bodyMedium),
                      Text(
                        formatPrice(order.totalAmount),
                        style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payé via',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary)),
                      Text(
                        order.paymentMethod.label,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // QR Code — uniquement si commande active
            if (order.status != OrderStatus.cancelled) ...[
              _Section(
                title: '🎫 Votre ticket',
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: QrImageView(
                          data: 'JUNA:${order.orderNumber}:${order.id}',
                          version: QrVersions.auto,
                          size: 180,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primaryDark,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Présentez ce code au prestataire pour validation',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Bouton laisser avis si complétée
            if (order.status == OrderStatus.completed)
              JunaButton(
                label: 'Laisser un avis',
                variant: JunaButtonVariant.outline,
                icon: Icons.star_outline_rounded,
                onPressed: () {},
              ),

            // Bouton annuler si en attente ou confirmée
            if (order.status == OrderStatus.pending ||
                order.status == OrderStatus.confirmed) ...[
              const SizedBox(height: AppSpacing.md),
              JunaButton(
                label: 'Annuler la commande',
                variant: JunaButtonVariant.danger,
                onPressed: () {},
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
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
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: AppTypography.bodyMedium),
        ),
      ],
    );
  }
}
