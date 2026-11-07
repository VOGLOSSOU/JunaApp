import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/api/current_account.dart';
import '../../../../core/utils/enums.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/mobile_money.dart';
import 'checkout_screen.dart';

// Données passées depuis MobileMoneyScreen
class PaymentProcessingExtra {
  final String orderId;
  final String? paymentId;
  final String phoneNumber;
  final double amount;
  final String subscriptionName;
  final String subscriptionImageUrl;
  final String paymentMethod;

  const PaymentProcessingExtra({
    required this.orderId,
    required this.paymentId,
    required this.phoneNumber,
    required this.amount,
    required this.subscriptionName,
    required this.subscriptionImageUrl,
    required this.paymentMethod,
  });
}

// Données passées à l'écran d'échec
class PaymentFailedExtra {
  final String orderId;
  final String phoneNumber;
  final String paymentMethod;
  final double amount;
  final String subscriptionName;
  final String subscriptionImageUrl;
  final String errorMessage;

  const PaymentFailedExtra({
    required this.orderId,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.amount,
    required this.subscriptionName,
    required this.subscriptionImageUrl,
    required this.errorMessage,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1A5C2A);
const _kPageBg = Color(0xFFF5F5F5);
const _kTextMain = Color(0xFF1C1C1C);
const _kTextSub = Color(0xFF757575);

const _pollInterval = Duration(seconds: 5);
const _maxWait = Duration(minutes: 3);

const _kDefaultFailureMessage =
    'Le paiement a échoué. Vérifiez votre solde et que le réseau choisi correspond bien à votre numéro, puis réessayez.';

/// Paiement confirmé : rafraîchit les commandes puis ouvre la commande payée.
/// Utilisé après le polling, et directement après l'initiation quand
/// l'opérateur (Moov) confirme le paiement sans étape de validation.
Future<void> openPaidOrder(
  BuildContext context,
  WidgetRef ref,
  String orderId,
) async {
  final account = ref.read(currentAccountIdProvider);
  ref.invalidate(orderByIdProvider(orderId));
  try {
    await ref.read(ordersControllerProvider.notifier).load(forceRefresh: true);
  } catch (_) {
    // La commande s'affichera quand même ; la liste se rechargera plus tard.
  }
  if (!context.mounted || ref.read(currentAccountIdProvider) != account) return;
  context.go('/orders/$orderId');
}

/// Paiement refusé : remplace l'écran courant par l'écran d'échec.
void showPaymentFailed(BuildContext context, PaymentFailedExtra extra) {
  context.pushReplacement('/checkout/failed', extra: extra);
}

// ─────────────────────────────────────────────────────────────────────────────

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final PaymentProcessingExtra extra;
  const PaymentProcessingScreen({super.key, required this.extra});

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen> with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _waitTimer;
  String? _paymentId;
  String? _account;
  bool _checking = false;
  bool _delayed = false;
  bool _finished = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _paymentId = widget.extra.paymentId;
    _account = ref.read(currentAccountIdProvider);
    _waitTimer = Timer(_maxWait, () {
      if (!mounted || _finished) return;
      _timer?.cancel();
      setState(() => _delayed = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _poll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waitTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _timer?.cancel();
    } else if (!_finished) {
      _poll();
    }
  }

  bool get _canContinue =>
      mounted && !_finished && ref.read(currentAccountIdProvider) == _account;

  void _finish() {
    _finished = true;
    _timer?.cancel();
    _waitTimer?.cancel();
  }

  Future<void> _poll() async {
    if (!_canContinue || _checking || _paused) return;
    _timer?.cancel();
    setState(() => _checking = true);
    try {
      // After an uncertain initiation, recover the payment from the server.
      // Never send another collection request from this screen.
      if (_paymentId == null) {
        final order = await ref
            .read(orderRepositoryProvider)
            .getOrderById(widget.extra.orderId);
        if (!mounted || !_canContinue) return;
        if (order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.active ||
            order.status == OrderStatus.completed) {
          _finish();
          await openPaidOrder(context, ref, order.id);
          return;
        }
        if (order.status == OrderStatus.cancelled) {
          _finish();
          context.go('/orders/${order.id}');
          return;
        }
        _paymentId = order.payment?.id;
      }
      final id = _paymentId;
      if (id == null) return;
      final result =
          await ref.read(paymentRepositoryProvider).getPaymentStatus(id);
      if (!mounted || !_canContinue) return;
      switch (PaymentOutcome.parse(result.status)) {
        case PaymentOutcome.success:
          _finish();
          await openPaidOrder(context, ref, widget.extra.orderId);
        case PaymentOutcome.failed:
          _finish();
          final e = widget.extra;
          showPaymentFailed(
              context,
              PaymentFailedExtra(
                orderId: e.orderId,
                phoneNumber: e.phoneNumber,
                paymentMethod: e.paymentMethod,
                amount: result.amount,
                subscriptionName: e.subscriptionName,
                subscriptionImageUrl: e.subscriptionImageUrl,
                errorMessage: _kDefaultFailureMessage,
              ));
        case PaymentOutcome.processing:
          break;
      }
    } catch (_) {
      // A network error cannot turn an uncertain payment into a failure.
    } finally {
      if (mounted) setState(() => _checking = false);
      if (_canContinue && !_paused && !_delayed) {
        _timer = Timer(_pollInterval, _poll);
      }
    }
  }

  void _viewOrders() {
    _finish();
    ref.read(ordersControllerProvider.notifier).load(forceRefresh: true);
    context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentAccountIdProvider, (previous, next) {
      if (next != _account) {
        _finish();
        context.go('/orders');
      }
    });
    final e = widget.extra;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kPageBg,
        body: SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(children: [
            Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0x141A5C2A)),
                child: _delayed && !_checking
                    ? const Icon(Icons.schedule_rounded,
                        size: 36, color: _kGreen)
                    : const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: _kGreen))),
            const SizedBox(height: 28),
            Text(
                _delayed
                    ? 'Confirmation en attente'
                    : 'Vérification du paiement',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _kTextMain)),
            const SizedBox(height: 12),
            Text(
                _delayed
                    ? "Le paiement n'est pas encore confirmé. Il peut toujours être en cours. Ne lancez pas un nouveau paiement. Vous pouvez vérifier son état ou revenir dans vos commandes."
                    : "Si une demande apparaît sur votre téléphone, validez-la avec votre code PIN Mobile Money. Nous vérifions la confirmation de votre paiement.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: _kTextSub, height: 1.6)),
            const SizedBox(height: 32),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  const Text('Montant du paiement',
                      style: TextStyle(fontSize: 12, color: _kTextSub)),
                  const SizedBox(height: 4),
                  Text(formatPrice(e.amount),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kGreen)),
                  if (e.phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('+${e.phoneNumber}',
                        style: const TextStyle(fontSize: 12, color: _kTextSub)),
                  ],
                ])),
            const SizedBox(height: 32),
            if (_delayed) ...[
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _checking ? null : _poll,
                      child: Text(_checking
                          ? 'Vérification en cours...'
                          : 'Vérifier le paiement'))),
              const SizedBox(height: 12),
            ],
            TextButton(
                onPressed: _viewOrders,
                child: const Text('Voir mes commandes')),
          ]),
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Écran 4 — Échec du paiement
// ─────────────────────────────────────────────────────────────────────────────

