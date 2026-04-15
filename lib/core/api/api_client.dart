import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

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

  dio.interceptors.add(_AuthInterceptor(dio, tokenStorage));
  dio.interceptors.add(_ErrorInterceptor());

  return dio;
});

// ── Intercepteur authentification (inject token + auto-refresh) ─────────────

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          await _tokenStorage.clearTokens();
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final data = response.data['data'];
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        // Relancer la requête originale avec le nouveau token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer ${data['accessToken']}';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await _tokenStorage.clearTokens();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
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
        final code = body?['error']?['code'] as String?;
        final message = body?['message'] as String?;

        if (status == 429) {
          exception = AppException.rateLimit();
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
