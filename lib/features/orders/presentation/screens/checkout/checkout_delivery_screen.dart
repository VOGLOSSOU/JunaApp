import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../../../core/widgets/juna_button.dart';
import '../../controllers/orders_controller.dart';
import '../../widgets/checkout_step_indicator.dart';

class CheckoutDeliveryScreen extends ConsumerStatefulWidget {
  final String subscriptionId;
  const CheckoutDeliveryScreen({super.key, required this.subscriptionId});

  @override
  ConsumerState<CheckoutDeliveryScreen> createState() =>
      _CheckoutDeliveryScreenState();
}

class _CheckoutDeliveryScreenState
    extends ConsumerState<CheckoutDeliveryScreen> {
  DeliveryMethod? _method;
  String? _selectedLocation;

  late final sub = MockData.subscriptions.firstWhere(
    (s) => s.id == widget.subscriptionId,
    orElse: () => MockData.subscriptions.first,
  );

  @override
  Widget build(BuildContext context) {
    final locations = _method == DeliveryMethod.delivery
        ? sub.deliveryZones
        : sub.pickupPoints;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mode de réception'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: CheckoutStepIndicator(current: 1),
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
                    Text(
                      'Comment recevoir votre commande ?',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Livraison
                    _MethodCard(
                      icon: '🛵',
                      title: 'Livraison à domicile',
                      subtitle: 'Livré directement à votre adresse',
                      isSelected: _method == DeliveryMethod.delivery,
                      onTap: () => setState(() {
                        _method = DeliveryMethod.delivery;
                        _selectedLocation = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Retrait
                    _MethodCard(
                      icon: '🏠',
                      title: 'Retrait sur place',
                      subtitle: 'Venir chercher chez le prestataire',
                      isSelected: _method == DeliveryMethod.pickup,
                      onTap: () => setState(() {
                        _method = DeliveryMethod.pickup;
                        _selectedLocation = null;
                      }),
                    ),

                    // Lieux disponibles
                    if (_method != null && locations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        _method == DeliveryMethod.delivery
                            ? 'Zones disponibles'
                            : 'Points de retrait',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...locations.map((loc) => GestureDetector(
                            onTap: () =>
                                setState(() => _selectedLocation = loc),
                            child: Container(
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: _selectedLocation == loc
                                    ? AppColors.primarySurface
                                    : AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _selectedLocation == loc
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: _selectedLocation == loc ? 1.5 : 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _method == DeliveryMethod.delivery
                                        ? Icons.location_on_outlined
                                        : Icons.store_outlined,
                                    color: _selectedLocation == loc
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      loc,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: _selectedLocation == loc
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: _selectedLocation == loc
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (_selectedLocation == loc)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 20),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),

            // Bouton continuer
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: JunaButton(
                label: 'Continuer',
                variant: JunaButtonVariant.secondary,
                onPressed: _method != null && _selectedLocation != null
                    ? () {
                        ref
                            .read(checkoutControllerProvider.notifier)
                          ..setSubscription(widget.subscriptionId)
                          ..setDelivery(_method!, _selectedLocation!);
                        context.push(AppRoutes.checkoutRecap);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primarySurface : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

