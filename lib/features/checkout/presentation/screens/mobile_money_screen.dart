import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/repositories/payment_repository.dart';
import 'checkout_screen.dart';
import 'payment_processing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
const _kGreen  = Color(0xFF1A5C2A);
const _kBorder = Color(0xFFE5E7EB);
const _kTextMain    = Color(0xFF1C1C1C);
const _kTextSub     = Color(0xFF757575);
const _kPageBg      = Color(0xFFF5F5F5);
const _kCardBg      = Color(0xFFFFFFFF);

// Opérateurs Mobile Money
class _Operator {
  final String code;
  final String label;
  const _Operator(this.code, this.label);
}

const _kOperators = [
  _Operator('MOBILE_MONEY_MTN',    'MTN Mobile Money'),
  _Operator('MOBILE_MONEY_MOOV',   'Moov Money'),
  _Operator('MOBILE_MONEY_ORANGE', 'Orange Money'),
];

// Pays disponibles
const _kCountries = [
  _Country('BEN', 'Bénin', '229'),
  _Country('CIV', "Côte d'Ivoire", '225'),
  _Country('SEN', 'Sénégal', '221'),
];

// Mapping opérateur + pays → provider PawaPay
String? _resolveProvider(String method, String countryCode) {
  return switch ('${method}_$countryCode') {
    'MOBILE_MONEY_MTN_BEN'    => 'MTN_MOMO_BEN',
    'MOBILE_MONEY_MTN_CIV'    => 'MTN_MOMO_CIV',
    'MOBILE_MONEY_MTN_SEN'    => 'MTN_MOMO_SEN',
    'MOBILE_MONEY_MOOV_BEN'   => 'MOOV_BEN',
    'MOBILE_MONEY_MOOV_CIV'   => 'MOOV_CIV',
    'MOBILE_MONEY_ORANGE_CIV' => 'ORANGE_CIV',
    'MOBILE_MONEY_ORANGE_SEN' => 'ORANGE_SEN',
    _                          => null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class MobileMoneyScreen extends ConsumerStatefulWidget {
  final CheckoutMobileExtra extra;
  const MobileMoneyScreen({super.key, required this.extra});

  @override
  ConsumerState<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends ConsumerState<MobileMoneyScreen> {
  _Country _country = _kCountries.first;
  late _Operator _operator;
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _needsOperatorChoice =>
      !_kOperators.any((o) => o.code == widget.extra.paymentMethod);

  @override
  void initState() {
    super.initState();
    _operator = _kOperators.firstWhere(
      (o) => o.code == widget.extra.paymentMethod,
      orElse: () => _kOperators.first,
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '${_country.dialCode}${_phoneCtrl.text.trim().replaceAll(' ', '')}';

  String? get _provider => _resolveProvider(
        _needsOperatorChoice ? _operator.code : widget.extra.paymentMethod,
        _country.code,
      );

  Future<void> _pay() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Entrez votre numéro Mobile Money');
      return;
    }
    final provider = _provider;
    if (provider == null) {
      setState(() => _error =
          'Cette méthode de paiement n\'est pas disponible dans ce pays');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final result = await ref.read(paymentRepositoryProvider).initiatePayment(
        orderId:     widget.extra.orderId,
        phoneNumber: _fullPhone,
        provider:    provider,
      );

      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.checkoutProcessing,
        extra: PaymentProcessingExtra(
          orderId:              widget.extra.orderId,
          paymentId:            result.paymentId,
          phoneNumber:          _fullPhone,
          amount:               widget.extra.amount,
          subscriptionName:     widget.extra.subscriptionName,
          paymentMethod:        widget.extra.paymentMethod,
          countryCode:          _country.code,
          subscriptionImageUrl: widget.extra.subscriptionImageUrl,
        ),
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('INVALID_PHONE_NUMBER')) {
        setState(() => _error = 'Numéro invalide. Vérifiez et réessayez.');
      } else if (msg.contains('PAYMENT_ALREADY_PROCESSED')) {
        setState(() => _error = 'Un paiement est déjà en cours pour cette commande.');
      } else if (msg.contains('PAWAPAY_ERROR')) {
        setState(() => _error = 'Service momentanément indisponible. Réessayez dans quelques instants.');
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              'Entrez le numéro associé à votre compte Mobile Money.',
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
                            width: 64, height: 56,
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

            // Formulaire
            _CardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur opérateur (uniquement pour retry depuis commande pending)
                  if (_needsOperatorChoice) ...[
                    const Text('Opérateur *',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _kTextMain)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _kBorder, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_Operator>(
                          value: _operator,
                          isExpanded: true,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          items: _kOperators
                              .map((o) => DropdownMenuItem(
                                    value: o,
                                    child: Text(o.label),
                                  ))
                              .toList(),
                          onChanged: (o) {
                            if (o != null) setState(() => _operator = o);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Sélecteur pays
                  const Text('Pays *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _kTextMain)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _kBorder, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_Country>(
                        value: _country,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: _kCountries
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('${c.name} (+${c.dialCode})'),
                                ))
                            .toList(),
                        onChanged: (c) {
                          if (c != null) setState(() => _country = c);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Numéro téléphone
                  const Text('Numéro Mobile Money *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _kTextMain)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            border: Border(
                                right: BorderSide(color: _kBorder)),
                          ),
                          child: Text(
                            '+${_country.dialCode}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kTextSub),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '97123456',
                              hintStyle:
                                  TextStyle(color: _kTextSub, fontSize: 14),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            onChanged: (_) =>
                                setState(() => _error = null),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error ?? 'Numéro sans indicatif ni zéro initial',
                    style: TextStyle(
                      fontSize: 12,
                      color: _error != null
                          ? const Color(0xFFEF4444)
                          : _kTextSub,
                    ),
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
                onPressed: _loading ? null : _pay,
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
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Payer ${formatPrice(e.amount)}',
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

class _Country {
  final String code;
  final String name;
  final String dialCode;
  const _Country(this.code, this.name, this.dialCode);

  @override
  bool operator ==(Object other) => other is _Country && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
