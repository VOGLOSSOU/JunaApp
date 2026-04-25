import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/subscriptions/domain/entities/subscription_entity.dart';
import '../../../../features/subscriptions/presentation/controllers/subscription_detail_controller.dart';
import '../../data/repositories/payment_repository.dart';

// Données passées via GoRouter extra
class CheckoutMobileExtra {
  final String orderId;
  final double amount;
  final String subscriptionName;
  final String subscriptionImageUrl;
  final String paymentMethod;
  const CheckoutMobileExtra({
    required this.orderId,
    required this.amount,
    required this.subscriptionName,
    required this.subscriptionImageUrl,
    required this.paymentMethod,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Couleurs locales (spec design)
const _kGreen       = Color(0xFF1A5C2A);
const _kGreenSurface = Color(0x141A5C2A);
const _kBorder      = Color(0xFFE5E7EB);
const _kTextMain    = Color(0xFF1C1C1C);
const _kTextSub     = Color(0xFF757575);
const _kPageBg      = Color(0xFFF5F5F5);
const _kCardBg      = Color(0xFFFFFFFF);
const _kOrange      = Color(0xFFF97316);

// Opérateurs disponibles par pays
const _kPaymentMethods = [
  ('MOBILE_MONEY_MTN',   'MTN Mobile Money',   'assets/icons/mtn.png'),
  ('MOBILE_MONEY_MOOV',  'Moov Money',         'assets/icons/moov.png'),
  ('MOBILE_MONEY_ORANGE','Orange Money',        'assets/icons/orange.png'),
  ('MOBILE_MONEY_WAVE',  'Wave',               'assets/icons/wave.png'),
  ('CASH',               'Espèces à la livraison', null),
];

// Parse "Cotonou · 500 FCFA" → (city, cost?)
(String, int?) _parseZone(String zone) {
  if (zone.contains(' · ')) {
    final parts = zone.split(' · ');
    final city = parts[0].trim();
    final costStr = parts[1].replaceAll('FCFA', '').replaceAll(' ', '').trim();
    return (city, int.tryParse(costStr.replaceAll(',', '').replaceAll(' ', '')));
  }
  return (zone.trim(), null);
}

// ─────────────────────────────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  final String subscriptionId;
  const CheckoutScreen({super.key, required this.subscriptionId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isDelivery = true;
  String? _selectedZone;
  final _addressCtrl = TextEditingController();
  String _paymentMethod = 'MOBILE_MONEY_MTN';
  bool _loading = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(SubscriptionEntity sub) async {
    // Validations
    if (_isDelivery) {
      if (_selectedZone == null) {
        _toast('Choisissez une ville de livraison');
        return;
      }
      if (_addressCtrl.text.trim().isEmpty) {
        _toast('Renseignez votre adresse précise');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final (city, _) = _selectedZone != null ? _parseZone(_selectedZone!) : ('', null);
      final result = await ref.read(paymentRepositoryProvider).createOrder(
        subscriptionId: widget.subscriptionId,
        deliveryMethod: _isDelivery ? 'DELIVERY' : 'PICKUP',
        deliveryAddress: _isDelivery ? _addressCtrl.text.trim() : null,
        deliveryCity:    _isDelivery ? city : null,
        pickupLocation:  _isDelivery ? null : sub.provider.businessAddress,
        startAsap: true,
      );

      if (!mounted) return;

      if (_paymentMethod == 'CASH') {
        context.go('/orders/${result.orderId}');
      } else {
        context.push(
          AppRoutes.checkoutMobileMoney,
          extra: CheckoutMobileExtra(
            orderId:              result.orderId,
            amount:               result.amount,
            subscriptionName:     sub.title,
            subscriptionImageUrl: sub.imageUrl,
            paymentMethod:        _paymentMethod,
          ),
        );
      }
    } catch (e) {
      if (mounted) _toast(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _kTextMain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscriptionDetailProvider(widget.subscriptionId));

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
        title: const Text('Commander'),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kGreen),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (sub) => _buildForm(sub),
      ),
    );
  }

  Widget _buildForm(SubscriptionEntity sub) {
    final zones = sub.deliveryZones;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1 : Récapitulatif abonnement ─────────────────────────
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: sub.imageUrl.isNotEmpty
                      ? Image.network(sub.imageUrl,
                          width: 80, height: 68, fit: BoxFit.cover)
                      : Container(
                          width: 80, height: 68,
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(Icons.restaurant_menu,
                              color: Color(0xFFBDBDBD)),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kTextMain)),
                      const SizedBox(height: 2),
                      Text(sub.provider.name,
                          style: const TextStyle(
                              fontSize: 12, color: _kTextSub)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Chip(sub.type.label,
                              bg: _kGreen, fg: Colors.white),
                          const SizedBox(width: 6),
                          _Chip(sub.duration.label,
                              bg: const Color(0xFFF5F5F5), fg: _kTextSub),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatPrice(sub.price),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 2 : Mode de livraison ────────────────────────────────
          _SectionTitle('Mode de livraison'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DeliveryToggle(
                  icon: Icons.delivery_dining_outlined,
                  label: 'Livraison\nà domicile',
                  selected: _isDelivery,
                  onTap: () => setState(() {
                    _isDelivery = true;
                    _selectedZone = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DeliveryToggle(
                  icon: Icons.store_outlined,
                  label: 'Retrait\nsur place',
                  selected: !_isDelivery,
                  onTap: () => setState(() => _isDelivery = false),
                ),
              ),
            ],
          ),

          if (_isDelivery) ...[
            const SizedBox(height: 14),

            // Zones de livraison
            if (zones.isNotEmpty) ...[
              ...zones.map((z) {
                final (city, cost) = _parseZone(z);
                final selected = _selectedZone == z;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedZone = z),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? _kGreenSurface : _kCardBg,
                        border: Border.all(
                          color: selected ? _kGreen : _kBorder,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(city,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? _kGreen : _kTextMain)),
                          ),
                          Text(
                            cost == null || cost == 0
                                ? 'Gratuit'
                                : '+ $cost XOF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cost == null || cost == 0
                                  ? _kGreen
                                  : (selected ? _kGreen : _kTextSub),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],

            // Champ adresse précise
            Text('Adresse précise *',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kTextMain)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                hintText: 'Ex : Rue 234, Quartier Cadjehoun',
                hintStyle: const TextStyle(color: _kTextSub, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kGreen, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Info livraison
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFDCFCE7),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        size: 14, color: _kGreen),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Information importante sur la livraison',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF14532D))),
                        SizedBox(height: 4),
                        Text(
                          'Si vous souhaitez être livré durant toute la période de votre abonnement, cela sera discuté directement avec le fournisseur de repas qui vous communiquera les frais et modalités.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Section 3 : Méthode de paiement ──────────────────────────────
          _SectionTitle('Méthode de paiement'),
          const SizedBox(height: 10),
          ..._kPaymentMethods.map(((String, String, String?) method) {
            final (value, label, _) = method;
            final selected = _paymentMethod == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _paymentMethod = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? _kGreenSurface : _kCardBg,
                    border: Border.all(
                      color: selected ? _kGreen : _kBorder,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: selected ? _kGreen : _kTextSub,
                      ),
                      const SizedBox(width: 12),
                      Text(label,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: selected ? _kGreen : _kTextMain)),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (_paymentMethod != 'CASH') ...[
            const SizedBox(height: 4),
            const Text(
              'Vous serez redirigé vers la saisie de votre numéro Mobile Money après confirmation.',
              style: TextStyle(fontSize: 12, color: _kTextSub),
            ),
          ],

          const SizedBox(height: 20),

          // ── Section 4 : Total + CTA ───────────────────────────────────────
          _Card(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Abonnement',
                        style: TextStyle(fontSize: 14, color: _kTextSub)),
                    Text(formatPrice(sub.price),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (_isDelivery && _selectedZone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Frais de livraison (${_parseZone(_selectedZone!).$1})',
                          style: const TextStyle(fontSize: 14, color: _kTextSub),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Négociés\navec le prestataire',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 12,
                              color: _kOrange,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: _kBorder, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total à payer maintenant',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(
                      formatPrice(sub.price),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _submit(sub),
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
                            _paymentMethod == 'CASH'
                                ? 'Confirmer la commande'
                                : 'Continuer vers le paiement',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Widgets internes ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: _kTextMain));
  }
}

class _DeliveryToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DeliveryToggle({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _kGreenSurface : _kCardBg,
          border: Border.all(
            color: selected ? _kGreen : _kBorder,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: selected ? _kGreen : _kTextSub),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? _kGreen : _kTextSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip(this.label, {required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

