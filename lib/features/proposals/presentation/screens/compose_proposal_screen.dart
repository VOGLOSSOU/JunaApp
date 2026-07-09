import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../provider_space/presentation/controllers/provider_detail_controller.dart';
import '../../../subscriptions/domain/entities/meal_entity.dart';
import '../../data/repositories/subscription_proposal_repository.dart';

class ComposeProposalScreen extends ConsumerStatefulWidget {
  final String providerId;
  const ComposeProposalScreen({super.key, required this.providerId});

  @override
  ConsumerState<ComposeProposalScreen> createState() => _ComposeProposalScreenState();
}

class _SelectedMealState {
  int quantity;
  String? pricingLabel;
  _SelectedMealState({this.quantity = 1, this.pricingLabel});
}

class _ComposeProposalScreenState extends ConsumerState<ComposeProposalScreen> {
  SubscriptionType _type = SubscriptionType.lunch;
  SubscriptionCategory _category = SubscriptionCategory.african;
  SubscriptionDuration _duration = SubscriptionDuration.workWeek;
  final _messageCtrl = TextEditingController();
  final Map<String, _SelectedMealState> _selected = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  void _toggleMeal(MealEntity meal) {
    setState(() {
      if (_selected.containsKey(meal.id)) {
        _selected.remove(meal.id);
      } else {
        _selected[meal.id] = _SelectedMealState(
          quantity: 1,
          pricingLabel: meal.priceType == MealPriceType.multiple && meal.pricings.isNotEmpty
              ? meal.pricings.first.label
              : null,
        );
      }
    });
  }

