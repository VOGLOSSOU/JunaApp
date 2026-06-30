import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscriptions/domain/entities/meal_entity.dart';
import '../../data/repositories/meal_repository.dart';

final mealDetailProvider = FutureProvider.autoDispose
    .family<MealEntity, String>((ref, id) async {
  ref.keepAlive();
  return ref.read(mealRepositoryProvider).getMealById(id);
});

class OtherMealsParams {
  final String providerId;
  final String excludeMealId;

  const OtherMealsParams({
    required this.providerId,
    required this.excludeMealId,
  });

  @override
  bool operator ==(Object other) =>
      other is OtherMealsParams &&
      other.providerId == providerId &&
      other.excludeMealId == excludeMealId;

  @override
  int get hashCode => Object.hash(providerId, excludeMealId);
}

final otherMealsProvider = FutureProvider.autoDispose
    .family<List<MealEntity>, OtherMealsParams>((ref, params) async {
  return ref.read(mealRepositoryProvider).getOtherMealsByProvider(
        params.providerId,
        excludeMealId: params.excludeMealId,
      );
});
