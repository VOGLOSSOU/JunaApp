import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/active_subscription_repository.dart';
import '../../domain/entities/active_subscription_entity.dart';

final activeSubscriptionsProvider =
    FutureProvider.autoDispose<List<ActiveSubscriptionEntity>>((ref) {
  return ref
      .read(activeSubscriptionRepositoryProvider)
      .getActiveSubscriptions();
});
