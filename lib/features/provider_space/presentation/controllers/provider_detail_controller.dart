import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../data/repositories/provider_repository.dart';

final providerDetailProvider =
    FutureProvider.autoDispose.family<ProviderEntity, String>((ref, id) async {
  ref.keepAlive();
  return ref.read(providerRepositoryProvider).getProviderById(id);
});

Future<void> refreshProviderDetail(WidgetRef ref, String id) async {
  await ref.read(providerRepositoryProvider).clearProviderCache(id);
  ref.invalidate(providerDetailProvider(id));
}
