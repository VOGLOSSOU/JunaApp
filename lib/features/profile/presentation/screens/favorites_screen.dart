import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesControllerProvider);
    final all = ref.watch(subscriptionsControllerProvider).items;
    final favorites = all.where((s) => favIds.contains(s.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mes favoris'),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_outline,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aucun favori pour l\'instant',
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Appuyez sur ♡ pour sauvegarder\nun abonnement',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
              itemCount: favorites.length,
              itemBuilder: (_, i) =>
                  SubscriptionCardCompact(subscription: favorites[i]),
            ),
    );
  }
}
