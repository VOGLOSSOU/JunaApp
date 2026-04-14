import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../../../core/utils/mock_data.dart';
import '../../../../core/utils/enums.dart';

// Liste complète
final allSubscriptionsProvider = Provider<List<SubscriptionEntity>>(
  (_) => MockData.subscriptions,
);

// Favoris
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

// Filtres actifs
class FilterState {
  final SubscriptionCategory? category;
  final SubscriptionType? type;
  final SubscriptionDuration? duration;
  final String? landmark;

  const FilterState({this.category, this.type, this.duration, this.landmark});

  int get activeCount =>
      (category != null ? 1 : 0) +
      (type != null ? 1 : 0) +
      (duration != null ? 1 : 0) +
      (landmark != null ? 1 : 0);

  bool get hasFilters => activeCount > 0;

  FilterState copyWith({
    SubscriptionCategory? category,
    SubscriptionType? type,
    SubscriptionDuration? duration,
    String? landmark,
    bool clearCategory = false,
    bool clearType = false,
    bool clearDuration = false,
    bool clearLandmark = false,
  }) {
    return FilterState(
      category: clearCategory ? null : (category ?? this.category),
      type: clearType ? null : (type ?? this.type),
      duration: clearDuration ? null : (duration ?? this.duration),
      landmark: clearLandmark ? null : (landmark ?? this.landmark),
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

  void setLandmark(String? l) =>
      state = state.copyWith(landmark: l);

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

// Abonnements filtrés
final filteredSubscriptionsProvider = Provider<List<SubscriptionEntity>>((ref) {
  final all = ref.watch(allSubscriptionsProvider);
  final filters = ref.watch(filterControllerProvider);

  return all.where((s) {
    if (filters.category != null && !s.categories.contains(filters.category)) {
      return false;
    }
    if (filters.type != null && s.type != filters.type) return false;
    if (filters.duration != null && s.duration != filters.duration) return false;
    return true;
  }).toList();
});
