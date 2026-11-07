import 'package:flutter/material.dart';
import '../../../../core/widgets/subscription_instructions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/api/current_account.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/mobile_money.dart';
import 'checkout_screen.dart';
import 'payment_processing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1A5C2A);
const _kBorder = Color(0xFFE5E7EB);
const _kTextMain = Color(0xFF1C1C1C);
const _kTextSub = Color(0xFF757575);
const _kPageBg = Color(0xFFF5F5F5);
const _kCardBg = Color(0xFFFFFFFF);

// ─────────────────────────────────────────────────────────────────────────────

class MobileMoneyScreen extends ConsumerStatefulWidget {
  final CheckoutMobileExtra extra;
  const MobileMoneyScreen({super.key, required this.extra});

  @override
  ConsumerState<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends ConsumerState<MobileMoneyScreen> {
  // Pas de valeur par défaut : FeexPay ne détecte pas l'opérateur, un choix
  // implicite (MTN) ferait échouer les paiements Moov et Celtiis.
  MobileMoneyOperator? _operator;
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pré-sélection seulement si l'utilisateur a déjà choisi cet opérateur
    // (bouton « Réessayer » après un échec).
    _operator = MobileMoneyOperator.fromMethod(widget.extra.paymentMethod);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_loading) return;
    final account = ref.read(currentAccountIdProvider);
    final operator = _operator;
    // Le bouton reste désactivé tant qu'aucun réseau n'est choisi.
    if (operator == null) return;
    final phone = toBeninPaymentPhone(_phoneCtrl.text);
    setState(() {
      _error = _phoneCtrl.text.trim().isEmpty
          ? 'Entrez votre numéro Mobile Money'
          : phone == null
              ? 'Numéro invalide : 10 chiffres commençant par 01'
              : null;
    });
    if (phone == null) return;

    setState(() => _loading = true);
    try {
      final result = await ref.read(paymentRepositoryProvider).initiatePayment(
            orderId: widget.extra.orderId,
            phoneNumber: phone,
            provider: operator.provider,
          );
      if (!mounted || ref.read(currentAccountIdProvider) != account) return;

      final e = widget.extra;
      // Moov peut renvoyer le résultat final dès l'initiation : on ne lance
      // le polling que si le paiement est réellement en attente.
      switch (PaymentOutcome.parse(result.status)) {
        case PaymentOutcome.success:
          await openPaidOrder(context, ref, e.orderId);
        case PaymentOutcome.failed:
          showPaymentFailed(
            context,
            PaymentFailedExtra(
              orderId: e.orderId,
              phoneNumber: phone,
              paymentMethod: operator.method,
              amount: e.amount,
              subscriptionName: e.subscriptionName,
              subscriptionImageUrl: e.subscriptionImageUrl,
              errorMessage: result.message.isNotEmpty
                  ? result.message
                  : 'Paiement refusé par l\'opérateur.',
            ),
          );
        case PaymentOutcome.processing:
          context.pushReplacement(
            AppRoutes.checkoutProcessing,
            extra: PaymentProcessingExtra(
              orderId: e.orderId,
              paymentId: result.paymentId,
              phoneNumber: phone,
              amount: e.amount,
              subscriptionName: e.subscriptionName,
              paymentMethod: operator.method,
              subscriptionImageUrl: e.subscriptionImageUrl,
            ),
          );
      }
    } catch (err) {
      if (!mounted || ref.read(currentAccountIdProvider) != account) return;
      if (paymentInitiationNeedsVerification(err)) {
        final e = widget.extra;
        context.pushReplacement(AppRoutes.checkoutProcessing,
            extra: PaymentProcessingExtra(
              orderId: e.orderId,
              paymentId: null,
              phoneNumber: phone,
              amount: e.amount,
              subscriptionName: e.subscriptionName,
              paymentMethod: operator.method,
              subscriptionImageUrl: e.subscriptionImageUrl,
            ));
      } else {
        setState(() => _error = paymentInitiationErrorMessage(err));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildPhoneField(MobileMoneyOperator operator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('2. Votre numéro ${operator.label}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kTextMain)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _error != null ? const Color(0xFFEF4444) : _kBorder,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  border: Border(right: BorderSide(color: _kBorder)),
                ),
                child: const Text(
                  '+$beninDialCode',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kTextSub),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  enabled: !_loading,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0166000000',
                    hintStyle: TextStyle(color: _kTextSub, fontSize: 14),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _error ??
              '10 chiffres commençant par 01. Ce doit être un numéro ${operator.label}.',
          style: TextStyle(
            fontSize: 12,
            color: _error != null ? const Color(0xFFEF4444) : _kTextSub,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.extra;

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Paiement Mobile Money'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            const Text('Payer par Mobile Money',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _kTextMain)),
            const SizedBox(height: 6),
            const Text(
              'Choisissez d\'abord votre réseau, puis entrez votre numéro Mobile Money.',
              style: TextStyle(fontSize: 14, color: _kTextSub),
            ),

            const SizedBox(height: 24),

            // Mini recap
            _CardWidget(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: e.subscriptionImageUrl.isNotEmpty
                        ? Image.network(e.subscriptionImageUrl,
                            width: 64, height: 56, fit: BoxFit.cover)
                        : Container(
                            width: 64,
                            height: 56,
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(Icons.restaurant_menu,
                                color: Color(0xFFBDBDBD))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.subscriptionName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextMain)),
                  ),
                  Text(
                    formatPrice(e.amount),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kGreen),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SubscriptionInstructions(instructions: e.subscriptionInstructions),
            const SizedBox(height: 16),

            // Formulaire
            _CardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Étape 1 — le réseau. FeexPay ne le détecte pas depuis le
                  // numéro : le champ numéro n'apparaît qu'une fois choisi,
                  // pour qu'il soit impossible de passer à côté.
                  const Text('1. Choisissez votre réseau',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTextMain)),
                  const SizedBox(height: 4),
                  const Text(
                    'Le réseau de la puce qui porte votre compte Mobile Money.',
                    style: TextStyle(fontSize: 12, color: _kTextSub),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final op in MobileMoneyOperator.values) ...[
                        if (op != MobileMoneyOperator.values.first)
                          const SizedBox(width: 8),
                        Expanded(
                          child: _OperatorOption(
                            label: op.label,
                            selected: _operator == op,
                            onTap: _loading
                                ? null
                                : () => setState(() {
                                      _operator = op;
                                      _error = null;
                                    }),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Étape 2 — le numéro, seulement après le choix du réseau
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: _operator == null
                        ? const SizedBox(width: double.infinity)
                        : _buildPhoneField(_operator!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton Payer
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading || _operator == null ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  disabledBackgroundColor: _kGreen.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _operator == null
                            ? 'Choisissez votre réseau'
                            : 'Payer ${formatPrice(e.amount)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: const Text('Retour',
                    style: TextStyle(
                        fontSize: 14,
                        color: _kTextSub,
                        decoration: TextDecoration.underline)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final Widget child;
  const _CardWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _OperatorOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _OperatorOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _kGreen : _kBorder;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0x141A5C2A) : _kCardBg,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _kGreen : _kTextMain,
            ),
          ),
        ),
      ),
    );
  }
}
