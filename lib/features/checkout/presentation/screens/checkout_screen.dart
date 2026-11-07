import 'package:flutter/material.dart';
import '../../../../core/widgets/subscription_instructions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../../../features/subscriptions/domain/entities/subscription_entity.dart';
import '../../../../features/subscriptions/presentation/controllers/subscription_detail_controller.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/fulfillment.dart';

// Données passées via GoRouter extra
class CheckoutMobileExtra {
  final String orderId;
  final double amount;
  final String subscriptionName;
  final String? subscriptionInstructions;
  final String subscriptionImageUrl;
  final String paymentMethod;
  const CheckoutMobileExtra({
    required this.orderId,
    required this.amount,
    required this.subscriptionName,
    this.subscriptionInstructions,
    required this.subscriptionImageUrl,
    required this.paymentMethod,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Couleurs locales (spec design)
const _kGreen = Color(0xFF1A5C2A);
const _kGreenSurface = Color(0x141A5C2A);
const _kBorder = Color(0xFFE5E7EB);
const _kTextMain = Color(0xFF1C1C1C);
const _kTextSub = Color(0xFF757575);
const _kPageBg = Color(0xFFF5F5F5);
const _kCardBg = Color(0xFFFFFFFF);
const _kOrange = Color(0xFFF97316);

// Parse "Cotonou · 500 FCFA" → (city, cost?)
(String, int?) _parseZone(String zone) {
  if (zone.contains(' · ')) {
    final parts = zone.split(' · ');
    final city = parts[0].trim();
    final costStr = parts[1].replaceAll('FCFA', '').replaceAll(' ', '').trim();
    return (
      city,
      int.tryParse(costStr.replaceAll(',', '').replaceAll(' ', ''))
    );
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

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with WidgetsBindingObserver {
  // Choix de l'utilisateur, utilisé seulement si le prestataire propose les
  // deux modes. Sinon le mode disponible est imposé (voir [_isDeliveryFor]).
  bool _prefersDelivery = true;
  String? _selectedZone;
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  bool _isDeliveryFor(List<FulfillmentMode> modes) => modes.length > 1
      ? _prefersDelivery
      : modes.contains(FulfillmentMode.delivery);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) {
      ref.invalidate(checkoutSubscriptionProvider(widget.subscriptionId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(SubscriptionEntity sub) async {
    if (_loading) return;
    final modes = availableFulfillmentModes(sub.provider);
    if (modes.isEmpty) return;
    final isDelivery = _isDeliveryFor(modes);

    // Validations
    if (isDelivery) {
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
      final fresh = await ref
          .refresh(checkoutSubscriptionProvider(widget.subscriptionId).future);
      if (!mounted) return;
      final selectedMode =
          isDelivery ? FulfillmentMode.delivery : FulfillmentMode.pickup;
      if (!availableFulfillmentModes(fresh.provider).contains(selectedMode)) {
        _toast(
            'Les modes de réception ont changé. Vérifiez les options proposées par ce prestataire.');
        return;
      }
      if (isDelivery && !fresh.deliveryZones.contains(_selectedZone)) {
        setState(() => _selectedZone = null);
        _toast(
            'Les zones de livraison ont changé. Choisissez une zone disponible.');
        return;
      }
      final (city, _) =
          _selectedZone != null ? _parseZone(_selectedZone!) : ('', null);
      final result = await ref.read(paymentRepositoryProvider).createOrder(
            subscriptionId: widget.subscriptionId,
            deliveryMethod: isDelivery ? 'DELIVERY' : 'PICKUP',
            deliveryAddress: isDelivery ? _addressCtrl.text.trim() : null,
            deliveryCity: isDelivery ? city : null,
            pickupLocation: isDelivery ? null : fresh.provider.businessAddress,
            startAsap: true,
          );

      if (!mounted) return;

      // Tout se paie via la plateforme : l'opérateur Mobile Money est choisi
      // à l'étape suivante, juste avant la saisie du numéro.
      context.push(
        AppRoutes.checkoutMobileMoney,
        extra: CheckoutMobileExtra(
          orderId: result.orderId,
          amount: result.amount,
          subscriptionName: fresh.title,
          subscriptionInstructions: fresh.instructions,
          subscriptionImageUrl: fresh.imageUrl,
          paymentMethod: 'MOBILE_MONEY',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final ex = e is AppException
          ? e
          : (e is Exception ? AppException(message: e.toString()) : null);
      if (ex?.code == 'EMAIL_NOT_VERIFIED') {
        _showEmailVerificationDialog();
      } else {
        _toast(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEmailVerificationDialog() {
    final email = ref.read(authControllerProvider).user?.email ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Email non vérifié'),
        content: const Text(
          'Vous devez vérifier votre adresse email avant de pouvoir passer une commande.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(
                AppRoutes.verifyEmail,
                extra: EmailVerificationExtra(
                  prefillEmail: email.isNotEmpty ? email : null,
                ),
              );
            },
            child: const Text('Vérifier maintenant'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _kTextMain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async =
        ref.watch(checkoutSubscriptionProvider(widget.subscriptionId));

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
        error: (e, _) => Center(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Impossible de vérifier les options de ce prestataire.',
                textAlign: TextAlign.center),
            TextButton(
                onPressed: () => ref.invalidate(
                    checkoutSubscriptionProvider(widget.subscriptionId)),
                child: const Text('Réessayer')),
          ]),
        )),
        data: (sub) =>
            AbsorbPointer(absorbing: _loading, child: _buildForm(sub)),
      ),
    );
  }

  Widget _buildForm(SubscriptionEntity sub) {
    final zones = sub.deliveryZones;
    final modes = availableFulfillmentModes(sub.provider);
    final isDelivery = _isDeliveryFor(modes);

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
                          width: 80,
                          height: 68,
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
                          style:
                              const TextStyle(fontSize: 12, color: _kTextSub)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Chip(sub.type.label, bg: _kGreen, fg: Colors.white),
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

          SubscriptionInstructions(instructions: sub.instructions),

          const SizedBox(height: 20),

          // ── Section 2 : Mode de récupération ─────────────────────────────
          // Seuls les modes proposés par le prestataire sont affichés ; un
          // sélecteur n'apparaît que s'il y a vraiment un choix à faire.
          const _SectionTitle('Mode de récupération'),
          const SizedBox(height: 10),
          if (modes.length > 1)
            Row(
              children: [
                Expanded(
                  child: _DeliveryToggle(
                    icon: Icons.delivery_dining_outlined,
                    label: 'Livraison\nà domicile',
                    selected: isDelivery,
                    onTap: () => setState(() {
                      _prefersDelivery = true;
                      _selectedZone = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DeliveryToggle(
                    icon: Icons.store_outlined,
                    label: 'Retrait\nsur place',
                    selected: !isDelivery,
                    onTap: () => setState(() => _prefersDelivery = false),
                  ),
                ),
              ],
            )
          else if (modes.length == 1)
            _InfoCard(
              icon: isDelivery
                  ? Icons.delivery_dining_outlined
                  : Icons.store_outlined,
              label: isDelivery ? 'Livraison à domicile' : 'Retrait sur place',
              detail: isDelivery
                  ? 'Ce prestataire propose uniquement la livraison.'
                  : sub.provider.businessAddress.isNotEmpty
                      ? 'Ce prestataire propose uniquement le retrait, à ${sub.provider.businessAddress}.'
                      : 'Ce prestataire propose uniquement le retrait sur place.',
            )
          else
            const _InfoCard(
              icon: Icons.info_outline_rounded,
              label: 'Commande indisponible',
              detail:
                  'Ce prestataire ne propose actuellement ni livraison ni retrait.',
            ),

          if (isDelivery) ...[
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
                                : '≈ $cost XOF',
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
            const Text('Adresse précise *',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kTextMain)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                hintText: 'Ex : Rue 234, Quartier Cadjehoun',
                hintStyle: const TextStyle(color: _kTextSub, fontSize: 14),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          'Si vous souhaitez être livré durant toute la période de votre abonnement, les frais et modalités de livraison sont gérés directement avec le prestataire.',
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Section 3 : Paiement ─────────────────────────────────────────
          // Mobile Money est le seul moyen de paiement : pas de sélecteur.
          const _SectionTitle('Paiement'),
          const SizedBox(height: 10),
          const _InfoCard(
            icon: Icons.phone_android_rounded,
            label: 'Mobile Money',
            detail:
                'Paiement de l’abonnement via Juna Eats par MTN, Moov ou Celtiis, en livraison comme en retrait. Vous choisirez votre opérateur à l’étape suivante.',
          ),

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
                if (isDelivery && _selectedZone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Frais de livraison (${_parseZone(_selectedZone!).$1})',
                          style:
                              const TextStyle(fontSize: 14, color: _kTextSub),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Géré directement\navec le prestataire',
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
                    const Text('Total',
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
                    onPressed:
                        _loading || modes.isEmpty ? null : () => _submit(sub),
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
                        : const Text(
                            'Continuer vers le paiement',
                            style: TextStyle(
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Icon(icon, size: 24, color: _kGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kTextMain)),
                const SizedBox(height: 2),
                Text(detail,
                    style: const TextStyle(fontSize: 12, color: _kTextSub)),
              ],
            ),
          ),
        ],
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
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
