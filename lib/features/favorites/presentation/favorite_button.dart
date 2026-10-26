import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/current_account.dart';
import '../../../core/api/api_client.dart';
import '../../../app/theme/app_colors.dart';
import '../../subscriptions/domain/entities/subscription_entity.dart';
import 'favorites_controller.dart';

class FavoriteButton extends ConsumerWidget {
  final SubscriptionEntity subscription;
  const FavoriteButton({super.key, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(currentAccountIdProvider);
    final state = ref.watch(favoritesControllerProvider);
    final selected = account != null &&
        (state.flags[subscription.id] ?? subscription.isFavorite);
    final pending = state.pending.contains(subscription.id);
    return IconButton(
      tooltip: selected ? 'Retirer des favoris' : 'Ajouter aux favoris',
      isSelected: selected,
      onPressed: pending || subscription.id.isEmpty
          ? null
          : () async {
              if (account == null) {
                final redirect = Uri.encodeComponent(
                    GoRouterState.of(context).uri.toString());
                context.push('/login?redirect=$redirect');
                return;
              }
              try {
                await ref
                    .read(favoritesControllerProvider.notifier)
                    .toggle(subscription);
              } catch (error) {
                if (!context.mounted ||
                    ref.read(currentAccountIdProvider) != account) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(extractException(error).message)));
              }
            },
      style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.96),
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8)),
      icon: pending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary))
          : const Icon(Icons.favorite_border_rounded, size: 20),
      selectedIcon: pending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary))
          : const Icon(Icons.favorite_rounded,
              size: 20, color: AppColors.accent),
    );
  }
}
