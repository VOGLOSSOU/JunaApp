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
  int _currentImageIndex = 0;

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

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(backgroundColor: AppColors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const JunaSkeleton(width: double.infinity, height: 288, borderRadius: 16),
            const SizedBox(height: 24),
            const JunaSkeleton.line(width: 240, height: 28),
            const SizedBox(height: 12),
            const JunaSkeleton.line(width: 160, height: 16),
            const SizedBox(height: 20),
            const JunaSkeleton.line(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const JunaSkeleton.line(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const JunaSkeleton.line(width: 200, height: 14),
            const SizedBox(height: 24),
            const JunaSkeleton(width: double.infinity, height: 80, borderRadius: 12),
            const SizedBox(height: 8),
            const JunaSkeleton(width: double.infinity, height: 80, borderRadius: 12),
            const SizedBox(height: 8),
            const JunaSkeleton(width: double.infinity, height: 80, borderRadius: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
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

  Widget _buildContent(
    BuildContext context,
    SubscriptionEntity sub,
    bool isFav,
    bool isAuthenticated,
  ) {
    final images = sub.images.isNotEmpty ? sub.images : (sub.imageUrl.isNotEmpty ? [sub.imageUrl] : <String>[]);
    final showDelivery = sub.provider.acceptsDelivery ||
        sub.provider.acceptsPickup ||
        sub.deliveryZones.isNotEmpty ||
        sub.pickupPoints.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.accent : AppColors.textSecondary,
            ),
            onPressed: () => ref
                .read(favoritesControllerProvider.notifier)
                .toggle(sub.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. CAROUSEL ─────────────────────────────────────────────────
            _ImageCarousel(
              images: images,
              currentIndex: _currentImageIndex,
              onChanged: (i) => setState(() => _currentImageIndex = i),
            ),

            const SizedBox(height: 32),

            // ── 2. INFOS PRINCIPALES ─────────────────────────────────────────
            _MainInfoSection(sub: sub),

            // ── 3. REPAS INCLUS ──────────────────────────────────────────────
            if (sub.meals.isNotEmpty) ...[
              const SizedBox(height: 40),
              _SectionDivider(title: 'Repas inclus', count: sub.meals.length),
              const SizedBox(height: 16),
              _MealsHorizontalList(meals: sub.meals),
            ],

            // ── 4. MODES DE RÉCEPTION ────────────────────────────────────────
            if (showDelivery) ...[
              const SizedBox(height: 40),
              _SectionDivider(title: 'Modes de réception'),
              const SizedBox(height: 16),
              _DeliveryModesSection(sub: sub),
            ],

            // ── 5. PRIX & CTA ────────────────────────────────────────────────
            const SizedBox(height: 40),
            _PriceCtaCard(
              sub: sub,
              isAuthenticated: isAuthenticated,
              onSubscribe: () => _openCheckout(context, sub.id, isAuthenticated),
            ),

            // ── 6. PRESTATAIRE ───────────────────────────────────────────────
            const SizedBox(height: 40),
            _ProviderBlock(provider: sub.provider),

            // ── 7. AUTRES ABONNEMENTS ────────────────────────────────────────
            if (sub.providerSubscriptions.isNotEmpty) ...[
              const SizedBox(height: 40),
              _OtherSubscriptionsSection(
                providerName: sub.provider.name,
                subscriptions: sub.providerSubscriptions,
              ),
            ],

            // ── AVIS CLIENTS ─────────────────────────────────────────────────
            const SizedBox(height: 40),
            _ReviewsSection(
              subscriptionId: widget.subscriptionId,
              totalCount: sub.reviewCount,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Carousel d'images ─────────────────────────────────────────────────────────

class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _ImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: currentIndex);

    return Column(
      children: [
        // Image principale
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 288,
            width: double.infinity,
            child: images.isEmpty
                ? _ImagePlaceholder()
                : PageView.builder(
                    controller: controller,
                    itemCount: images.length,
                    onPageChanged: onChanged,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surface),
                      errorWidget: (_, __, ___) => _ImagePlaceholder(),
                    ),
                  ),
          ),
        ),

        // Thumbnails
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == currentIndex;
                return GestureDetector(
                  onTap: () {
                    controller.animateToPage(i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _ImagePlaceholder(size: 64),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double? size;
  const _ImagePlaceholder({this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.restaurant_outlined, color: AppColors.textLight, size: 48),
      ),
    );
  }
}

// ── Section infos principales ─────────────────────────────────────────────────

class _MainInfoSection extends StatelessWidget {
  final SubscriptionEntity sub;
  const _MainInfoSection({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre + badge disponibilité
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                sub.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _AvailabilityBadge(isAvailable: sub.isAvailable),
          ],
        ),

        // Rating (seulement si > 0)
        if (sub.reviewCount > 0) ...[
          const SizedBox(height: 8),
          JunaRating(rating: sub.rating, reviewCount: sub.reviewCount),
        ],

        // Description
        if (sub.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            sub.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],

        // 3 cartes détail
        const SizedBox(height: 20),
        _DetailCard(
          label: 'TYPE DE REPAS',
          value: sub.type.label,
          description: sub.type.explanation,
        ),
        const SizedBox(height: 8),
        _DetailCard(
          label: 'DURÉE',
          value: sub.duration.label,
          description: sub.duration.explanation,
          subtitle: sub.duration.sublabel,
        ),
        const SizedBox(height: 8),
        if (sub.categories.isNotEmpty)
          _DetailCard(
            label: 'STYLE CULINAIRE',
            value: sub.categories.first.label,
            description: sub.categories.first.explanation,
          ),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFFDCFCE7)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isAvailable
              ? const Color(0xFF166534)
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final String? subtitle;

  const _DetailCard({
    required this.label,
    required this.value,
    required this.description,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section divider avec titre ────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionDivider({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Repas inclus (liste horizontale) ─────────────────────────────────────────

class _MealsHorizontalList extends StatelessWidget {
  final List<MealEntity> meals;
  const _MealsHorizontalList({required this.meals});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: meals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _MealItem(meal: meals[i]),
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final MealEntity meal;
  const _MealItem({required this.meal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                      imageUrl: meal.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _ImagePlaceholder(size: 96),
                    )
                  : _ImagePlaceholder(size: 96),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (meal.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              meal.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Modes de réception ────────────────────────────────────────────────────────

class _DeliveryModesSection extends StatelessWidget {
  final SubscriptionEntity sub;
  const _DeliveryModesSection({required this.sub});

  @override
  Widget build(BuildContext context) {
    final showDelivery =
        sub.provider.acceptsDelivery || sub.deliveryZones.isNotEmpty;
    final showPickup =
        sub.provider.acceptsPickup || sub.pickupPoints.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDelivery) _DeliveryModeCard(
          icon: Icons.delivery_dining_outlined,
          title: 'Livraison à domicile',
          subtitle: 'Le prestataire livre directement chez vous',
        ),
        if (showDelivery && showPickup) const SizedBox(height: 8),
        if (showPickup) _DeliveryModeCard(
          icon: Icons.storefront_outlined,
          title: 'Retrait sur place',
          subtitle: 'Récupérez votre repas directement chez le prestataire',
        ),

        // Zones desservies
        if (sub.deliveryZones.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Zones desservies',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sub.deliveryZones
                .map((zone) => _ZoneChip(label: zone))
                .toList(),
          ),
        ],

        // Points de retrait
        if (sub.pickupPoints.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Points de retrait',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...sub.pickupPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

class _DeliveryModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _DeliveryModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

class _ZoneChip extends StatelessWidget {
  final String label;
  const _ZoneChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Prix & CTA ────────────────────────────────────────────────────────────────

class _PriceCtaCard extends StatelessWidget {
  final SubscriptionEntity sub;
  final bool isAuthenticated;
  final VoidCallback onSubscribe;
  const _PriceCtaCard({
    required this.sub,
    required this.isAuthenticated,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POUR UNE VALEUR DE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatPrice(sub.price),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub.duration.label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: sub.isAvailable ? onSubscribe : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.textLight,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                sub.isAvailable ? 'S\'abonner' : 'Indisponible',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!sub.isAvailable) ...[
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Cet abonnement n\'est pas disponible pour le moment.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bloc Prestataire ──────────────────────────────────────────────────────────

class _ProviderBlock extends StatelessWidget {
  final ProviderEntity provider;
  const _ProviderBlock({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CET ABONNEMENT EST PROPOSÉ PAR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              JunaAvatar(
                imageUrl: provider.avatarUrl.isNotEmpty
                    ? provider.avatarUrl
                    : provider.logo,
                initials: provider.name.isNotEmpty
                    ? provider.name.substring(0, 2).toUpperCase()
                    : '??',
                size: 56,
                showVerifiedBadge: provider.isVerified,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: Color(0xFF3B82F6), size: 18),
                        ],
                      ],
                    ),
                    if (provider.rating > 0) ...[
                      const SizedBox(height: 4),
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

          if (provider.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              provider.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          if (provider.businessAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.city.name.isNotEmpty
                          ? '${provider.businessAddress}, ${provider.city.name}'
                          : provider.businessAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Autres abonnements du provider ────────────────────────────────────────────

class _OtherSubscriptionsSection extends StatelessWidget {
  final String providerName;
  final List<SubscriptionEntity> subscriptions;
  const _OtherSubscriptionsSection({
    required this.providerName,
    required this.subscriptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autres abonnements de $providerName',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subscriptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _OtherSubCard(sub: subscriptions[i]),
          ),
        ),
      ],
    );
  }
}

class _OtherSubCard extends StatelessWidget {
  final SubscriptionEntity sub;
  const _OtherSubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/subscriptions/${sub.id}'),
      child: SizedBox(
        width: 192,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 120,
                child: sub.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: sub.imageUrl,
                        width: 192,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _ImagePlaceholder(),
                      )
                    : _ImagePlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              formatPrice(sub.price),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                _SmallBadge(sub.type.label),
                _SmallBadge(sub.duration.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  const _SmallBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Avis clients ──────────────────────────────────────────────────────────────

class _ReviewsSection extends ConsumerWidget {
  final String subscriptionId;
  final int totalCount;
  const _ReviewsSection(
      {required this.subscriptionId, required this.totalCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync =
        ref.watch(subscriptionReviewsProvider(subscriptionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Avis clients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (totalCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$totalCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        reviewsAsync.when(
          loading: () => Column(
            children: List.generate(
              2,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      JunaSkeleton(width: 36, height: 36, borderRadius: 18),
                      SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        JunaSkeleton.line(width: 100, height: 12),
                        SizedBox(height: 4),
                        JunaSkeleton.line(width: 70, height: 10),
                      ]),
                    ]),
                    SizedBox(height: 12),
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
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          data: (reviews) => reviews.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Aucun avis pour l\'instant.\nSoyez le premier à donner votre avis !',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
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

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    JunaRating(
                      rating: review.rating,
                      showCount: false,
                      size: 12,
                    ),
                  ],
                ),
              ),
              Text(
                review.timeAgo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
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
