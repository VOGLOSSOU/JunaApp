import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../../../core/utils/enums.dart';
import '../../../home/presentation/controllers/location_controller.dart';

// ── Favoris ──────────────────────────────────────────────────────────────────

class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController() : super({});

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  bool isFavorite(String id) => state.contains(id);
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, Set<String>>(
  (_) => FavoritesController(),
);

// ── Filtres ───────────────────────────────────────────────────────────────────

class FilterState {
  final SubscriptionCategory? category;
  final SubscriptionType? type;
  final SubscriptionDuration? duration;
  final String? landmarkId;

  const FilterState({this.category, this.type, this.duration, this.landmarkId});

  int get activeCount =>
      (category != null ? 1 : 0) +
      (type != null ? 1 : 0) +
      (duration != null ? 1 : 0) +
      (landmarkId != null ? 1 : 0);

  bool get hasFilters => activeCount > 0;

  FilterState copyWith({
    SubscriptionCategory? category,
    SubscriptionType? type,
    SubscriptionDuration? duration,
    String? landmarkId,
    bool clearCategory = false,
    bool clearType = false,
    bool clearDuration = false,
    bool clearLandmark = false,
  }) {
    return FilterState(
      category: clearCategory ? null : (category ?? this.category),
      type: clearType ? null : (type ?? this.type),
      duration: clearDuration ? null : (duration ?? this.duration),
      landmarkId: clearLandmark ? null : (landmarkId ?? this.landmarkId),
    );
  }

  FilterState clear() => const FilterState();
}

class FilterController extends StateNotifier<FilterState> {
  FilterController() : super(const FilterState());

  void setCategory(SubscriptionCategory? c) =>
      state = c == state.category
          ? state.copyWith(clearCategory: true)
          : state.copyWith(category: c);

  void setType(SubscriptionType? t) =>
      state = t == null
          ? state.copyWith(clearType: true)
          : t == state.type
              ? state.copyWith(clearType: true)
              : state.copyWith(type: t);

  void setDuration(SubscriptionDuration? d) =>
      state = state.copyWith(duration: d);

  void setLandmark(String? id) => state = state.copyWith(landmarkId: id);

  void reset() => state = const FilterState();

  void applyFromParams({String? category, String? duration}) {
    final cat = category != null
        ? SubscriptionCategory.values.where((c) => c.name == category).firstOrNull
        : null;
    final dur = duration != null
        ? SubscriptionDuration.values.where((d) => d.name == duration).firstOrNull
        : null;
    state = FilterState(category: cat, duration: dur);
  }
}

final filterControllerProvider =
    StateNotifierProvider<FilterController, FilterState>(
  (_) => FilterController(),
);

// ── État de la liste ──────────────────────────────────────────────────────────

class SubscriptionsState {
  final List<SubscriptionEntity> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final String sort;
  final String search;

  const SubscriptionsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.sort = 'popular',
    this.search = '',
  });

  bool get hasMore => currentPage < totalPages;

  SubscriptionsState copyWith({
    List<SubscriptionEntity>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    String? sort,
    String? search,
    bool clearError = false,
  }) {
    return SubscriptionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      sort: sort ?? this.sort,
      search: search ?? this.search,
    );
  }
}

// ── Contrôleur principal ──────────────────────────────────────────────────────

class SubscriptionsController extends StateNotifier<SubscriptionsState> {
  final SubscriptionRepository _repo;
  final Ref _ref;

  SubscriptionsController(this._repo, this._ref)
      : super(const SubscriptionsState());

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;

    final filters = _ref.read(filterControllerProvider);
    final location = _ref.read(locationControllerProvider);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: refresh ? [] : state.items,
      currentPage: refresh ? 1 : state.currentPage,
    );

    try {
      final result = await _repo.getSubscriptions(
        page: 1,
        limit: 20,
        cityId: location.cityId,
        category: filters.category?.apiValue,
        type: filters.type?.apiValue,
        duration: filters.duration?.apiValue,
        landmarkId: filters.landmarkId,
        sort: state.sort,
        search: state.search.isNotEmpty ? state.search : null,
      );
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        currentPage: 1,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    final filters = _ref.read(filterControllerProvider);
    final location = _ref.read(locationControllerProvider);
    final nextPage = state.currentPage + 1;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repo.getSubscriptions(
        page: nextPage,
        limit: 20,
        cityId: location.cityId,
        category: filters.category?.apiValue,
        type: filters.type?.apiValue,
        duration: filters.duration?.apiValue,
        landmarkId: filters.landmarkId,
        sort: state.sort,
        search: state.search.isNotEmpty ? state.search : null,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        currentPage: nextPage,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> setSort(String sort) async {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort, items: [], currentPage: 1, totalPages: 1);
    await load();
  }

  Future<void> setSearch(String query) async {
    if (state.search == query) return;
    state = state.copyWith(search: query, items: [], currentPage: 1, totalPages: 1);
    await load();
  }
}

final subscriptionsControllerProvider =
    StateNotifierProvider<SubscriptionsController, SubscriptionsState>((ref) {
  final ctrl = SubscriptionsController(
    ref.read(subscriptionRepositoryProvider),
    ref,
  );
  ctrl.load();
  return ctrl;
});

// ── Provider de liste filtrée (backend gère le filtrage) ─────────────────────

final filteredSubscriptionsProvider = Provider<List<SubscriptionEntity>>((ref) {
  return ref.watch(subscriptionsControllerProvider).items;
});
