import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/current_account.dart';
import '../../../app/theme/app_colors.dart';
import '../../subscriptions/presentation/widgets/subscription_card.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(favoritesControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(currentAccountIdProvider);
    ref.listen<String?>(currentAccountIdProvider, (previous, next) {
      if (next != null) {
        Future.microtask(() {
          if (mounted) ref.read(favoritesControllerProvider.notifier).load();
        });
      }
    });
    final state = ref.watch(favoritesControllerProvider);
    final controller = ref.read(favoritesControllerProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Mes favoris'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/profile'))),
      body: account == null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.favorite_border_rounded,
                        size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                        'Connectez-vous pour retrouver vos abonnements favoris.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () => context
                            .push('/login?redirect=%2Fprofile%2Ffavorites'),
                        child: const Text('Se connecter')),
                  ])))
          : state.items.isEmpty &&
                  (state.loading || (!state.loaded && state.error == null))
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => controller.load(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (state.items.isEmpty)
                        SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                              state.error == null
                                                  ? Icons
                                                      .favorite_border_rounded
                                                  : Icons.wifi_off_rounded,
                                              size: 48,
                                              color: AppColors.primary),
                                          const SizedBox(height: 16),
                                          Text(
                                              state.error ??
                                                  'Aucun favori pour le moment.',
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 8),
                                          if (state.error == null) ...[
                                            const Text(
                                                'Touchez le cœur d’un abonnement pour le retrouver ici.',
                                                textAlign: TextAlign.center),
                                            TextButton(
                                                onPressed: () =>
                                                    context.go('/explorer'),
                                                child: const Text(
                                                    'Explorer les abonnements')),
                                          ] else
                                            TextButton(
                                                onPressed: () =>
                                                    controller.load(),
                                                child: const Text('Réessayer')),
                                        ]))))
                      else ...[
                        if (state.loading)
                          const SliverToBoxAdapter(
                              child: LinearProgressIndicator()),
                        SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          MediaQuery.sizeOf(context).width < 350
                                              ? 1
                                              : 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      mainAxisExtent: subscriptionCardHeight(
                                          context,
                                          hasReviews: state.items.any(
                                              (item) => item.reviewCount > 0))),
                              delegate: SliverChildBuilderDelegate(
                                  (context, index) => SubscriptionCardCompact(
                                      key: ValueKey(state.items[index].id),
                                      subscription: state.items[index]),
                                  childCount: state.items.length),
                            )),
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                child: Column(children: [
                                  if (state.error != null)
                                    Text(state.error!,
                                        textAlign: TextAlign.center),
                                  if (state.loadingMore)
                                    const CircularProgressIndicator()
                                  else if (state.error != null ||
                                      state.page < state.totalPages)
                                    TextButton(
                                        onPressed: () => controller.load(
                                            more: state.error == null),
                                        child: Text(state.error != null
                                            ? 'Réessayer'
                                            : 'Voir plus')),
                                ]))),
                      ],
                    ],
                  ),
                ),
    );
  }
}
