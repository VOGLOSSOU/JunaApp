import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/core/errors/app_exception.dart';
import 'package:juna/features/favorites/data/favorite_repository.dart';
import 'package:juna/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:juna/features/subscriptions/data/repositories/subscription_repository.dart';

SubscriptionEntity favoriteSample(
        {String id = 'sub-1', bool saved = false, bool available = true}) =>
    SubscriptionRepository.mapSubscription({
      'id': id,
      'name': 'Formule midi',
      'price': 1000,
      'isFavorite': saved,
      'isAvailable': available,
      'provider': {'id': 'provider-1', 'name': 'Prestataire test'}
    });

class FakeFavoriteRepository extends Fake implements FavoriteRepository {
  final List<(String, bool)> mutations = [];
  final List<int> pages = [];
  bool fail = false;
  Completer<bool>? blockedMutation;
  Completer<FavoritePage>? blockedList;
  List<SubscriptionEntity> items = [];
  @override
  Future<bool> setFavorite(String id, bool favorite) async {
    mutations.add((id, favorite));
    if (fail) throw AppException.network();
    if (blockedMutation != null) return blockedMutation!.future;
    return favorite;
  }

  @override
  Future<FavoritePage> list({int page = 1, int limit = 20}) async {
    pages.add(page);
    if (fail) throw AppException.network();
    if (blockedList != null) return blockedList!.future;
    return FavoritePage(
        items: items, page: page, totalPages: 2, total: items.length * 2);
  }
}
