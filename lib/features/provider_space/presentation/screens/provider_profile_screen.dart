import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/mock_data.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_rating.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';

class ProviderProfileScreen extends ConsumerWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = MockData.providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => MockData.providers.first,
    );
    final subscriptions = MockData.subscriptions
        .where((s) => s.provider.id == providerId)
        .toList();
    final reviews =
        MockData.reviews.where((r) => r.providerId == providerId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Bannière
                  CachedNetworkImage(
                    imageUrl: provider.avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.primary),
                  ),
                  // Overlay dégradé
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Infos dans le header
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        JunaAvatar(
                          imageUrl: provider.avatarUrl,
                          initials: provider.name.substring(0, 2).toUpperCase(),
                          size: 64,
                          showVerifiedBadge: false,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      provider.name,
                                      style:
                                          AppTypography.headlineMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (provider.isVerified) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified,
                                              color: Colors.white, size: 11),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Certifié',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: Colors.white70, size: 13),
                                  const SizedBox(width: 3),
                                  Text(
                                    provider.city.name,
                                    style: AppTypography.bodySmall
                                        .copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BODY ────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat bar
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                  child: Row(
                    children: [
                      _StatItem(
                        value: provider.rating.toStringAsFixed(1),
                        label: 'Note moyenne',
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFA726),
                      ),
                      _Divider(),
                      _StatItem(
                        value: '${provider.reviewCount}',
                        label: 'Avis clients',
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: AppColors.primary,
                      ),
                      _Divider(),
                      _StatItem(
                        value: '${subscriptions.length}',
                        label: 'Abonnements',
                        icon: Icons.restaurant_menu_rounded,
                        iconColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Description
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('À propos', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        provider.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Abonnements
                if (subscriptions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                    child: Text('Ses abonnements',
                        style: AppTypography.titleLarge),
                  ),
                  LayoutBuilder(builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 600 ? 3 : 2;
                    final spacing = AppSpacing.md;
                    final itemW = (constraints.maxWidth -
                            AppSpacing.lg * 2 -
                            spacing * (cols - 1)) /
                        cols;
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: subscriptions
                            .map((s) => SizedBox(
                                  width: itemW,
                                  child:
                                      SubscriptionCardCompact(subscription: s),
                                ))
                            .toList(),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: AppSpacing.sm),

                // Avis
                if (reviews.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                    child: Row(
                      children: [
                        Text('Avis clients', style: AppTypography.titleLarge),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '${reviews.length}',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Résumé des étoiles
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              provider.rating.toStringAsFixed(1),
                              style: AppTypography.displayMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            JunaRating(
                                rating: provider.rating,
                                reviewCount: 0,
                                size: 16),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.reviewCount} avis',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Column(
                            children: [5, 4, 3, 2, 1].map((star) {
                              final count = reviews
                                  .where((r) => r.rating.round() == star)
                                  .length;
                              final pct = reviews.isEmpty
                                  ? 0.0
                                  : count / reviews.length;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Text('$star',
                                        style: AppTypography.bodySmall),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star_rounded,
                                        size: 12, color: Color(0xFFFFA726)),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 6,
                                          backgroundColor:
                                              AppColors.surfaceGrey,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  Color(0xFFFFA726)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    SizedBox(
                                      width: 20,
                                      child: Text('$count',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary),
                                          textAlign: TextAlign.right),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...reviews.map((r) => _ReviewTile(review: r)),
                ],

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

class _ReviewTile extends StatelessWidget {
  final MockReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              JunaAvatar(
                initials: review.authorName.substring(0, 2).toUpperCase(),
                size: 36,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.authorName, style: AppTypography.titleMedium),
                    Text(
                      review.date,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              JunaRating(rating: review.rating, reviewCount: 0, size: 13),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            review.comment,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
