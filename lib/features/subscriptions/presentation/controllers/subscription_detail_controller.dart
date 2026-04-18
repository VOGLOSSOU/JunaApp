import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/subscription_repository.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/subscription_entity.dart';

final subscriptionDetailProvider = FutureProvider.autoDispose
    .family<SubscriptionEntity, String>((ref, id) async {
  return ref.read(subscriptionRepositoryProvider).getSubscriptionById(id);
});

final subscriptionReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewEntity>, String>((ref, id) async {
  return ref.read(subscriptionRepositoryProvider).getReviews(id);
});
