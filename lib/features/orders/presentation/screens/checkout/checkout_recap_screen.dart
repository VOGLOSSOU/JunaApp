import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../../../core/widgets/juna_button.dart';
import '../../controllers/orders_controller.dart';
import '../../widgets/checkout_step_indicator.dart';

class CheckoutRecapScreen extends ConsumerWidget {
  const CheckoutRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutControllerProvider);
    final sub = MockData.subscriptions.firstWhere(
      (s) => s.id == checkout.subscriptionId,
      orElse: () => MockData.subscriptions.first,
    );
    final deliveryFee =
        checkout.deliveryMethod == DeliveryMethod.delivery ? 1000.0 : 0.0;
    final total = sub.price + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Récapitulatif'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: CheckoutStepIndicator(current: 2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Abonnement
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined,
                              color: AppColors.primary, size: 24),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sub.title,
                                    style: AppTypography.titleMedium),
                                Text(
                                  'par ${sub.provider.name}',
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (sub.provider.isVerified)
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 16),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Détails
                    _DetailRow(
                      icon: Icons.restaurant_outlined,
                      label: sub.type.label,
                      sublabel: sub.duration.label,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      icon: checkout.deliveryMethod == DeliveryMethod.delivery
                          ? Icons.delivery_dining_outlined
                          : Icons.store_outlined,
                      label: checkout.deliveryMethod == DeliveryMethod.delivery
                          ? 'Livraison'
                          : 'Retrait sur place',
                      sublabel: checkout.deliveryLocation ?? '',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Début',
                      sublabel: 'Dès demain',
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),

                    // Prix
                    Text('Détail du prix', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _PriceRow(
                        label: 'Abonnement', amount: sub.price),
                    if (deliveryFee > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PriceRow(
                          label: 'Frais de livraison', amount: deliveryFee),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700)),
                        Text(
                          formatPrice(total),
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: JunaButton(
                label: 'Choisir le paiement',
                onPressed: () => context.push(AppRoutes.checkoutPayment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelLarge),
            Text(sublabel,
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;

  const _PriceRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary)),
        Text(formatPrice(amount), style: AppTypography.bodyMedium),
      ],
    );
  }
}
