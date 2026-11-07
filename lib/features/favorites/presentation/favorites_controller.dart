import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/current_account.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/api/api_client.dart';
import '../../subscriptions/domain/entities/subscription_entity.dart';
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
  int _request = 0;

  // Synchronisation optimiste, par abonnement :
  // - _confirmed : dernier état connu du serveur avant la synchro en cours ;
  // - _wanted : dernier choix de l'utilisateur, envoyé quand la requête en
  //   cours se termine (plusieurs appuis rapides = une seule valeur finale) ;
  // - _removed : position d'une ligne retirée de « Mes favoris », pour la
  //   remettre à sa place si le serveur refuse.
  final Map<String, bool> _confirmed = {};
  final Map<String, bool> _wanted = {};
  final Map<String, (int, SubscriptionEntity)> _removed = {};

  FavoritesController(this.repository, this.accountId)
      : super(const FavoritesState());

  /// Bascule le favori immédiatement, puis synchronise avec le serveur.
  ///
  /// Le Future se termine quand le serveur a enregistré le dernier choix. En
  /// cas d'échec, l'état confirmé est rétabli et l'erreur est relancée. Un
  /// appui pendant une synchronisation en cours se termine tout de suite :
  /// c'est la synchronisation déjà lancée qui enverra ce nouveau choix.
  Future<void> toggle(SubscriptionEntity sub) async {
    if (accountId == null) throw AppException.unauthorized();
    final id = sub.id;
    final current = state.flags[id] ?? sub.isFavorite;
    _confirmed.putIfAbsent(id, () => current);
    _wanted[id] = !current;
    _show(sub, !current);
    if (state.pending.contains(id)) return;

    state = state.copyWith(pending: {...state.pending, id});
    try {
      while (_wanted[id] != _confirmed[id]) {
        final target = _wanted[id]!;
        await repository.setFavorite(id, target);
        if (!mounted) return;
        _confirmed[id] = target;
      }
      _settle(id);
      // « Mes favoris » doit afficher un abonnement qui vient d'être ajouté.
      if (state.loaded || state.loading) unawaited(load());
    } catch (_) {
      if (!mounted) return;
      final confirmed = _confirmed[id]!;
      _settle(id);
      _show(sub, confirmed);
      rethrow;
    } finally {
      if (mounted) {
        state = state.copyWith(pending: {...state.pending}..remove(id));
      }
    }
  }

  void _settle(String id) {
    _confirmed.remove(id);
    _wanted.remove(id);
  }

  void _show(SubscriptionEntity sub, bool favorite) {
    var items = state.items;
    if (!favorite) {
      final index = items.indexWhere((item) => item.id == sub.id);
      if (index >= 0) {
        _removed[sub.id] = (index, items[index]);
        items = [...items]..removeAt(index);
      }
    } else {
      final removed = _removed.remove(sub.id);
      if (removed != null && !items.any((item) => item.id == sub.id)) {
        final (index, item) = removed;
        items = [...items]..insert(index.clamp(0, items.length), item);
      }
    }
    state =
        state.copyWith(flags: {...state.flags, sub.id: favorite}, items: items);
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
      // Un choix pas encore confirmé par le serveur reste prioritaire sur une
      // liste chargée avant lui.
      final unique = {
        for (final item in items)
          if (_wanted[item.id] != false) item.id: item
      };
      state = state.copyWith(
          items: unique.values.toList(),
          loaded: true,
          loading: false,
          loadingMore: false,
          page: result.page,
          totalPages: result.totalPages,
          flags: {
            ...state.flags,
            for (final item in result.items)
              if (!_wanted.containsKey(item.id)) item.id: true
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
// Les cœurs de tous les écrans lisent `flags` : un changement ici se voit
// partout sans recharger l'accueil, Explorer ou les détails.
final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final accountId = ref.watch(currentAccountIdProvider);
  return FavoritesController(ref.watch(favoriteRepositoryProvider), accountId);
});
