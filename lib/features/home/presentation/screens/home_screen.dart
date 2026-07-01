import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/geo_modal.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';
import '../controllers/home_feed_controller.dart';
import '../controllers/location_controller.dart';
import '../widgets/filter_chips_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      ref.read(notificationsControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final location = ref.watch(locationControllerProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final filterState = ref.watch(filterControllerProvider);
    final feedState = ref.watch(homeFeedProvider);

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
                              Flexible(
                                child: Text(
                                  location.display,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  authState.user == null
                      ? GestureDetector(
                          onTap: () => context.push(AppRoutes.login),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.25),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 15, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Se connecter',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              color: AppColors.textPrimary,
                              onPressed: () =>
                                  context.push(AppRoutes.notifications),
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
              : _FeedBody(
                  feedState: feedState,
                  location: location,
                  city: city,
                  onRetry: () => ref.read(homeFeedProvider.notifier).load(),
                  onShowGeoModal: () => _showGeoModal(context),
                ),
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
  final CityState location;
  final String city;
  final VoidCallback onRetry;
  final VoidCallback onShowGeoModal;

  const _FeedBody({
    required this.feedState,
    required this.location,
    required this.city,
    required this.onRetry,
    required this.onShowGeoModal,
  });

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
            // skeleton du titre principal
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JunaSkeleton.line(width: 260, height: 20),
                  SizedBox(height: 6),
                  JunaSkeleton.line(width: 180, height: 18),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // skeleton sous-section 1
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: JunaSkeleton.line(width: 200, height: 15),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildRowSkeleton(),
            const SizedBox(height: AppSpacing.xl),
            // skeleton sous-section 2
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: JunaSkeleton.line(width: 180, height: 15),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildRowSkeleton(),
            const SizedBox(height: AppSpacing.xxl),
            // skeleton prestataires
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: JunaSkeleton.line(width: 230, height: 20),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
                itemBuilder: (_, __) => const Column(
                  children: [
                    JunaSkeleton(width: 64, height: 64, borderRadius: 32),
                    SizedBox(height: 6),
                    JunaSkeleton.line(width: 60, height: 12),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
    }

    // Erreur API → message d'erreur avec retry
    if (feedState.error != null && feedState.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 64, color: AppColors.textLight),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Impossible de charger le contenu',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Vérifiez votre connexion et réessayez.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Aucun contenu dans cette ville
    final noSubs = feedState.popular.isEmpty &&
        feedState.recent.isEmpty &&
        feedState.providers.isEmpty;
    if (noSubs) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  location.city.isEmpty
                      ? Icons.location_off_rounded
                      : Icons.restaurant_outlined,
                  size: 64,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  location.city.isEmpty
                      ? 'Localisation non définie'
                      : 'Aucun abonnement disponible',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  location.city.isEmpty
                      ? 'Choisissez votre ville pour voir les abonnements disponibles près de vous.'
                      : 'Les prestataires arrivent bientôt\ndans votre zone.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (location.city.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onShowGeoModal,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Choisir ma ville'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Section unifiée "Découvrir"
    return SliverPadding(
      padding:
          const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xxxl),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (feedState.popular.isNotEmpty || feedState.recent.isNotEmpty)
            _DiscoverSection(
              popular: feedState.popular,
              recent: feedState.recent,
              city: city,
            ),

          if (feedState.providers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _ProvidersSection(
              providers: feedState.providers,
              city: city,
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
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) =>
            const SizedBox(width: 150, child: JunaSubscriptionCardSkeleton()),
      ),
    );
  }

}

// ── Section prestataires ──────────────────────────────────────────────────────

class _ProvidersSection extends StatelessWidget {
  final List<ProviderEntity> providers;
  final String city;

  const _ProvidersSection({required this.providers, required this.city});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Qui cuisine pour vous à $city ?',
            style: AppTypography.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (_, i) => _ProviderCard(provider: providers[i]),
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderEntity provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        provider.avatarUrl.isNotEmpty ? provider.avatarUrl : provider.logo;
    final initials = provider.name.isNotEmpty
        ? provider.name.substring(0, provider.name.length.clamp(0, 2)).toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => context.push('/providers/${provider.id}'),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + badge vérifié
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySurface,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                if (provider.isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Nom
            Text(
              provider.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Note (si disponible)
            if (provider.rating > 0) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 11, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 2),
                  Text(
                    provider.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sous-titre de section (avec trait coloré) ─────────────────────────────────

class _SubSectionHeader extends StatelessWidget {
  final String label;
  const _SubSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(label, style: AppTypography.labelLarge),
    );
  }
}

// ── Section "Découvrir des abonnements" (populaires + récents) ───────────────

class _DiscoverSection extends StatelessWidget {
  final List<SubscriptionEntity> popular;
  final List<SubscriptionEntity> recent;
  final String city;

  const _DiscoverSection({
    required this.popular,
    required this.recent,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre principal + lien unique ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Abonnements à $city',
                  style: AppTypography.headlineMedium,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.explorer),
                child: Text(
                  'Voir tout →',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Sous-section : populaires ────────────────────────────────────
        if (popular.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SubSectionHeader(label: 'Les plus populaires'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalCardRow(items: popular),
        ],

        // ── Sous-section : récents ───────────────────────────────────────
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SubSectionHeader(label: 'Les plus récents'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalCardRow(items: recent),
        ],
      ],
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

class _HorizontalCardRow extends StatefulWidget {
  final List<SubscriptionEntity> items;

  const _HorizontalCardRow({required this.items});

  @override
  State<_HorizontalCardRow> createState() => _HorizontalCardRowState();
}

class _HorizontalCardRowState extends State<_HorizontalCardRow> {
  final _controller = ScrollController();
  bool _showArrow = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_controller.hasClients) return;
      final atEnd = _controller.offset >= _controller.position.maxScrollExtent - 8;
      if (atEnd != !_showArrow) setState(() => _showArrow = !atEnd);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollForward(double cardWidth) {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      (_controller.offset + cardWidth + AppSpacing.md).clamp(
        0.0,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = ((screenWidth - AppSpacing.lg - AppSpacing.md) / 2.15)
        .clamp(130.0, 170.0);

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) => SizedBox(
              width: cardWidth,
              child: SubscriptionCardCompact(subscription: widget.items[i]),
            ),
          ),
          // Flèche de scroll
          if (_showArrow && widget.items.length > 2)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _scrollForward(cardWidth),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

