import 'dart:typed_data';

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
  Future<({ApiUserModel user, AuthTokensModel tokens, bool isProfileComplete})> register({
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
    final isProfileComplete = data['isProfileComplete'] as bool? ?? false;
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return (user: user, tokens: tokens, isProfileComplete: isProfileComplete);
  }

  // ── Connexion ─────────────────────────────────────────────────────────────
  Future<({ApiUserModel user, AuthTokensModel tokens, bool isProfileComplete})> login({
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
    final isProfileComplete = data['isProfileComplete'] as bool? ?? true;
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return (user: user, tokens: tokens, isProfileComplete: isProfileComplete);
  }

  // ── Profil ────────────────────────────────────────────────────────────────
  Future<ApiUserModel> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.userProfile);
      return ApiUserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<ApiUserModel> updateMe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.userProfile, data: data);
      return ApiUserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<void> updateLocation(String cityId) async {
    try {
      await _dio.put(ApiEndpoints.updateUserLocation, data: {'cityId': cityId});
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _dio.put(ApiEndpoints.updateUserPreferences, data: preferences);
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // Fonctionne sur web et mobile (accepte des bytes)
  // Champ multipart = "image" (pas "file"), endpoint = /upload/:folder
  Future<String> uploadImageBytes(Uint8List bytes, String filename,
      {String folder = 'avatars'}) async {
    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(
        '/upload/$folder',
        data: formData,
      );
      final data = response.data['data'];
      return data['url'] as String;
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // ── Changement de mot de passe ────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(ApiEndpoints.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Always clear tokens even if API call fails
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  // ── Vérification auth ─────────────────────────────────────────────────────
  Future<bool> isAuthenticated() => _tokenStorage.hasTokens();
}
