import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  // ── Inscription ───────────────────────────────────────────────────────────
  Future<({ApiUserModel user, AuthTokensModel tokens})> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _dio.post(ApiEndpoints.register, data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });

    final body = response.data;
    final success = body['success'] as bool?;
    if (success != true) {
      final message = body['message'] as String?;
      final errorField = body['error'] as Map?;
      final code = errorField?['code'] as String?;
      throw AppException.fromCode(code, message, response.statusCode);
    }

    final data = body['data'];
    final user = ApiUserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens =
        AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>);
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return (user: user, tokens: tokens);
  }

  // ── Connexion ─────────────────────────────────────────────────────────────
  Future<({ApiUserModel user, AuthTokensModel tokens})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });

    final body = response.data;
    final success = body['success'] as bool?;
    if (success != true) {
      final message = body['message'] as String?;
      final errorField = body['error'] as Map?;
      final code = errorField?['code'] as String?;
      throw AppException.fromCode(code, message, response.statusCode);
    }

    final data = body['data'];
    final user = ApiUserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens =
        AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>);
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return (user: user, tokens: tokens);
  }

  // ── Profil ────────────────────────────────────────────────────────────────
  Future<ApiUserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);

    final body = response.data;
    final success = body['success'] as bool?;
    if (success != true) {
      final message = body['message'] as String?;
      final errorField = body['error'] as Map?;
      final code = errorField?['code'] as String?;
      throw AppException.fromCode(code, message, response.statusCode);
    }

    return ApiUserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ApiUserModel> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.put(ApiEndpoints.me, data: data);

    final body = response.data;
    final success = body['success'] as bool?;
    if (success != true) {
      final message = body['message'] as String?;
      final errorField = body['error'] as Map?;
      final code = errorField?['code'] as String?;
      throw AppException.fromCode(code, message, response.statusCode);
    }

    return ApiUserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  // ── Vérification auth ─────────────────────────────────────────────────────
  Future<bool> isAuthenticated() => _tokenStorage.hasTokens();
}
