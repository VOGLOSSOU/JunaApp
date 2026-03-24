import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';
import '../../../home/presentation/widgets/filter_chips_row.dart';

enum SortOption { relevance, priceAsc, priceDesc, rating, newest }

extension SortLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.relevance: return 'Pertinence';
      case SortOption.priceAsc:  return 'Prix croissant';
      case SortOption.priceDesc: return 'Prix décroissant';
      case SortOption.rating:    return 'Mieux notés';
      case SortOption.newest:    return 'Plus récents';
    }
  }
}

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
  SortOption _sort = SortOption.relevance;
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Appliquer les filtres pré-sélectionnés depuis l'accueil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedCategory != null || widget.preselectedDuration != null) {
        ref.read(filterControllerProvider.notifier).applyFromParams(
              category: widget.preselectedCategory,
              duration: widget.preselectedDuration,
            );
      }
    });
    Future.delayed(const Duration(milliseconds: 900),
        () { if (mounted) setState(() => _isLoading = false); });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SubscriptionEntity> _applySort(List<SubscriptionEntity> list) {
    final sorted = [...list];
    switch (_sort) {
      case SortOption.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      default:
        break;
    }
    return sorted;
  }

  List<SubscriptionEntity> _applySearch(List<SubscriptionEntity> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((s) =>
        s.title.toLowerCase().contains(q) ||
        s.provider.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredSubscriptionsProvider);
    final results = _applySort(_applySearch(filtered));
    final filterState = ref.watch(filterControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                children: [
                  // Barre de recherche
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un abonnement...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textLight),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.textLight),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
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
              child: Column(
                children: [
                  const SizedBox(height: 0),

                  // Compteur + tri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLoading
                            ? 'Chargement...'
                            : '${results.length} abonnement${results.length > 1 ? "s" : ""} trouvé${results.length > 1 ? "s" : ""}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showSortPicker(context),
                        child: Row(
                          children: [
                            Text(
                              'Trier : ${_sort.label}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── GRILLE ──────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : results.isEmpty
                      ? _buildEmpty(filterState.hasFilters)
                      : GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: results.length,
                          itemBuilder: (_, i) =>
                              SubscriptionCardCompact(subscription: results[i]),
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

  Widget _buildEmpty(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun abonnement trouvé',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () =>
                  ref.read(filterControllerProvider.notifier).reset(),
              child: Text(
                'Réinitialiser les filtres',
                style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Trier par', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            ...SortOption.values.map((s) => ListTile(
                  title: Text(s.label, style: AppTypography.bodyLarge),
                  trailing: _sort == s
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _sort = s);
                    Navigator.pop(context);
                  },
                  contentPadding: EdgeInsets.zero,
                )),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