  Future<void> _submit(String providerName) async {
    if (_selected.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final meals = _selected.entries
          .map((e) => ProposalMealInput(
                mealId: e.key,
                quantity: e.value.quantity,
                mealPricingLabel: e.value.pricingLabel,
              ))
          .toList();
      await ref.read(subscriptionProposalRepositoryProvider).createProposal(
            providerId: widget.providerId,
            type: _type,
            category: _category,
            duration: _duration,
            message: _messageCtrl.text,
            meals: meals,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proposition envoyée à $providerName !')),
      );
      context.go(AppRoutes.myProposals);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerAsync = ref.watch(providerDetailProvider(widget.providerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Proposer un abonnement'),
      ),
      body: providerAsync.when(
        loading: () => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const JunaSkeleton.line(width: 140, height: 16),
              const SizedBox(height: AppSpacing.xl),
              JunaSkeleton(width: double.infinity, height: 56, borderRadius: AppRadius.md),
              const SizedBox(height: AppSpacing.md),
              JunaSkeleton(width: double.infinity, height: 56, borderRadius: AppRadius.md),
              const SizedBox(height: AppSpacing.md),
              JunaSkeleton(width: double.infinity, height: 56, borderRadius: AppRadius.md),
              const SizedBox(height: AppSpacing.xl),
              const JunaSkeleton.line(width: 100, height: 16),
              const SizedBox(height: AppSpacing.md),
              JunaSkeleton(width: double.infinity, height: 72, borderRadius: AppRadius.md),
              const SizedBox(height: AppSpacing.sm),
              JunaSkeleton(width: double.infinity, height: 72, borderRadius: AppRadius.md),
              const SizedBox(height: AppSpacing.sm),
              JunaSkeleton(width: double.infinity, height: 72, borderRadius: AppRadius.md),
              const SizedBox(height: AppSpacing.xl),
              JunaSkeleton(width: double.infinity, height: 100, borderRadius: AppRadius.md),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Text('Impossible de charger ce prestataire',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ),
        data: (provider) {
          final meals = provider.meals;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'à ${provider.name}',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Carte 1 : Vos préférences ─────────────────────
                      _Card(
                        title: 'Vos préférences',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LabeledDropdown<SubscriptionType>(
                              label: 'Type de repas',
                              value: _type,
                              items: SubscriptionType.values,
                              itemLabel: (t) => t.label,
                              onChanged: (v) => setState(() => _type = v),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _LabeledDropdown<SubscriptionCategory>(
                              label: 'Catégorie',
                              value: _category,
                              items: SubscriptionCategory.values,
                              itemLabel: (c) => c.label,
                              onChanged: (v) => setState(() => _category = v),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _LabeledDropdown<SubscriptionDuration>(
                              label: 'Fréquence',
                              value: _duration,
                              items: SubscriptionDuration.values,
                              itemLabel: (d) => d.label,
                              onChanged: (v) => setState(() => _duration = v),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Message (optionnel)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _messageCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText:
                                    'Ex: Livraison tous les midis. Pour le riz sauté, je vise autour de 4 500 FCFA.',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Carte 2 : Choisissez les plats ────────────────
                      _Card(
                        title: 'Choisissez les plats',
                        trailing: Text(
                          '${_selected.length} sélectionné${_selected.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        child: meals.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: Text(
                                  'Ce prestataire n\'a pas encore de plats au catalogue.',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              )
                            : Column(
                                children: meals
                                    .map((meal) => _MealSelectRow(
                                          meal: meal,
                                          state: _selected[meal.id],
                                          onToggle: () => _toggleMeal(meal),
                                          onQuantityChanged: (q) => setState(
                                              () => _selected[meal.id]!.quantity = q),
                                          onPricingChanged: (l) => setState(
                                              () => _selected[meal.id]!.pricingLabel = l),
                                        ))
                                    .toList(),
                              ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // ── Bouton sticky ──────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: JunaButton(
                    label: 'Envoyer la proposition',
                    onPressed: _selected.isEmpty
                        ? null
                        : () => _submit(provider.name),
                    isLoading: _isSubmitting,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Carte container ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _Card({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleMedium),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ── Dropdown labellisé ──────────────────────────────────────────────────────────

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textLight),
              items: items
                  .map((i) => DropdownMenuItem<T>(
                        value: i,
                        child: Text(itemLabel(i),
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ligne de sélection d'un plat ────────────────────────────────────────────────

class _MealSelectRow extends StatelessWidget {
  final MealEntity meal;
  final _SelectedMealState? state;
  final VoidCallback onToggle;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onPricingChanged;

  const _MealSelectRow({
    required this.meal,
    required this.state,
    required this.onToggle,
    required this.onQuantityChanged,
    required this.onPricingChanged,
  });

  String _priceLabel() {
    switch (meal.priceType) {
      case MealPriceType.multiple:
        return 'À partir de ${formatPrice(meal.price.toDouble())}';
      case MealPriceType.range:
        final min = meal.priceMin ?? 0;
        final max = meal.priceMax ?? 0;
        return '${formatPrice(min.toDouble())} – ${formatPrice(max.toDouble())}';
      case MealPriceType.fixed:
        return formatPrice(meal.price.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = state != null;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: meal.imageUrl.isNotEmpty
                        ? CachedNetworkImage(imageUrl: meal.imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.restaurant,
                                color: AppColors.primary, size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _priceLabel(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _QuantityStepper(
                    value: state!.quantity,
                    onChanged: onQuantityChanged,
                  ),
                  if (meal.priceType == MealPriceType.multiple &&
                      meal.pricings.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PricingPicker(
                        pricings: meal.pricings,
                        value: state!.pricingLabel ?? meal.pricings.first.label,
                        onChanged: onPricingChanged,
                      ),
                    ),
                  ],
                ],
              ),
              if (meal.priceType == MealPriceType.range) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Prix indicatif : ${formatPrice((meal.priceMin ?? 0).toDouble())} – ${formatPrice((meal.priceMax ?? 0).toDouble())}. Précisez votre budget dans le champ message ci-dessous.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stepper quantité ─────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.value, required this.onChanged});

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Icon(icon,
            size: 14, color: onTap != null ? AppColors.primary : AppColors.textLight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove_rounded, value > 1 ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        _btn(Icons.add_rounded, () => onChanged(value + 1)),
      ],
    );
  }
}

// ── Sélecteur de variante (plats MULTIPLE) ──────────────────────────────────────

class _PricingPicker extends StatelessWidget {
  final List<MealPricing> pricings;
  final String value;
  final ValueChanged<String> onChanged;

  const _PricingPicker({
    required this.pricings,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AppColors.textLight),
          items: pricings
              .map((p) => DropdownMenuItem<String>(
                    value: p.label,
                    child: Text(
                      '${p.label} · ${formatPrice(p.price.toDouble())}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
