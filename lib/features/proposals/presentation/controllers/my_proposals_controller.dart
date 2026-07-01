import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/subscription_proposal_repository.dart';
import '../../domain/entities/subscription_proposal_entity.dart';

class MyProposalsState {
  final List<SubscriptionProposalEntity> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const MyProposalsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  MyProposalsState copyWith({
    List<SubscriptionProposalEntity>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) {
    return MyProposalsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MyProposalsController extends StateNotifier<MyProposalsState> {
  final SubscriptionProposalRepository _repo;

  MyProposalsController(this._repo) : super(const MyProposalsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getMyProposals(page: 1);
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        hasMore: result.items.length < result.total,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repo.getMyProposals(page: nextPage);
      final items = [...state.items, ...result.items];
      state = state.copyWith(
        isLoadingMore: false,
        items: items,
        hasMore: items.length < result.total,
        page: nextPage,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final myProposalsControllerProvider =
    StateNotifierProvider<MyProposalsController, MyProposalsState>((ref) {
  return MyProposalsController(ref.read(subscriptionProposalRepositoryProvider));
});
