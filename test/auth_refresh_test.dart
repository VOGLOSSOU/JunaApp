import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/core/api/api_client.dart';
import 'package:juna/core/api/api_endpoints.dart';
import 'package:juna/core/storage/token_storage.dart';

void main() {
  test('keeps the current refresh token when API only returns accessToken',
      () async {
    final storage = _MemoryTokenStorage(
      accessToken: 'expired-access',
      refreshToken: 'stable-refresh',
    );
    final refreshAdapter = _RefreshAdapter(
      statusCode: 200,
      body: {
        'success': true,
        'data': {'accessToken': 'fresh-access'},
      },
    );
    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl))
      ..httpClientAdapter = refreshAdapter;
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        refreshDioProvider.overrideWithValue(refreshDio),
      ],
    );
    addTearDown(container.dispose);
    final api = container.read(dioProvider)
      ..httpClientAdapter = _ProtectedRouteAdapter();

    final response = await api.get('/protected');

    expect(response.statusCode, 200);
    expect(storage.accessToken, 'fresh-access');
    expect(storage.refreshToken, 'stable-refresh');
    expect(refreshAdapter.calls, 1);
    expect(refreshAdapter.authorizationHeader, isNull);
  });

  test('shares one refresh between simultaneous 401 responses', () async {
    final storage = _MemoryTokenStorage(
      accessToken: 'expired-access',
      refreshToken: 'stable-refresh',
    );
    final refreshAdapter = _RefreshAdapter(
      statusCode: 200,
      delay: const Duration(milliseconds: 20),
      body: {
        'success': true,
        'data': {
          'accessToken': 'fresh-access',
          'refreshToken': 'rotated-refresh',
        },
      },
    );
    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl))
      ..httpClientAdapter = refreshAdapter;
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        refreshDioProvider.overrideWithValue(refreshDio),
      ],
    );
    addTearDown(container.dispose);
    final api = container.read(dioProvider)
      ..httpClientAdapter = _ProtectedRouteAdapter();

    await Future.wait([
      api.get('/protected/one'),
      api.get('/protected/two'),
    ]);

    expect(refreshAdapter.calls, 1);
    expect(storage.accessToken, 'fresh-access');
    expect(storage.refreshToken, 'rotated-refresh');
  });

  test('invalidates the session only when refresh is rejected', () async {
    final storage = _MemoryTokenStorage(
      accessToken: 'expired-access',
      refreshToken: 'invalid-refresh',
    );
    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl))
      ..httpClientAdapter = _RefreshAdapter(
        statusCode: 401,
        body: {
          'success': false,
          'error': {'code': 'INVALID_TOKEN'},
        },
      );
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        refreshDioProvider.overrideWithValue(refreshDio),
      ],
    );
    addTearDown(container.dispose);
    final api = container.read(dioProvider)
      ..httpClientAdapter = _ProtectedRouteAdapter();

    await expectLater(api.get('/protected'), throwsA(isA<DioException>()));

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(container.read(sessionInvalidationProvider), 1);
  });

  test('keeps the session when refresh fails because of network', () async {
    final storage = _MemoryTokenStorage(
      accessToken: 'expired-access',
      refreshToken: 'stable-refresh',
    );
    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl))
      ..httpClientAdapter = _NetworkFailureAdapter();
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        refreshDioProvider.overrideWithValue(refreshDio),
      ],
    );
    addTearDown(container.dispose);
    final api = container.read(dioProvider)
      ..httpClientAdapter = _ProtectedRouteAdapter();

    await expectLater(api.get('/protected'), throwsA(isA<DioException>()));

    expect(storage.accessToken, 'expired-access');
    expect(storage.refreshToken, 'stable-refresh');
    expect(container.read(sessionInvalidationProvider), 0);
  });
}

class _MemoryTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  _MemoryTokenStorage({
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _ProtectedRouteAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final retried = options.extra['authRetried'] == true;
    return ResponseBody.fromString(
      jsonEncode(retried ? {'success': true} : {'success': false}),
      retried ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RefreshAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> body;
  final Duration delay;
  int calls = 0;
  dynamic authorizationHeader;

  _RefreshAdapter({
    required this.statusCode,
    required this.body,
    this.delay = Duration.zero,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    authorizationHeader = options.headers['Authorization'];
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _NetworkFailureAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}
