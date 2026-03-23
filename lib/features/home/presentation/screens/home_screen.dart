import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/mock_data.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';
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
    // Simule un chargement initial
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final subscriptions = ref.watch(allSubscriptionsProvider);

    final popular = subscriptions.take(4).toList();
    final african = subscriptions
        .where((s) => s.categories.contains(SubscriptionCategory.african))
        .take(4)
        .toList();
    final workWeek = subscriptions
        .where((s) => s.duration == SubscriptionDuration.workWeek)
        .take(4)
        .toList();

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
                          '${greeting()} ${authState.user != null ? ", ${authState.user!.firstName}" : ""} 👋',
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
                                style: AppTypography.bodySmall.copyWith(
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
                  ),
                  // Notifications
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
              preferredSize: const Size.fromHeight(52),
              child: Column(
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
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Section 1 — Populaires
                SectionHeader(
                  title: 'Populaires près de toi',
                  explorerRoute: AppRoutes.explorer,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 300,
                  child: _isLoading
                      ? _buildHorizontalSkeleton()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          itemCount: popular.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (_, i) =>
                              SubscriptionCardLarge(subscription: popular[i]),
                        ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Section 2 — Cuisine Africaine
                SectionHeader(
                  title: 'Cuisine Africaine 🌍',
                  explorerRoute:
                      '${AppRoutes.explorer}?category=${SubscriptionCategory.african.name}',
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 220,
                  child: _isLoading
                      ? _buildHorizontalSkeleton(height: 220, cardWidth: 180)
                      : african.isEmpty
                          ? _buildEmptySection()
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              itemCount: african.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (_, i) => SizedBox(
                                width: 180,
                                child: SubscriptionCardCompact(
                                    subscription: african[i]),
                              ),
                            ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Section 3 — Formules semaine de travail
                SectionHeader(
                  title: 'Formules semaine de travail 💼',
                  explorerRoute:
                      '${AppRoutes.explorer}?duration=${SubscriptionDuration.workWeek.name}',
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 220,
                  child: _isLoading
                      ? _buildHorizontalSkeleton(height: 220, cardWidth: 180)
                      : workWeek.isEmpty
                          ? _buildEmptySection()
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              itemCount: workWeek.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (_, i) => SizedBox(
                                width: 180,
                                child: SubscriptionCardCompact(
                                    subscription: workWeek[i]),
                              ),
                            ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Section 4 — Prestataires
                SectionHeader(title: 'Nos prestataires'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 100,
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
                                  size: 56,
                                  showVerifiedBadge: p.isVerified,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    p.name,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                    ),
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

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSkeleton({
    double height = 300,
    double cardWidth = 280,
  }) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (_, __) => SizedBox(
        width: cardWidth,
        height: height,
        child: const JunaSubscriptionCardSkeleton(),
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
          JunaSkeleton(width: 56, height: 56, borderRadius: 28),
          const SizedBox(height: AppSpacing.xs),
          const JunaSkeleton.line(width: 56, height: 10),
        ],
      ),
    );
  }

  Widget _buildEmptySection() {
    return Center(
      child: Text(
        'Aucun abonnement disponible',
        style: AppTypography.bodySmall,
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
