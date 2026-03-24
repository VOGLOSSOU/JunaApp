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
import '../../../../orders/domain/entities/order_entity.dart';
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
    await Future.delayed(const Duration(seconds: 2)); // simule paiement

    final checkout = ref.read(checkoutControllerProvider);
    ref.read(checkoutControllerProvider.notifier).setPaymentMethod(_method!);

    final sub = MockData.subscriptions.firstWhere(
      (s) => s.id == checkout.subscriptionId,
      orElse: () => MockData.subscriptions.first,
    );
    final deliveryFee =
        checkout.deliveryMethod == DeliveryMethod.delivery ? 1000.0 : 0.0;

    final order = OrderEntity(
      id: 'o_new_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: 'JUN-${(100 + MockData.orders.length).toString().padLeft(5, "0")}',
      subscription: sub,
      status: OrderStatus.confirmed,
      deliveryMethod: checkout.deliveryMethod!,
      deliveryLocation: checkout.deliveryLocation!,
      totalAmount: sub.price + deliveryFee,
      deliveryFee: deliveryFee,
      paymentMethod: _method!,
      createdAt: DateTime.now(),
    );

    ref.read(ordersControllerProvider.notifier).addOrder(order);
    ref.read(checkoutControllerProvider.notifier).reset();

    if (mounted) {
      context.go('${AppRoutes.checkoutConfirm}?orderId=${order.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final sub = MockData.subscriptions.firstWhere(
      (s) => s.id == checkout.subscriptionId,
      orElse: () => MockData.subscriptions.first,
    );
    final total = sub.price +
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
