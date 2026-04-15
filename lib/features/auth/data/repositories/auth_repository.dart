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
    try {
      final response = await _dio.post(ApiEndpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      final data = response.data['data'];
      final user = ApiUserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens =
          AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return (user: user, tokens: tokens);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // ── Connexion ─────────────────────────────────────────────────────────────
  Future<({ApiUserModel user, AuthTokensModel tokens})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      final data = response.data['data'];
      final user = ApiUserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens =
          AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return (user: user, tokens: tokens);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // ── Profil ────────────────────────────────────────────────────────────────
  Future<ApiUserModel> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      return ApiUserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<ApiUserModel> updateMe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.me, data: data);
      return ApiUserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  // ── Vérification auth ─────────────────────────────────────────────────────
  Future<bool> isAuthenticated() => _tokenStorage.hasTokens();
}
