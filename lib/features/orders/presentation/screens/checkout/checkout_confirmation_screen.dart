import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/widgets/juna_button.dart';
import '../../controllers/orders_controller.dart';

class CheckoutConfirmationScreen extends ConsumerWidget {
  final String orderId;
  const CheckoutConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersControllerProvider);
    final orders = ordersState.items;
    final order = orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => orders.first,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Animation succès
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text(
                'Commande confirmée !',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                order.subscription?.title ?? order.orderNumber,
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                order.subscription != null
                    ? '${order.subscription!.provider.name} · ${order.subscription!.type.label}'
                    : '',
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // QR Code
              Text('Votre ticket', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                    ),
                  ],
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
              const SizedBox(height: AppSpacing.md),
              Text(
                'Présentez ce QR code au prestataire\npour validation',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Boutons
              JunaButton(
                label: 'Voir mes commandes',
                variant: JunaButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.orders),
              ),
              const SizedBox(height: AppSpacing.md),
              JunaButton(
                label: 'Retour à l\'accueil',
                variant: JunaButtonVariant.outline,
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
