import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/geo_modal.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';
import '../controllers/home_feed_controller.dart';
import '../controllers/location_controller.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/section_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _lastCityId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final location = ref.watch(locationControllerProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final filterState = ref.watch(filterControllerProvider);
    final feedState = ref.watch(homeFeedProvider);

    // Reload when city changes
    if (location.cityId != _lastCityId) {
      _lastCityId = location.cityId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(homeFeedProvider.notifier).load();
        if (filterState.hasFilters) {
          ref.read(subscriptionsControllerProvider.notifier).load(refresh: true);
        }
      });
    }

    final city = location.short.isEmpty ? 'votre ville' : location.short;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── APP BAR ───────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 1,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${greeting()}${authState.user != null ? ", ${authState.user!.name}" : ""} 👋',
                          style: AppTypography.titleLarge,
                        ),
                        GestureDetector(
                          onTap: () => _showGeoModal(context),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                location.display,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.primary),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppColors.textPrimary,
                        onPressed: () => context.push(AppRoutes.notifications),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  const FilterChipsRow(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────────────
          filterState.hasFilters
              ? _FilteredBody(city: city)
              : _FeedBody(feedState: feedState, city: city),
        ],
      ),
    );
  }

  void _showGeoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeoModal(),
    );
  }
}

// ── Corps en mode feed (sans filtre) ─────────────────────────────────────────

class _FeedBody extends StatelessWidget {
  final HomeFeedState feedState;
  final String city;

  const _FeedBody({required this.feedState, required this.city});

  @override
  Widget build(BuildContext context) {
    final isLoading = feedState.isLoading && feedState.isEmpty;

    // Skeleton global pendant le premier chargement
    if (isLoading) {
      return SliverPadding(
        padding:
            const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xxxl),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildRowSkeleton(),
            const SizedBox(height: AppSpacing.xxl),
            _buildRowSkeleton(),
            const SizedBox(height: AppSpacing.xxl),
            _buildProvidersSkeleton(),
          ]),
        ),
      );
    }

    // Aucun abonnement dans cette ville → message global, pas de prestataires
    final noSubs = feedState.popular.isEmpty && feedState.recent.isEmpty;
    if (noSubs) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_outlined,
                    size: 72, color: AppColors.textLight),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Aucun abonnement disponible\npour l\'instant à $city',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Les prestataires arrivent bientôt\ndans votre zone.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sections normales (on affiche uniquement celles qui ont du contenu)
    return SliverPadding(
      padding:
          const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xxxl),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (feedState.popular.isNotEmpty) ...[
            SectionHeader(
              title: 'Populaires à $city',
              explorerRoute: AppRoutes.explorer,
            ),
            const SizedBox(height: AppSpacing.md),
            _HorizontalCardRow(items: feedState.popular),
            const SizedBox(height: AppSpacing.xxl),
          ],

          if (feedState.recent.isNotEmpty) ...[
            SectionHeader(
              title: 'Récemment ajoutés à $city',
              explorerRoute: AppRoutes.explorer,
            ),
            const SizedBox(height: AppSpacing.md),
            _HorizontalCardRow(items: feedState.recent),
            const SizedBox(height: AppSpacing.xxl),
          ],

          if (feedState.providers.isNotEmpty) ...[
            SectionHeader(title: 'Nos prestataires à $city'),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 88,
              child: _ProviderRow(providers: feedState.providers),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildRowSkeleton() {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) =>
            const SizedBox(width: 160, child: JunaSubscriptionCardSkeleton()),
      ),
    );
  }

  Widget _buildProvidersSkeleton() {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (_, __) => Column(
          children: [
            JunaSkeleton(width: 52, height: 52, borderRadius: 26),
            const SizedBox(height: AppSpacing.xs),
            const JunaSkeleton.line(width: 52, height: 10),
          ],
        ),
      ),
    );
  }
}

// ── Corps en mode filtré (filtre actif) ──────────────────────────────────────

class _FilteredBody extends ConsumerWidget {
  final String city;

  const _FilteredBody({required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionsControllerProvider);
    final results = ref.watch(filteredSubscriptionsProvider);
    final isLoading = subState.isLoading && results.isEmpty;

    if (isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.65,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, __) => const JunaSubscriptionCardSkeleton(),
            childCount: 6,
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 64, color: AppColors.textLight),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Aucun abonnement trouvé',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(filterControllerProvider.notifier).reset(),
                child: Text(
                  'Réinitialiser les filtres',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => SubscriptionCardCompact(subscription: results[i]),
          childCount: results.length,
        ),
      ),
    );
  }
}

// ── Row horizontal de cartes abonnements ─────────────────────────────────────

class _HorizontalCardRow extends StatelessWidget {
  final List<SubscriptionEntity> items;

  const _HorizontalCardRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final cardWidth =
        (MediaQuery.of(context).size.width * 0.45).clamp(140.0, 180.0);

    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => SizedBox(
          width: cardWidth,
          child: SubscriptionCardCompact(subscription: items[i]),
        ),
      ),
    );
  }
}

// ── Row horizontal de prestataires ───────────────────────────────────────────

class _ProviderRow extends StatelessWidget {
  final List<ProviderEntity> providers;

  const _ProviderRow({required this.providers});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: providers.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
      itemBuilder: (_, i) {
        final p = providers[i];
        return GestureDetector(
          onTap: () => context.push('/providers/${p.id}'),
          child: Column(
            children: [
              JunaAvatar(
                imageUrl: p.avatarUrl,
                initials: p.name.isNotEmpty
                    ? p.name.substring(0, 2).toUpperCase()
                    : '??',
                size: 52,
                showVerifiedBadge: p.isVerified,
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: 60,
                child: Text(
                  p.name,
                  style: AppTypography.bodySmall.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
