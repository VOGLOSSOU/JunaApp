import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/active_subscription_repository.dart';
import '../../domain/entities/active_subscription_entity.dart';

final activeSubscriptionsProvider =
    FutureProvider.autoDispose<List<ActiveSubscriptionEntity>>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth.isInitializing || !auth.isAuthenticated) {
    return const [];
  }
  ref.keepAlive();
  return ref
      .read(activeSubscriptionRepositoryProvider)
      .getActiveSubscriptions();
});

Future<void> refreshActiveSubscriptions(WidgetRef ref) async {
  await ref.read(activeSubscriptionRepositoryProvider).clearCache();
  ref.invalidate(activeSubscriptionsProvider);
}
