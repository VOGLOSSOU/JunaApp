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
    final token =
        await ref.read(tokenStorageProvider).getAccessToken();
    final uri = Uri.parse(
      'https://junaeats.com/checkout?subscriptionId=$subscriptionId&token=${token ?? ""}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(subscriptionDetailProvider(widget.subscriptionId));
    final isFav = ref.watch(
      favoritesControllerProvider.select((s) => s.contains(widget.subscriptionId)),
    );
    final authState = ref.watch(authControllerProvider);

    return detailAsync.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError(e.toString()),
      data: (sub) => _buildContent(context, sub, isFav, authState.isAuthenticated),
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
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.error),
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
                        color: isFav ? AppColors.accent : AppColors.textSecondary,
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
                                margin: const EdgeInsets.symmetric(horizontal: 3),
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
                      // ── TITRE + RATING ─────────────────────────────────
                      Text(sub.title, style: AppTypography.headlineLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          JunaRating(
                              rating: sub.rating,
                              reviewCount: sub.reviewCount),
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

                      // ── STATS RAPIDES ───────────────────────────────────
                      _QuickStatsRow(sub: sub),

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),

                      // ── CE QUE VOUS RECEVEZ ─────────────────────────────
                      Text('Ce que vous recevez',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      _TypeDetailCard(type: sub.type),
                      const SizedBox(height: AppSpacing.sm),
                      _DurationDetailCard(duration: sub.duration),

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),

                      // ── PRESTATAIRE ────────────────────────────────────
                      Text('Prestataire', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      _ProviderCard(provider: sub.provider),

                      // ── DESCRIPTION ────────────────────────────────────
                      if (sub.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xl),
                        Text('À propos', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          sub.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.7,
                          ),
                        ),
                      ],

                      // ── STYLE CULINAIRE ────────────────────────────────
                      if (sub.categories.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Style culinaire',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        ...sub.categories
                            .map((c) => _CategoryCard(category: c)),
                      ],

                      // ── REPAS INCLUS ───────────────────────────────────
                      if (sub.meals.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Text('Repas inclus',
                                style: AppTypography.titleMedium),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${sub.meals.length}',
                                style: AppTypography.labelSmall
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...sub.meals.map((m) => _MealCard(meal: m)),
                      ] else if (sub.mealCount > 0) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${sub.mealCount} repas inclus dans cet abonnement',
                                style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── LIVRAISON & RETRAIT ────────────────────────────
                      if (sub.deliveryZones.isNotEmpty ||
                          sub.pickupPoints.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Livraison et retrait',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        if (sub.deliveryZones.isNotEmpty) ...[
                          _DeliverySection(
                            icon: Icons.delivery_dining_outlined,
                            label: 'Zones de livraison',
                            items: sub.deliveryZones,
                          ),
                          if (sub.pickupPoints.isNotEmpty)
                            const SizedBox(height: AppSpacing.md),
                        ],
                        if (sub.pickupPoints.isNotEmpty)
                          _DeliverySection(
                            icon: Icons.store_outlined,
                            label: 'Points de retrait',
                            items: sub.pickupPoints,
                          ),
                      ],

                      // ── AVIS CLIENTS ───────────────────────────────────
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),
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
                      Text(sub.duration.label,
                          style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: JunaButton(
                      label: 'S\'abonner',
                      onPressed: sub.isAvailable
                          ? () => _openCheckout(context, sub.id, isAuthenticated)
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
        _InfoChip(
            icon: Icons.access_time_outlined, label: sub.duration.label),
        _InfoChip(
            icon: Icons.restaurant_outlined, label: sub.type.label),
        if (sub.mealCount > 0)
          _InfoChip(
              icon: Icons.lunch_dining_outlined,
              label: '${sub.mealCount} repas'),
        _InfoChip(
            icon: Icons.payments_outlined,
            label: sub.currency),
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
                      const Icon(Icons.verified,
                          color: Colors.blue, size: 16),
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

// ── Carte repas ───────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealEntity meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          if (meal.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: CachedNetworkImage(
                imageUrl: meal.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary, size: 24),
                ),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.restaurant,
                  color: AppColors.primary, size: 24),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (meal.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meal.description,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
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
                  children:
                      reviews.map((r) => _ReviewCard(review: r)).toList(),
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
                    Text(review.userName,
                        style: AppTypography.labelLarge),
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
