import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../auth/presentation/screens/geo_modal.dart';
import '../../../home/presentation/controllers/location_controller.dart';
import '../../../home/presentation/widgets/filter_chips_row.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';

// ── Sort options ──────────────────────────────────────────────────────────────

enum SortOption { popular, newest, priceAsc, priceDesc, rating }

extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.popular:   return 'Populaires';
      case SortOption.newest:    return 'Plus récents';
      case SortOption.priceAsc:  return 'Prix croissant';
      case SortOption.priceDesc: return 'Prix décroissant';
      case SortOption.rating:    return 'Mieux notés';
    }
  }

  String get apiValue {
    switch (this) {
      case SortOption.popular:   return 'popular';
      case SortOption.newest:    return 'recent';
      case SortOption.priceAsc:  return 'price_asc';
      case SortOption.priceDesc: return 'price_desc';
      case SortOption.rating:    return 'rating';
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ExplorerScreen extends ConsumerStatefulWidget {
  final String? preselectedCategory;
  final String? preselectedDuration;

  const ExplorerScreen({
    super.key,
    this.preselectedCategory,
    this.preselectedDuration,
  });

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  SortOption _sort = SortOption.popular;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedCategory != null ||
          widget.preselectedDuration != null) {
        ref.read(filterControllerProvider.notifier).applyFromParams(
              category: widget.preselectedCategory,
              duration: widget.preselectedDuration,
            );
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(subscriptionsControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(subscriptionsControllerProvider.notifier).setSearch(value);
    });
  }

  void _onSortSelected(SortOption option) {
    setState(() => _sort = option);
    ref
        .read(subscriptionsControllerProvider.notifier)
        .setSort(option.apiValue);
  }

  void _showGeoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GeoModal(),
    );
  }

  void _showSortPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Trier par', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            ...SortOption.values.map(
              (s) => ListTile(
                title: Text(s.label, style: AppTypography.bodyLarge),
                trailing: _sort == s
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _onSortSelected(s);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);
    final subState = ref.watch(subscriptionsControllerProvider);
    final items = ref.watch(filteredSubscriptionsProvider);

    ref.listen(filterControllerProvider, (_, __) {
      if (ref.read(locationControllerProvider).cityId != null) {
        ref.read(subscriptionsControllerProvider.notifier).load(refresh: true);
      }
    });

    final hasCity = location.cityId != null;
    final isFirstLoad = subState.isLoading && items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    enabled: hasCity,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un abonnement...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textLight),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.textLight),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(subscriptionsControllerProvider
                                        .notifier)
                                    .setSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Container(
              color: AppColors.white,
              child: const FilterChipsRow(),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFirstLoad
                        ? 'Chargement...'
                        : hasCity
                            ? '${subState.totalPages > 1 ? "+" : ""}${items.length} abonnement${items.length > 1 ? "s" : ""}'
                            : '',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (hasCity)
                    GestureDetector(
                      onTap: () => _showSortPicker(context),
                      child: Row(
                        children: [
                          Text(
                            'Trier : ${_sort.label}',
                            style: AppTypography.labelSmall
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
            const Divider(height: 1),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: !hasCity
                  ? _buildNoCity(context)
                  : isFirstLoad
                      ? _buildSkeleton()
                      : subState.error != null && items.isEmpty
                          ? _buildError(subState.error!)
                          : items.isEmpty
                              ? _buildEmpty()
                              : _buildGrid(items, subState.isLoadingMore,
                                  subState.hasMore),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCity(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Localisation non définie',
              style: AppTypography.titleMedium
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choisissez votre ville pour voir les abonnements disponibles près de vous.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showGeoModal(context),
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Choisir ma ville'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const JunaSubscriptionCardSkeleton(),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: AppSpacing.lg),
          Text('Impossible de charger les abonnements',
              style: AppTypography.titleMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () =>
                ref.read(subscriptionsControllerProvider.notifier).load(refresh: true),
            child: Text('Réessayer',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final filterState = ref.watch(filterControllerProvider);
    final city = ref.watch(locationControllerProvider).city;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: AppSpacing.lg),
          Text(
            city.isNotEmpty
                ? 'Aucun abonnement trouvé à $city'
                : 'Aucun abonnement trouvé',
            style: AppTypography.titleMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (filterState.hasFilters) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () =>
                  ref.read(filterControllerProvider.notifier).reset(),
              child: Text('Réinitialiser les filtres',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(
      List items, bool isLoadingMore, bool hasMore) {
    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.65,
      ),
      itemCount: items.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (_, i) {
        if (i >= items.length) {
          return const JunaSubscriptionCardSkeleton();
        }
        return SubscriptionCardCompact(subscription: items[i]);
      },
    );
  }
}
