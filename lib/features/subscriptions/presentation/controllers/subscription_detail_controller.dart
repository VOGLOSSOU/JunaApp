import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/home/presentation/controllers/home_feed_controller.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import 'subscriptions_controller.dart';

final subscriptionDetailProvider = FutureProvider.autoDispose
    .family<SubscriptionEntity, String>((ref, id) async {
  // Cherche d'abord dans le feed home (popular + recent)
  final feed = ref.read(homeFeedProvider);
  final fromFeed = [...feed.popular, ...feed.recent]
      .where((s) => s.id == id)
      .firstOrNull;
  if (fromFeed != null) return fromFeed;

  // Cherche dans la liste explorer / subscriptions
  final fromList = ref.read(subscriptionsControllerProvider)
      .items
      .where((s) => s.id == id)
      .firstOrNull;
  if (fromList != null) return fromList;

  // Pas en cache — appel réseau
  return ref.read(subscriptionRepositoryProvider).getSubscriptionById(id);
});

final subscriptionReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewEntity>, String>((ref, id) async {
  return ref.read(subscriptionRepositoryProvider).getReviews(id);
});
