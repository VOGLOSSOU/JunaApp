import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/current_account.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/api/api_client.dart';
import '../../subscriptions/domain/entities/subscription_entity.dart';
import '../../subscriptions/presentation/controllers/subscription_detail_controller.dart';
import '../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../provider_space/presentation/controllers/provider_detail_controller.dart';
import '../../home/presentation/controllers/home_feed_controller.dart';
import '../data/favorite_repository.dart';

class FavoritesState {
  final List<SubscriptionEntity> items;
  final Map<String, bool> flags;
  final Set<String> pending;
  final bool loading;
  final bool loadingMore;
  final bool loaded;
  final int page;
  final int totalPages;
  final String? error;
  const FavoritesState(
      {this.items = const [],
      this.flags = const {},
      this.pending = const {},
      this.loading = false,
      this.loadingMore = false,
      this.loaded = false,
      this.page = 0,
      this.totalPages = 0,
      this.error});

  FavoritesState copyWith(
          {List<SubscriptionEntity>? items,
          Map<String, bool>? flags,
          Set<String>? pending,
          bool? loading,
          bool? loadingMore,
          bool? loaded,
          int? page,
          int? totalPages,
          String? error,
          bool clearError = false}) =>
      FavoritesState(
          items: items ?? this.items,
          flags: flags ?? this.flags,
          pending: pending ?? this.pending,
          loading: loading ?? this.loading,
          loadingMore: loadingMore ?? this.loadingMore,
          loaded: loaded ?? this.loaded,
          page: page ?? this.page,
          totalPages: totalPages ?? this.totalPages,
          error: clearError ? null : error ?? this.error);
}

class FavoritesController extends StateNotifier<FavoritesState> {
  final FavoriteRepository repository;
  final String? accountId;
  final void Function(SubscriptionEntity)? onChanged;
  int _request = 0;
  FavoritesController(this.repository, this.accountId, {this.onChanged})
      : super(const FavoritesState());

  Future<void> toggle(SubscriptionEntity sub) async {
    if (accountId == null) throw AppException.unauthorized();
    if (state.pending.contains(sub.id)) return;
    final wasFavorite = state.flags[sub.id] ?? sub.isFavorite;
    state = state.copyWith(pending: {...state.pending, sub.id});
    try {
      final favorite = await repository.setFavorite(sub.id, !wasFavorite);
      if (!mounted) return;
      _request++;
      final shouldReload = state.loaded || state.loading;
      state = state.copyWith(
          flags: {...state.flags, sub.id: favorite},
          items: favorite
              ? state.items
              : state.items.where((item) => item.id != sub.id).toList());
      onChanged?.call(sub);
      if (shouldReload) unawaited(load());
    } finally {
      if (mounted) {
        state = state.copyWith(pending: {...state.pending}..remove(sub.id));
      }
    }
  }

  Future<void> load({bool more = false}) async {
    if (accountId == null ||
        (more &&
            (state.loading ||
                state.loadingMore ||
                state.page >= state.totalPages))) {
      return;
    }
    final request = ++_request;
    final page = more ? state.page + 1 : 1;
    state = state.copyWith(loading: !more, loadingMore: more, clearError: true);
    try {
      final result = await repository.list(page: page);
      if (!mounted || request != _request) return;
      final items = more ? [...state.items, ...result.items] : result.items;
      final unique = {for (final item in items) item.id: item};
      state = state.copyWith(
          items: unique.values.toList(),
          loaded: true,
          loading: false,
          loadingMore: false,
          page: result.page,
          totalPages: result.totalPages,
          flags: {
            ...state.flags,
            for (final item in result.items) item.id: true
          },
          clearError: true);
    } catch (error) {
      if (!mounted || request != _request) return;
      state = state.copyWith(
          loading: false,
          loadingMore: false,
          error: extractException(error).message);
    }
  }
}

// Reconstruit automatiquement l'état lors d'une connexion, déconnexion ou changement de compte.
final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final accountId = ref.watch(currentAccountIdProvider);
  return FavoritesController(ref.watch(favoriteRepositoryProvider), accountId,
      onChanged: (sub) {
    ref.invalidate(subscriptionDetailProvider(sub.id));
    if (sub.provider.id.isNotEmpty) {
      ref.invalidate(providerDetailProvider(sub.provider.id));
    }
    ref.invalidate(homeFeedProvider);
    unawaited(
        ref.read(subscriptionsControllerProvider.notifier).load(refresh: true));
  });
});
