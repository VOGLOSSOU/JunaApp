import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../subscriptions/domain/entities/meal_entity.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../../subscriptions/presentation/controllers/subscription_detail_controller.dart';
import '../controllers/meal_detail_controller.dart';

class MealDetailScreen extends ConsumerWidget {
  final String mealId;

  const MealDetailScreen({
    super.key,
    required this.mealId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealAsync = ref.watch(mealDetailProvider(mealId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: mealAsync.when(
        loading: () => _buildLoading(context),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (meal) => _buildContent(context, ref, meal),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + bouton retour
          Stack(
            children: [
              JunaSkeleton(
                  width: double.infinity, height: 280, borderRadius: 0),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + prix
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                        child: JunaSkeleton.line(
                            width: double.infinity, height: 24)),
                    const SizedBox(width: AppSpacing.md),
                    JunaSkeleton(
                        width: 80, height: 24, borderRadius: AppRadius.sm),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Badge type
                JunaSkeleton(
                    width: 90, height: 22, borderRadius: AppRadius.full),
                const SizedBox(height: AppSpacing.lg),
                // Description
                const JunaSkeleton.line(width: double.infinity, height: 13),
                const SizedBox(height: 6),
                const JunaSkeleton.line(width: double.infinity, height: 13),
                const SizedBox(height: 6),
                const JunaSkeleton.line(width: 200, height: 13),
                const SizedBox(height: AppSpacing.xl),
                // Bloc provider
                JunaSkeleton(
                    width: double.infinity,
                    height: 72,
                    borderRadius: AppRadius.lg),
                const SizedBox(height: AppSpacing.md),
                // Bloc abonnement
                JunaSkeleton(
                    width: double.infinity,
                    height: 72,
                    borderRadius: AppRadius.lg),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 64, color: AppColors.textLight),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Impossible de charger ce plat',
                        style: AppTypography.titleMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => refreshMealDetail(ref, mealId),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _priceLabel(MealEntity meal) {
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

  Widget _buildContent(BuildContext context, WidgetRef ref, MealEntity meal) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image principale ──────────────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: meal.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: meal.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppColors.surface),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primarySurface,
                              child: const Icon(Icons.restaurant,
                                  color: AppColors.primary, size: 48),
                            ),
                          )
                        : Container(
                            color: AppColors.primarySurface,
                            child: const Icon(Icons.restaurant,
                                color: AppColors.primary, size: 48),
                          ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                        ),
                      ),
                    ),
                  ),
                  if (meal.priceType == MealPriceType.multiple)
                    Positioned(
                      bottom: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text(
                          'Variantes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Titre + type + prix ─────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  meal.mealType.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          _priceLabel(meal),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),

                    // ── Description ──────────────────────────────────────
                    if (meal.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        meal.description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],

                    // ── Note explicative ─────────────────────────────────
                    if (meal.priceGuideline != null &&
                        meal.priceGuideline!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          meal.priceGuideline!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    // ── Variantes (MULTIPLE) ─────────────────────────────
                    if (meal.priceType == MealPriceType.multiple &&
                        meal.pricings.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Variantes', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ...meal.pricings.map(
                        (p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                formatPrice(p.price.toDouble()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── Fait partie de l'abonnement / des abonnements ────
                    if (meal.subscriptions.isNotEmpty) ...[
                      for (final sub in meal.subscriptions) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _SubscriptionRefCard(subscriptionId: sub.id),
                      ],
                    ],

                    // ── Proposé par ───────────────────────────────────────
                    if (meal.provider != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _ProviderRefCard(provider: meal.provider!),
                    ],

                    // ── Autres plats du même prestataire ────────────────
                    if (meal.provider != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _OtherMealsSection(
                        providerId: meal.provider!.id,
                        excludeMealId: meal.id,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home_outlined, size: 18),
                        label: const Text('Retour à l\'accueil'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Carte "fait partie de l'abonnement" ───────────────────────────────────────

class _SubscriptionRefCard extends ConsumerWidget {
  final String subscriptionId;
  const _SubscriptionRefCard({required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionDetailProvider(subscriptionId));

    return subAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sub) => GestureDetector(
        onTap: () => context.push('/subscriptions/${sub.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: sub.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: sub.imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.white,
                          child: const Icon(Icons.restaurant,
                              color: AppColors.primary, size: 22),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fait partie de l\'abonnement',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte "Proposé par" ────────────────────────────────────────────────────────

class _ProviderRefCard extends StatelessWidget {
  final ProviderEntity provider;
  const _ProviderRefCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/providers/${provider.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySurface,
              ),
              child: ClipOval(
                child: provider.logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: provider.logo, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          provider.name.isNotEmpty
                              ? provider.name.substring(0, 2).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                children: [
                  const Text(
                    'Proposé par ',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Flexible(
                    child: Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (provider.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        color: Color(0xFF3B82F6), size: 15),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

// ── Section "autres plats du même prestataire" ────────────────────────────────

class _OtherMealsSection extends ConsumerWidget {
  final String providerId;
  final String excludeMealId;

  const _OtherMealsSection({
    required this.providerId,
    required this.excludeMealId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherMealsAsync = ref.watch(otherMealsProvider(
      OtherMealsParams(providerId: providerId, excludeMealId: excludeMealId),
    ));

    return otherMealsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (meals) {
        if (meals.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Autres plats du même prestataire',
                style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: meals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _OtherMealItem(meal: meals[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OtherMealItem extends StatelessWidget {
  final MealEntity meal;
  const _OtherMealItem({required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/meals/${meal.id}'),
      child: SizedBox(
        width: 144,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 144,
                height: 96,
                child: meal.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: meal.imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.primarySurface,
                        child: const Icon(Icons.restaurant,
                            color: AppColors.primary, size: 28),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meal.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              meal.priceType == MealPriceType.multiple
                  ? 'Dès ${formatPrice(meal.price.toDouble())}'
                  : formatPrice(meal.price.toDouble()),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
