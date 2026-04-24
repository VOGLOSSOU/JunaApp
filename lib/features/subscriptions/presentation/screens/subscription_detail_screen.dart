import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_badge.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../../core/widgets/juna_rating.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/api/api_client.dart';
import '../controllers/subscription_detail_controller.dart';
import '../controllers/subscriptions_controller.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/provider_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/subscription_entity.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final String subscriptionId;
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  final _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openCheckout(
      BuildContext context, String subscriptionId, bool isAuthenticated) async {
    if (!isAuthenticated) {
      context.push('${AppRoutes.login}?redirect=/subscription/$subscriptionId');
      return;
    }
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    final uri = Uri.parse(
      'https://junaeats.com/checkout?subscriptionId=$subscriptionId&token=${token ?? ""}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(subscriptionDetailProvider(widget.subscriptionId));
    final isFav = ref.watch(
      favoritesControllerProvider
          .select((s) => s.contains(widget.subscriptionId)),
    );
    final authState = ref.watch(authControllerProvider);

    return detailAsync.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError(e.toString()),
      data: (sub) =>
          _buildContent(context, sub, isFav, authState.isAuthenticated),
    );
  }

  // ── États de chargement / erreur ──────────────────────────────────────────

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.white,
            leading: _BackButton(onTap: () => context.pop()),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: AppColors.primarySurface),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const JunaSkeleton.line(width: double.infinity, height: 28),
                  const SizedBox(height: AppSpacing.sm),
                  const JunaSkeleton.line(width: 160, height: 16),
                  const SizedBox(height: AppSpacing.xl),
                  const JunaSkeleton.line(width: double.infinity, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  const JunaSkeleton.line(width: double.infinity, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  const JunaSkeleton.line(width: 200, height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.textLight),
              const SizedBox(height: AppSpacing.lg),
              Text('Impossible de charger cet abonnement',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(error,
                  style:
                      AppTypography.bodySmall.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => ref.invalidate(
                    subscriptionDetailProvider(widget.subscriptionId)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contenu principal ─────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    SubscriptionEntity sub,
    bool isFav,
    bool isAuthenticated,
  ) {
    final images = sub.images.isNotEmpty ? sub.images : [sub.imageUrl];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── GALERIE D'IMAGES ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.white,
                leading: _BackButton(onTap: () => context.pop()),
                actions: [
                  GestureDetector(
                    onTap: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .toggle(sub.id),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color:
                            isFav ? AppColors.accent : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Carousel
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (i) =>
                            setState(() => _currentImageIndex = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.primarySurface),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primarySurface,
                            child: const Icon(Icons.restaurant,
                                color: AppColors.primary, size: 60),
                          ),
                        ),
                      ),
                      // Indicateurs de pages
                      if (images.length > 1)
                        Positioned(
                          bottom: AppSpacing.md,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentImageIndex == i ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == i
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── TITRE + STATUS ─────────────────────────────────
                      Text(sub.title, style: AppTypography.headlineLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          JunaRating(
                              rating: sub.rating, reviewCount: sub.reviewCount),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: sub.isAvailable
                                  ? AppColors.primarySurface
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              sub.isAvailable ? 'Disponible' : 'Indisponible',
                              style: AppTypography.labelSmall.copyWith(
                                color: sub.isAvailable
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── DESCRIPTION ────────────────────────────────────
                      if (sub.description.isNotEmpty) ...[
                        Text(
                          sub.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // ── DÉTAILS TYPE ───────────────────────────────────
                      Text(sub.type.label, style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        sub.type.explanation,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl * 2),

                      // ── DÉTAILS DURÉE ───────────────────────────────────
                      Text(sub.duration.label,
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        sub.duration.explanation,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl * 2),

                      // ── CATÉGORIES ─────────────────────────────────────
                      if (sub.categories.isNotEmpty) ...[
                        Text('Catégorie', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: sub.categories
                              .map((c) => _CategoryCard(category: c))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl * 2),
                      ],

                      // ── REPAS INCLUS ───────────────────────────────────
                      if (sub.meals.isNotEmpty) ...[
                        Text('Repas inclus (${sub.meals.length})',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        ...sub.meals.map((meal) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _MealCard(meal: meal),
                            )),
                        const SizedBox(height: AppSpacing.xl * 2),
                      ],

                      // ── MODES DE RÉCEPTION ──────────────────────────────
                      Text('Modes de réception',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      if (sub.provider.acceptsDelivery) ...[
                        _DeliveryModeCard(
                          icon: Icons.delivery_dining_outlined,
                          title: 'Livraison à domicile',
                          description:
                              'Le prestataire livre vos repas directement chez vous.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (sub.provider.acceptsPickup) ...[
                        _DeliveryModeCard(
                          icon: Icons.store_outlined,
                          title: 'Retrait sur place',
                          description:
                              'Récupérez vos repas directement chez le prestataire.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // ── ZONES DE LIVRAISON ──────────────────────────────
                      if (sub.deliveryZones.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text('Zones de livraison',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        ...sub.deliveryZones.map((zone) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      zone,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: AppSpacing.xl * 2),
                      ],

                      // ── PRESTATAIRE ────────────────────────────────────
                      Text('Cet abonnement est proposé par',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      _ProviderDetailCard(provider: sub.provider),

                      const SizedBox(height: AppSpacing.xl * 2),

                      // ── AUTRES ABONNEMENTS ──────────────────────────────
                      if (sub.providerSubscriptions.isNotEmpty) ...[
                        Text('Découvrez d\'autres abonnements',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        ...sub.providerSubscriptions.map((otherSub) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _OtherSubscriptionCard(
                                  subscription: otherSub),
                            )),
                      ],

                      // ── AVIS CLIENTS ───────────────────────────────────
                      const SizedBox(height: AppSpacing.xl * 2),
                      _ReviewsSection(
                          subscriptionId: widget.subscriptionId,
                          totalCount: sub.reviewCount),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── BOUTON STICKY ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPrice(sub.price),
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(sub.duration.label, style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: JunaButton(
                      label: 'S\'abonner',
                      onPressed: sub.isAvailable
                          ? () =>
                              _openCheckout(context, sub.id, isAuthenticated)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── STATS RAPIDES ───────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final SubscriptionEntity sub;
  const _QuickStatsRow({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.restaurant_outlined,
          label: '${sub.mealCount} repas',
        ),
        const SizedBox(width: AppSpacing.lg),
        _StatItem(
          icon: Icons.access_time_outlined,
          label: sub.duration.label,
        ),
        const SizedBox(width: AppSpacing.lg),
        _StatItem(
          icon: Icons.attach_money_outlined,
          label: formatPrice(sub.price),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}

// ── DÉTAILS TYPE ─────────────────────────────────────────────────────

class _TypeDetailCard extends StatelessWidget {
  final SubscriptionType type;
  const _TypeDetailCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Text(type.label, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            type.explanation,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── DÉTAILS DURÉE ─────────────────────────────────────────────────────

class _DurationDetailCard extends StatelessWidget {
  final SubscriptionDuration duration;
  const _DurationDetailCard({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(duration.label, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            duration.explanation,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CATÉGORIE ─────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final SubscriptionCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.xs),
          Text(category.label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

// ── REPAS ──────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealEntity meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          if (meal.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: meal.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary, size: 24),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary, size: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name, style: AppTypography.titleMedium),
                if (meal.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    meal.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── MODE DE LIVRAISON ──────────────────────────────────────────────────

class _DeliveryModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _DeliveryModeCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── PRESTATAIRE DÉTAIL ─────────────────────────────────────────────────

class _ProviderDetailCard extends StatelessWidget {
  final ProviderEntity provider;
  const _ProviderDetailCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: CachedNetworkImage(
                  imageUrl: provider.logo,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.primarySurface,
                    child: const Icon(Icons.store,
                        color: AppColors.primary, size: 24),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.primarySurface,
                    child: const Icon(Icons.store,
                        color: AppColors.primary, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(provider.name,
                              style: AppTypography.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (provider.isVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      provider.businessAddress,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              provider.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── AUTRE ABONNEMENT ───────────────────────────────────────────────────

class _OtherSubscriptionCard extends StatelessWidget {
  final SubscriptionEntity subscription;
  const _OtherSubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/subscription/${subscription.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: subscription.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary, size: 24),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary, size: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subscription.title, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${subscription.type.label} · ${subscription.duration.label}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatPrice(subscription.price),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Bouton retour ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Chips d'infos rapides ─────────────────────────────────────────────────────

class _InfoChipsRow extends StatelessWidget {
  final SubscriptionEntity sub;
  const _InfoChipsRow({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _InfoChip(icon: Icons.access_time_outlined, label: sub.duration.label),
        _InfoChip(icon: Icons.restaurant_outlined, label: sub.type.label),
        if (sub.mealCount > 0)
          _InfoChip(
              icon: Icons.lunch_dining_outlined,
              label: '${sub.mealCount} repas'),
        _InfoChip(icon: Icons.payments_outlined, label: sub.currency),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Carte prestataire ─────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          JunaAvatar(
            imageUrl: provider.avatarUrl,
            initials: provider.name.isNotEmpty
                ? provider.name.substring(0, 2).toUpperCase()
                : '??',
            size: 52,
            showVerifiedBadge: provider.isVerified,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(provider.name,
                          style: AppTypography.titleMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (provider.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ],
                ),
                if (provider.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    provider.description,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (provider.rating > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  JunaRating(
                    rating: provider.rating,
                    reviewCount: provider.reviewCount,
                    size: 12,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section livraison / retrait ───────────────────────────────────────────────

class _DeliverySection extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> items;
  const _DeliverySection(
      {required this.icon, required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.lg, bottom: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(item,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section avis clients ──────────────────────────────────────────────────────

class _ReviewsSection extends ConsumerWidget {
  final String subscriptionId;
  final int totalCount;
  const _ReviewsSection(
      {required this.subscriptionId, required this.totalCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(subscriptionReviewsProvider(subscriptionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Avis clients', style: AppTypography.titleMedium),
            if (totalCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$totalCount',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        reviewsAsync.when(
          loading: () => Column(
            children: List.generate(
              2,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      JunaSkeleton(width: 36, height: 36, borderRadius: 18),
                      SizedBox(width: AppSpacing.sm),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            JunaSkeleton.line(width: 100, height: 12),
                            SizedBox(height: 4),
                            JunaSkeleton.line(width: 70, height: 10),
                          ]),
                    ]),
                    SizedBox(height: AppSpacing.sm),
                    JunaSkeleton.line(width: double.infinity, height: 12),
                    SizedBox(height: 4),
                    JunaSkeleton.line(width: 200, height: 12),
                  ],
                ),
              ),
            ),
          ),
          error: (_, __) => Text(
            'Impossible de charger les avis.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          data: (reviews) => reviews.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      'Aucun avis pour l\'instant.\nSoyez le premier à donner votre avis !',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: reviews.map((r) => _ReviewCard(review: r)).toList(),
                ),
        ),
      ],
    );
  }
}

// ── Carte avis ────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              JunaAvatar(
                imageUrl: review.userAvatar,
                initials: review.initials,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: AppTypography.labelLarge),
                    JunaRating(
                      rating: review.rating,
                      showCount: false,
                      size: 12,
                    ),
                  ],
                ),
              ),
              Text(review.timeAgo,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textLight)),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
