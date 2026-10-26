import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/subscriptions_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/subscription_entity.dart';

// Une hauteur commune garde les prix alignés et réserve la place aux noms longs.
double subscriptionCardHeight(BuildContext context, {bool hasReviews = true}) =>
    (hasReviews ? 292 : 270) +
    (MediaQuery.textScalerOf(context).scale(14) / 14 - 1).clamp(0, 2) * 160;

class SubscriptionCardLarge extends StatelessWidget {
  final SubscriptionEntity subscription;
  const SubscriptionCardLarge({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 280,
      height: subscriptionCardHeight(context),
      child: SubscriptionCardCompact(subscription: subscription));
}

class SubscriptionCardCompact extends ConsumerWidget {
  final SubscriptionEntity subscription;
  const SubscriptionCardCompact({super.key, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = subscription;
    final isFavorite = ref.watch(favoritesControllerProvider
        .select((favorites) => favorites.contains(sub.id)));
    return Semantics(
      button: true,
      label:
          '${sub.title}, ${sub.provider.name}, ${sub.duration.label}, ${formatPrice(sub.price)} pour toute la durée',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAEDE9)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: sub.id.isEmpty
                ? null
                : () => context.push('/subscriptions/${sub.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 136,
                  width: double.infinity,
                  child: Stack(fit: StackFit.expand, children: [
                    if (sub.imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: sub.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const _MealPlaceholder(),
                        errorWidget: (_, __, ___) => const _MealPlaceholder(),
                      )
                    else
                      const _MealPlaceholder(),
                    Positioned(
                      left: 10,
                      right: 52,
                      top: 10,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(sub.duration.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        tooltip: isFavorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                        isSelected: isFavorite,
                        onPressed: sub.id.isEmpty
                            ? null
                            : () => ref
                                .read(favoritesControllerProvider.notifier)
                                .toggle(sub.id),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.96),
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.all(8),
                        ),
                        icon:
                            const Icon(Icons.favorite_border_rounded, size: 20),
                        selectedIcon: const Icon(Icons.favorite_rounded,
                            size: 20, color: AppColors.accent),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Flexible(
                            child: Text(sub.provider.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: AppColors.textSecondary))),
                        if (sub.provider.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 13,
                              color: Color(0xFF3B82F6),
                              semanticLabel: 'Prestataire vérifié'),
                        ],
                      ]),
                      if (sub.reviewCount > 0) ...[
                        const SizedBox(height: 7),
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFE69B21)),
                          const SizedBox(width: 3),
                          Expanded(
                              child: Text(
                                  '${sub.rating.toStringAsFixed(1)} (${sub.reviewCount} avis)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary))),
                        ]),
                      ],
                      const Spacer(),
                      const Divider(height: 13, color: Color(0xFFF0F1EE)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(formatPrice(sub.price),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            flex: 5,
                            child: Text('pour toute la durée',
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10,
                                    height: 1.2,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealPlaceholder extends StatelessWidget {
  const _MealPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.primarySurface,
        child: Center(
            child: Icon(Icons.restaurant_outlined,
                size: 32, color: AppColors.primary)),
      );
}
