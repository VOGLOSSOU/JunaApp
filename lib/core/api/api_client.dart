import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Incrémenté uniquement lorsque le serveur confirme que la session n'est plus
/// récupérable. Les contrôleurs d'UI peuvent ainsi se déconnecter sans que la
/// couche HTTP dépende directement d'une feature.
final sessionInvalidationProvider = StateProvider<int>((ref) => 0);

final refreshDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final refreshDio = ref.read(refreshDioProvider);

  dio.interceptors.add(
    _AuthInterceptor(
      dio,
      refreshDio,
      tokenStorage,
      onSessionInvalidated: () {
        ref.read(sessionInvalidationProvider.notifier).state++;
      },
    ),
  );
  dio.interceptors.add(_ErrorInterceptor());

  return dio;
});

// ── Intercepteur authentification (inject token + auto-refresh) ─────────────

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final void Function() _onSessionInvalidated;
  Future<String?>? _refreshFuture;

  _AuthInterceptor(
    this._dio,
    this._refreshDio,
    this._tokenStorage, {
    required void Function() onSessionInvalidated,
  }) : _onSessionInvalidated = onSessionInvalidated;

  static const _publicAuthPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.refresh,
    ApiEndpoints.sendVerificationCode,
    ApiEndpoints.verifyCode,
    ApiEndpoints.forgotPassword,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && !_publicAuthPaths.contains(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _publicAuthPaths.contains(options.path) ||
        options.extra['authRetried'] == true) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await _sharedRefresh();
      if (newAccessToken == null) {
        handler.next(err);
        return;
      }

      options.extra['authRetried'] = true;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(options);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _sharedRefresh() {
    final running = _refreshFuture;
    if (running != null) return running;

    final future = _refreshAccessToken();
    _refreshFuture = future;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    });
  }

  Future<String?> _refreshAccessToken() async {
    final currentRefreshToken = await _tokenStorage.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      await _invalidateSession();
      return null;
    }

    try {
      final response = await _refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': currentRefreshToken},
      );
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final newAccessToken =
          data is Map ? data['accessToken'] as String? : null;
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _invalidateSession();
        return null;
      }

      final nextRefreshToken =
          data!['refreshToken'] as String? ?? currentRefreshToken;
      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: nextRefreshToken,
      );
      return newAccessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await _invalidateSession();
      }
      return null;
    } catch (_) {
      // Une réponse 2xx mal formée ne permet pas de restaurer la session.
      await _invalidateSession();
      return null;
    }
  }

  Future<void> _invalidateSession() async {
    await _tokenStorage.clearTokens();
    _onSessionInvalidated();
  }
}

// ── Intercepteur erreurs (transforme DioException → AppException) ────────────

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = AppException.timeout();
        break;
      case DioExceptionType.connectionError:
        exception = AppException.network();
        break;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        final body = err.response?.data;

        // Le code peut être dans body['code'] ou body['error']['code']
        String? code;
        if (body is Map) {
          final errorField = body['error'];
          if (errorField is Map) {
            code = errorField['code'] as String?;
          } else {
            code = body['code'] as String?;
          }
        }

        // Le message peut être un String ou un List (NestJS validation errors)
        String? message;
        if (body is Map) {
          final raw = body['message'];
          if (raw is String) {
            if (raw.startsWith('Validation failed: ')) {
              // Extraire les erreurs du JSON dans le string
              try {
                final jsonStr = raw.substring('Validation failed: '.length);
                final errors = jsonDecode(jsonStr) as List;
                final messages =
                    errors.map((e) => e['message'] as String).toList();
                message = messages.join(' • ');
              } catch (_) {
                message = raw; // fallback
              }
            } else {
              message = raw;
            }
          } else if (raw is List && raw.isNotEmpty) {
            // Tableau de strings directes (format Juna API) ou objets NestJS
            final messages = <String>[];
            for (final item in raw) {
              if (item is String) {
                messages.add(item);
              } else if (item is Map) {
                final msg = item['message'] as String?;
                if (msg != null) {
                  messages.add(msg);
                } else {
                  final constraints = item['constraints'] as Map?;
                  if (constraints != null) {
                    messages
                        .addAll(constraints.values.map((v) => v.toString()));
                  }
                }
              }
            }
            message = messages.isNotEmpty ? messages.join('\n') : null;
          }
        }

        if (status == 429) {
          exception = AppException(
            message:
                message ?? 'Trop de tentatives. Attendez quelques minutes.',
            code: code ?? 'TOO_MANY_REQUESTS',
            statusCode: 429,
          );
        } else if (status == 500) {
          exception = AppException.server();
        } else {
          exception = AppException.fromCode(code, message, status);
        }
        break;
      default:
        exception = AppException(message: err.message ?? 'Erreur inconnue.');
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }
}

// Helper pour extraire AppException d'une DioException
AppException extractException(Object error) {
  if (error is DioException && error.error is AppException) {
    return error.error as AppException;
  }
  if (error is AppException) return error;
  return AppException(message: error.toString());
}
