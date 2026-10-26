import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../subscriptions/data/repositories/subscription_repository.dart';
import '../../subscriptions/domain/entities/subscription_entity.dart';

class FavoritePage {
  final List<SubscriptionEntity> items;
  final int page;
  final int totalPages;
  final int total;
  const FavoritePage(
      {required this.items,
      required this.page,
      required this.totalPages,
      required this.total});
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
    (ref) => FavoriteRepository(ref.read(dioProvider)));

class FavoriteRepository {
  final Dio _dio;
  FavoriteRepository(this._dio);

  Future<bool> setFavorite(String id, bool favorite) async {
    try {
      final response = favorite
          ? await _dio
              .post(ApiEndpoints.favorites, data: {'subscriptionId': id})
          : await _dio.delete(ApiEndpoints.favorite(id));
      final data = response.data['data'] as Map;
      if (data['isFavorite'] != favorite || data['subscriptionId'] != id) {
        throw const AppException(
            message: 'Réponse de favoris inattendue. Réessayez.');
      }
      return favorite;
    } on DioException catch (error) {
      throw extractException(error);
    }
  }

  Future<FavoritePage> list({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(ApiEndpoints.favorites,
          queryParameters: {'page': page, 'limit': limit});
      final data = response.data['data'] as Map;
      final pagination = data['pagination'] as Map;
      return FavoritePage(
        items: (data['favorites'] as List)
            .map((value) => SubscriptionRepository.mapSubscription(
                Map<String, dynamic>.from(value as Map)))
            .toList(),
        page: (pagination['page'] as num).toInt(),
        totalPages: (pagination['totalPages'] as num).toInt(),
        total: (pagination['total'] as num).toInt(),
      );
    } on DioException catch (error) {
      throw extractException(error);
    } catch (error) {
      if (error is AppException) rethrow;
      throw const AppException(
          message: 'Impossible de lire vos favoris. Réessayez.');
    }
  }
}
