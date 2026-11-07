import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/current_account.dart';
import '../../../../core/utils/enums.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../screens/checkout_screen.dart';
import '../screens/payment_processing_screen.dart';

class OrderPaymentButton extends ConsumerStatefulWidget {
  final OrderEntity order;
  final bool compact;
  const OrderPaymentButton(
      {super.key, required this.order, this.compact = false});
  @override
  ConsumerState<OrderPaymentButton> createState() => _OrderPaymentButtonState();
}

class _OrderPaymentButtonState extends ConsumerState<OrderPaymentButton> {
  bool _loading = false;
  Future<void> _open() async {
    if (_loading) return;
    final account = ref.read(currentAccountIdProvider);
    setState(() => _loading = true);
    try {
      final order =
          await ref.read(orderRepositoryProvider).getOrderById(widget.order.id);
      if (!mounted || ref.read(currentAccountIdProvider) != account) return;
      ref.invalidate(orderByIdProvider(order.id));
      if (!order.status.isPending) {
        ref.read(ordersControllerProvider.notifier).load(forceRefresh: true);
        if (GoRouterState.of(context).uri.path != '/orders/${order.id}') {
          context.push('/orders/${order.id}');
        }
        return;
      }
      final payment = order.payment;
      if (payment != null && !payment.isFailed) {
        await context.push('/checkout/processing',
            extra: PaymentProcessingExtra(
              orderId: order.id,
              paymentId: payment.id,
              phoneNumber: '',
              amount: order.amount,
              subscriptionName: order.subscriptionName ?? order.orderNumber,
              subscriptionImageUrl: '',
              paymentMethod: payment.method ?? 'MOBILE_MONEY',
            ));
      } else {
        await context.push('/checkout/mobile-money',
            extra: CheckoutMobileExtra(
              orderId: order.id,
              amount: order.amount,
              subscriptionName: order.subscriptionName ?? order.orderNumber,
              subscriptionInstructions: order.subscriptionInstructions,
              subscriptionImageUrl: '',
              paymentMethod: payment?.method ?? 'MOBILE_MONEY',
            ));
      }
      if (mounted && ref.read(currentAccountIdProvider) == account) {
        ref.invalidate(orderByIdProvider(order.id));
        ref.read(ordersControllerProvider.notifier).load(forceRefresh: true);
      }
    } catch (_) {
      if (mounted && ref.read(currentAccountIdProvider) == account) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Impossible de vérifier cette commande. Réessayez la vérification dans quelques instants.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checking =
        widget.order.payment != null && !widget.order.payment!.isFailed;
    return SizedBox(
      height: widget.compact ? 36 : 52,
      width: widget.compact ? null : double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _open,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4521E),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                checking
                    ? 'Vérifier le paiement'
                    : widget.compact
                        ? 'Payer'
                        : 'Payer maintenant',
                style: TextStyle(
                    fontSize: widget.compact ? 12 : 15,
                    fontWeight: FontWeight.w600)),
      ),
    );
  }
}
