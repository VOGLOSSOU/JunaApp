import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/mock_data.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';
import '../controllers/location_controller.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/section_header.dart';

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
    final location = ref.watch(locationControllerProvider);
    final city = location.short;
    final all = ref.watch(allSubscriptionsProvider);

    final popular    = all.take(6).toList();
    final recommended = all.reversed.take(6).toList();
    final workWeek   = all.where((s) => s.duration == SubscriptionDuration.workWeek).take(6).toList();
    final weekend    = all.where((s) => s.duration == SubscriptionDuration.weekend).take(6).toList();
    final threeDays  = all.where((s) => s.duration == SubscriptionDuration.threeDays).take(6).toList();
    final monthly    = all.where((s) =>
        s.duration == SubscriptionDuration.month ||
        s.duration == SubscriptionDuration.workMonth).take(6).toList();

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

                // 1 — Populaires
                SectionHeader(
                  title: 'Populaires à $city',
                  explorerRoute: AppRoutes.explorer,
                ),
                const SizedBox(height: AppSpacing.md),
                _isLoading
                    ? _buildRowSkeleton()
                    : _HorizontalCardRow(items: popular),

                const SizedBox(height: AppSpacing.xxl),

                // 2 — Recommandés
                SectionHeader(
                  title: 'Recommandés à $city',
                  explorerRoute: AppRoutes.explorer,
                ),
                const SizedBox(height: AppSpacing.md),
                _isLoading
                    ? _buildRowSkeleton()
                    : _HorizontalCardRow(items: recommended),

                if (workWeek.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'Semaine de travail à $city',
                    explorerRoute:
                        '${AppRoutes.explorer}?duration=${SubscriptionDuration.workWeek.name}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildRowSkeleton()
                      : _HorizontalCardRow(items: workWeek),
                ],

                if (weekend.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'Week-end à $city',
                    explorerRoute:
                        '${AppRoutes.explorer}?duration=${SubscriptionDuration.weekend.name}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildRowSkeleton()
                      : _HorizontalCardRow(items: weekend),
                ],

                if (threeDays.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'Formules 3 jours à $city',
                    explorerRoute:
                        '${AppRoutes.explorer}?duration=${SubscriptionDuration.threeDays.name}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildRowSkeleton()
                      : _HorizontalCardRow(items: threeDays),
                ],

                if (monthly.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'Abonnements du mois à $city',
                    explorerRoute:
                        '${AppRoutes.explorer}?duration=${SubscriptionDuration.month.name}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _isLoading
                      ? _buildRowSkeleton()
                      : _HorizontalCardRow(items: monthly),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Prestataires
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
                                  initials: p.name.substring(0, 2).toUpperCase(),
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

  Widget _buildRowSkeleton() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) => const SizedBox(
          width: 160,
          child: JunaSubscriptionCardSkeleton(),
        ),
      ),
    );
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
    const cities = [
      ('Cotonou', 'BJ'),
      ('Porto-Novo', 'BJ'),
      ('Abomey-Calavi', 'BJ'),
      ('Parakou', 'BJ'),
      ('Lomé', 'TG'),
      ('Abidjan', 'CI'),
      ('Dakar', 'SN'),
    ];

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
            ...cities.map((c) => ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
                  title: Text('${c.$1}, ${c.$2}', style: AppTypography.bodyLarge),
                  onTap: () {
                    ref
                        .read(locationControllerProvider.notifier)
                        .selectCity(c.$1, c.$2);
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

// ── Row horizontal de cartes ───────────────────────────────────────────────────

class _HorizontalCardRow extends StatelessWidget {
  final List<SubscriptionEntity> items;

  const _HorizontalCardRow({required this.items});

  @override
  Widget build(BuildContext context) {
    // Largeur de carte : environ 45% de l'écran, max 180px
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.45).clamp(140.0, 180.0);

    return SizedBox(
      height: 220,
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
