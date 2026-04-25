import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../data/repositories/payment_repository.dart';
import 'checkout_screen.dart';

// Données passées depuis MobileMoneyScreen
class PaymentProcessingExtra {
  final String orderId;
  final String paymentId;
  final String phoneNumber;
  final double amount;
  final String subscriptionName;
  final String subscriptionImageUrl;
  final String paymentMethod;
  final String countryCode;

  const PaymentProcessingExtra({
    required this.orderId,
    required this.paymentId,
    required this.phoneNumber,
    required this.amount,
    required this.subscriptionName,
    required this.subscriptionImageUrl,
    required this.paymentMethod,
    required this.countryCode,
  });
}

// Données passées à l'écran d'échec
class PaymentFailedExtra {
  final String orderId;
  final String phoneNumber;
  final String countryCode;
  final String paymentMethod;
  final double amount;
  final String subscriptionName;
  final String subscriptionImageUrl;
  final String errorMessage;

  const PaymentFailedExtra({
    required this.orderId,
    required this.phoneNumber,
    required this.countryCode,
    required this.paymentMethod,
    required this.amount,
    required this.subscriptionName,
    required this.subscriptionImageUrl,
    required this.errorMessage,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
const _kGreen   = Color(0xFF1A5C2A);
const _kPageBg  = Color(0xFFF5F5F5);
const _kTextMain = Color(0xFF1C1C1C);
const _kTextSub  = Color(0xFF757575);

const _pollInterval = Duration(seconds: 5);
const _maxWait      = Duration(minutes: 3);

// ─────────────────────────────────────────────────────────────────────────────

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final PaymentProcessingExtra extra;
  const PaymentProcessingScreen({super.key, required this.extra});

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen> {
  Timer? _timer;
  final _start = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    // Timeout check
    if (DateTime.now().difference(_start) >= _maxWait) {
      _timer?.cancel();
      _goFailed(
        'Le paiement prend plus de temps que prévu. Vérifiez votre historique de transactions.',
      );
      return;
    }

    try {
      final result = await ref
          .read(paymentRepositoryProvider)
          .getPaymentStatus(widget.extra.paymentId);

      if (!mounted) return;

      switch (result.status) {
        case 'SUCCESS':
          _timer?.cancel();
          // Rafraîchit la liste des commandes avant de naviguer
          await ref.read(ordersControllerProvider.notifier).load();
          if (!mounted) return;
          context.go('/orders/${widget.extra.orderId}');
        case 'FAILED':
          _timer?.cancel();
          _goFailed('Le paiement a échoué. Vérifiez votre solde et réessayez.');
        default:
          break; // PROCESSING → continuer
      }
    } catch (_) {
      // Erreur réseau → ignorer, retenter au prochain tick
    }
  }

  void _goFailed(String message) {
    if (!mounted) return;
    final e = widget.extra;
    context.pushReplacement(
      '/checkout/failed',
      extra: PaymentFailedExtra(
        orderId:              e.orderId,
        phoneNumber:          e.phoneNumber,
        countryCode:          e.countryCode,
        paymentMethod:        e.paymentMethod,
        amount:               e.amount,
        subscriptionName:     e.subscriptionName,
        subscriptionImageUrl: e.subscriptionImageUrl,
        errorMessage:         message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.extra;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kPageBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spinner
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x141A5C2A),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: _kGreen),
                  ),
                ),

                const SizedBox(height: 28),

                const Text('Validation en cours…',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _kTextMain)),

                const SizedBox(height: 12),

                const Text(
                  'Une demande de confirmation a été envoyée sur votre téléphone.\nSaisissez votre code PIN Mobile Money pour valider le paiement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: _kTextSub, height: 1.6),
                ),

                const SizedBox(height: 32),

                // Carte info paiement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Montant à payer',
                          style: TextStyle(fontSize: 12, color: _kTextSub)),
                      const SizedBox(height: 4),
                      Text(
                        formatPrice(e.amount),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _kGreen),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${e.phoneNumber}',
                        style: const TextStyle(
                            fontSize: 12, color: _kTextSub),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () => context.go('/orders'),
                  child: const Text(
                    'Voir mes commandes',
                    style: TextStyle(
                        fontSize: 14,
                        color: _kTextSub,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Écran 4 — Échec du paiement
// ─────────────────────────────────────────────────────────────────────────────

const _kRed    = Color(0xFFEF4444);
const _kRedBg  = Color(0xFFFEF2F2);
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
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _kRedBg),
                child: const Icon(Icons.close_rounded,
                    size: 36, color: _kRed),
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
                        orderId:              extra.orderId,
                        amount:               extra.amount,
                        subscriptionName:     extra.subscriptionName,
                        subscriptionImageUrl: extra.subscriptionImageUrl,
                        paymentMethod:        extra.paymentMethod,
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
