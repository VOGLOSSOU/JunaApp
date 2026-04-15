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
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_badge.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../../core/widgets/juna_rating.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/subscriptions_controller.dart';

class SubscriptionDetailScreen extends ConsumerWidget {
  final String subscriptionId;
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSubs = ref.watch(subscriptionsControllerProvider).items;
    final sub = allSubs.isNotEmpty
        ? allSubs.firstWhere(
            (s) => s.id == subscriptionId,
            orElse: () => allSubs.first,
          )
        : null;
    if (sub == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isFav = ref.watch(
        favoritesControllerProvider.select((s) => s.contains(sub.id)));
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // ── SCROLL CONTENT ───────────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // Image + AppBar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.white,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textPrimary),
                  ),
                ),
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
                  background: CachedNetworkImage(
                    imageUrl: sub.imageUrl,
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
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre + rating
                      Text(sub.title, style: AppTypography.headlineLarge),
                      const SizedBox(height: AppSpacing.sm),
                      JunaRating(
                          rating: sub.rating, reviewCount: sub.reviewCount),

                      const SizedBox(height: AppSpacing.lg),

                      // Prestataire
                      Row(
                        children: [
                          JunaAvatar(
                            imageUrl: sub.provider.avatarUrl,
                            initials: sub.provider.name
                                .substring(0, 2)
                                .toUpperCase(),
                            size: 40,
                            showVerifiedBadge: sub.provider.isVerified,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(sub.provider.name,
                                      style: AppTypography.titleMedium),
                                  if (sub.provider.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified,
                                        color: Colors.blue, size: 16),
                                  ],
                                ],
                              ),
                              Text('Prestataire certifié Juna',
                                  style: AppTypography.bodySmall),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),

                      // Infos rapides
                      _InfoRow(
                        icon: Icons.access_time_outlined,
                        label: 'Durée',
                        value: sub.duration.label,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(
                        icon: Icons.restaurant_outlined,
                        label: 'Type',
                        value: sub.type.label,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Zones de livraison',
                        value: sub.deliveryZones.join(', '),
                      ),
                      if (sub.pickupPoints.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _InfoRow(
                          icon: Icons.store_outlined,
                          label: 'Retrait sur place',
                          value: sub.pickupPoints.join(', '),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),

                      // Catégories
                      Text('Catégories', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: sub.categories
                            .map((c) => JunaBadge.category(c))
                            .toList(),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),

                      // Description
                      Text('Description', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        sub.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      // Repas inclus
                      if (sub.meals.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Repas inclus', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.md),
                        ...sub.meals.map((meal) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(meal.name,
                                        style: AppTypography.bodyMedium),
                                  ),
                                ],
                              ),
                            )),
                      ],

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xl),

                      // Avis clients (mock)
                      Text('Avis clients', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      ..._mockReviews.map((r) => _ReviewCard(review: r)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── BOUTON STICKY EN BAS ─────────────────────────────────────────
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
                      Text(
                        sub.duration.label,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: JunaButton(
                      label: 'S\'abonner',
                      onPressed: () {
                        if (!authState.isAuthenticated) {
                          context.push(
                            '${AppRoutes.login}?redirect=${AppRoutes.checkoutDelivery}?subscriptionId=${sub.id}',
                          );
                        } else {
                          context.push(
                            '${AppRoutes.checkoutDelivery}?subscriptionId=${sub.id}',
                          );
                        }
                      },
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium,
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
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
                initials: review['initials'] as String,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['name'] as String,
                        style: AppTypography.labelLarge),
                    JunaRating(
                      rating: (review['rating'] as num).toDouble(),
                      showCount: false,
                      size: 12,
                    ),
                  ],
                ),
              ),
              Text(review['date'] as String,
                  style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            review['comment'] as String,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

const _mockReviews = [
  {
    'initials': 'AD',
    'name': 'Adjoua D.',
    'rating': 5,
    'date': 'Il y a 2 jours',
    'comment':
        'Excellente cuisine, les repas sont toujours chauds et savoureux. Je recommande vivement !',
  },
  {
    'initials': 'KM',
    'name': 'Kofi M.',
    'rating': 4,
    'date': 'Il y a 1 semaine',
    'comment':
        'Très bon rapport qualité-prix. La livraison est parfois en retard mais ça vaut le coup.',
  },
  {
    'initials': 'FB',
    'name': 'Fatou B.',
    'rating': 5,
    'date': 'Il y a 2 semaines',
    'comment': 'Je me suis abonnée depuis 3 mois, jamais déçue. Le riz sauce graine est incroyable.',
  },
];
