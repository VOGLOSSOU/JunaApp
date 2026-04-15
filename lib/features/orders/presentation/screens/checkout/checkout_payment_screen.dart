import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/juna_button.dart';
import '../../controllers/orders_controller.dart';
import '../../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../widgets/checkout_step_indicator.dart';

class CheckoutPaymentScreen extends ConsumerStatefulWidget {
  const CheckoutPaymentScreen({super.key});

  @override
  ConsumerState<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState
    extends ConsumerState<CheckoutPaymentScreen> {
  PaymentMethod? _method;
  final _phoneCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _needsPhone =>
      _method != null &&
      _method != PaymentMethod.card &&
      _method != PaymentMethod.cash;

  Future<void> _confirm() async {
    setState(() => _isProcessing = true);

    final checkout = ref.read(checkoutControllerProvider);
    ref.read(checkoutControllerProvider.notifier).setPaymentMethod(_method!);

    // Map PaymentMethod enum to API string
    String apiPaymentMethod;
    switch (_method!) {
      case PaymentMethod.wave:        apiPaymentMethod = 'MOBILE_MONEY_WAVE'; break;
      case PaymentMethod.mtnMoney:    apiPaymentMethod = 'MOBILE_MONEY_MTN'; break;
      case PaymentMethod.moovMoney:   apiPaymentMethod = 'MOBILE_MONEY_MOOV'; break;
      case PaymentMethod.orangeMoney: apiPaymentMethod = 'MOBILE_MONEY_ORANGE'; break;
      case PaymentMethod.card:        apiPaymentMethod = 'CARD'; break;
      case PaymentMethod.cash:        apiPaymentMethod = 'CASH'; break;
    }

    final deliveryMethodStr = checkout.deliveryMethod == DeliveryMethod.delivery
        ? 'DELIVERY'
        : 'PICKUP';

    final success = await ref.read(ordersControllerProvider.notifier).createOrder(
      subscriptionId: checkout.subscriptionId!,
      deliveryMethod: deliveryMethodStr,
      deliveryAddress: checkout.deliveryLocation,
      landmarkId: checkout.landmarkId,
      paymentMethod: apiPaymentMethod,
    );

    if (!mounted) return;

    if (success) {
      final orderId = ref.read(ordersControllerProvider).items.first.id;
      ref.read(checkoutControllerProvider.notifier).reset();
      context.go('${AppRoutes.checkoutConfirm}?orderId=$orderId');
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(ordersControllerProvider).error ?? 'Erreur lors de la commande'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final allSubs = ref.watch(subscriptionsControllerProvider).items;
    final sub = allSubs.isNotEmpty
        ? allSubs.firstWhere(
            (s) => s.id == checkout.subscriptionId,
            orElse: () => allSubs.first,
          )
        : null;
    final total = (sub?.price ?? 0) +
        (checkout.deliveryMethod == DeliveryMethod.delivery ? 1000.0 : 0.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Moyen de paiement'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: CheckoutStepIndicator(current: 3),
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
                    Text('Choisissez votre moyen de paiement',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xl),

                    // Liste méthodes
                    ...PaymentMethod.values.map((m) => GestureDetector(
                          onTap: () => setState(() => _method = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: _method == m
                                  ? AppColors.primarySurface
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: _method == m
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: _method == m ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(m.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(m.label,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: _method == m
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      )),
                                ),
                                Radio<PaymentMethod>(
                                  value: m,
                                  groupValue: _method,
                                  onChanged: (v) =>
                                      setState(() => _method = v),
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        )),

                    // Champ numéro si Mobile Money
                    if (_needsPhone) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text('Numéro de téléphone',
                          style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '+229 97 00 00 00',
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: AppColors.textLight),
                        ),
                      ),
                    ],

                    // Note espèces
                    if (_method == PaymentMethod.cash) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.warning, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Le paiement s\'effectue au moment de la livraison ou du retrait.',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Total + bouton confirmer
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total à payer',
                          style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary)),
                      Text(
                        formatPrice(total),
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  JunaButton(
                    label: 'Confirmer et payer',
                    isLoading: _isProcessing,
                    onPressed: _method != null ? _confirm : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
