import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../../data/repositories/home_feed_repository.dart';
import '../controllers/location_controller.dart';

class HomeFeedState {
  final List<SubscriptionEntity> popular;
  final List<SubscriptionEntity> recent;
  final List<ProviderEntity> providers;
  final bool isLoading;
  final String? error;

  const HomeFeedState({
    this.popular = const [],
    this.recent = const [],
    this.providers = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty => popular.isEmpty && recent.isEmpty && providers.isEmpty;

  HomeFeedState copyWith({
    List<SubscriptionEntity>? popular,
    List<SubscriptionEntity>? recent,
    List<ProviderEntity>? providers,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HomeFeedState(
      popular: popular ?? this.popular,
      recent: recent ?? this.recent,
      providers: providers ?? this.providers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HomeFeedController extends StateNotifier<HomeFeedState> {
  final HomeFeedRepository _repo;
  final Ref _ref;

  HomeFeedController(this._repo, this._ref) : super(const HomeFeedState()) {
    final cityId = _ref.read(locationControllerProvider).cityId;
    if (cityId != null) load();
  }

  Future<void> load() async {
    final cityId = _ref.read(locationControllerProvider).cityId;
    if (cityId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final feed = await _repo.getHomeFeed(cityId);
      state = state.copyWith(
        isLoading: false,
        popular: feed.popular,
        recent: feed.recent,
        providers: feed.providers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final homeFeedProvider =
    StateNotifierProvider<HomeFeedController, HomeFeedState>((ref) {
  return HomeFeedController(
    ref.read(homeFeedRepositoryProvider),
    ref,
  );
});
