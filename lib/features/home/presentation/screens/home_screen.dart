import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/mock_data.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/section_header.dart';
import '../../../../core/utils/formatters.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final all = ref.watch(allSubscriptionsProvider);

    final popular = all.take(4).toList();
    final recommended = all.reversed.take(4).toList();
    final workWeek = all.where((s) => s.duration == SubscriptionDuration.workWeek).toList();
    final weekend = all.where((s) => s.duration == SubscriptionDuration.weekend).toList();
    final monthly = all.where((s) =>
        s.duration == SubscriptionDuration.month ||
        s.duration == SubscriptionDuration.workMonth).toList();
    final threeDays = all.where((s) => s.duration == SubscriptionDuration.threeDays).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── APP BAR ─────────────────────────────────────────────────────────
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
                          '${greeting()}${authState.user != null ? ", ${authState.user!.firstName}" : ""} 👋',
                          style: AppTypography.titleLarge,
                        ),
                        GestureDetector(
                          onTap: () => _showCityPicker(context),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                'Cotonou, Bénin',
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
                        onPressed: () {},
                      ),
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
                              '3',
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
              preferredSize: const Size.fromHeight(48),
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

          // ── BODY ────────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xl, bottom: AppSpacing.xxxl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Section 1 — Populaires
                SectionHeader(title: 'Populaires près de chez toi'),
                const SizedBox(height: AppSpacing.md),
                _isLoading
                    ? _buildGridSkeleton()
                    : _ResponsiveGrid(items: popular),

                const SizedBox(height: AppSpacing.xxl),

                // Section 2 — Recommandés
                SectionHeader(title: 'Recommandés pour vous'),
                const SizedBox(height: AppSpacing.md),
                _isLoading
                    ? _buildGridSkeleton()
                    : _ResponsiveGrid(items: recommended),

                if (workWeek.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(title: 'Semaine de travail près de chez vous'),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildGridSkeleton()
                      : _ResponsiveGrid(items: workWeek),
                ],

                if (weekend.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(title: 'Week-end près de chez vous'),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildGridSkeleton()
                      : _ResponsiveGrid(items: weekend),
                ],

                if (threeDays.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(title: 'Formules 3 jours près de chez vous'),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildGridSkeleton()
                      : _ResponsiveGrid(items: threeDays),
                ],

                if (monthly.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(title: 'Abonnements du mois près de chez vous'),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildGridSkeleton()
                      : _ResponsiveGrid(items: monthly),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Section prestataires
                SectionHeader(title: 'Nos prestataires'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 88,
                  child: _isLoading
                      ? _buildProvidersSkeleton()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          itemCount: MockData.providers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.lg),
                          itemBuilder: (_, i) {
                            final p = MockData.providers[i];
                            return Column(
                              children: [
                                JunaAvatar(
                                  imageUrl: p.avatarUrl,
                                  initials: p.name
                                      .substring(0, 2)
                                      .toUpperCase(),
                                  size: 52,
                                  showVerifiedBadge: p.isVerified,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    p.name,
                                    style: AppTypography.bodySmall
                                        .copyWith(fontSize: 10),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = _columnCount(constraints.maxWidth);
      final itemWidth =
          (constraints.maxWidth - AppSpacing.lg * 2 - AppSpacing.md * (cols - 1)) /
              cols;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(
            cols * 2,
            (_) => SizedBox(
              width: itemWidth,
              child: const JunaSubscriptionCardSkeleton(),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildProvidersSkeleton() {
    return ListView.separated(
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
    );
  }

  void _showCityPicker(BuildContext context) {
    final cities = ['Cotonou', 'Porto-Novo', 'Abomey-Calavi', 'Parakou'];
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
            Text('Choisir une ville', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            ...cities.map((city) => ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
                  title: Text(city, style: AppTypography.bodyLarge),
                  onTap: () => Navigator.pop(context),
                  contentPadding: EdgeInsets.zero,
                )),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ── Grille responsive ──────────────────────────────────────────────────────────

int _columnCount(double width) {
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
}

class _ResponsiveGrid extends StatelessWidget {
  final List<SubscriptionEntity> items;

  const _ResponsiveGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = _columnCount(constraints.maxWidth);
      final spacing = AppSpacing.md;
      final itemWidth =
          (constraints.maxWidth - AppSpacing.lg * 2 - spacing * (cols - 1)) /
              cols;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((s) => SizedBox(
                    width: itemWidth,
                    child: SubscriptionCardCompact(subscription: s),
                  ))
              .toList(),
        ),
      );
    });
  }
}