const _kRed = Color(0xFFEF4444);
const _kRedBg = Color(0xFFFEF2F2);
const _kBorder = Color(0xFFE5E7EB);

class PaymentFailedScreen extends ConsumerWidget {
  final PaymentFailedExtra extra;
  const PaymentFailedScreen({super.key, required this.extra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône erreur
              Container(
                width: 80,
                height: 80,
                decoration:
                    const BoxDecoration(shape: BoxShape.circle, color: _kRedBg),
                child: const Icon(Icons.close_rounded, size: 36, color: _kRed),
              ),

              const SizedBox(height: 28),

              const Text('Paiement échoué',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kTextMain)),

              const SizedBox(height: 12),

              Text(
                extra.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: _kTextSub, height: 1.5),
              ),

              const SizedBox(height: 40),

              // Bouton Réessayer
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.pushReplacement(
                      '/checkout/mobile-money',
                      extra: CheckoutMobileExtra(
                        orderId: extra.orderId,
                        amount: extra.amount,
                        subscriptionName: extra.subscriptionName,
                        subscriptionImageUrl: extra.subscriptionImageUrl,
                        paymentMethod: extra.paymentMethod,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Réessayer',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 12),

              // Bouton Voir commandes
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go('/orders'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kTextMain,
                    side: const BorderSide(color: _kBorder, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Voir mes commandes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
