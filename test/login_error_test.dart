import 'dart:async';
import 'package:dio/dio.dart';
import 'package:juna/core/storage/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juna/core/api/api_client.dart';
import 'package:juna/core/errors/app_exception.dart';
import 'package:juna/core/storage/token_storage.dart';
import 'package:juna/features/auth/data/models/auth_models.dart';
import 'package:juna/features/auth/data/repositories/auth_repository.dart';
import 'package:juna/features/auth/presentation/controllers/auth_controller.dart';
import 'package:juna/features/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository extends AuthRepository {
  final bool hasTokens;
  Future<ApiUserModel> Function()? profile;
  Completer<void>? loginGate;
  _FakeAuthRepository({this.hasTokens = false})
      : super(dio: Dio(), tokenStorage: TokenStorage());

  @override
  Future<bool> isAuthenticated() async => hasTokens;

  @override
  Future<ApiUserModel> getMe() async => profile != null
      ? await profile!()
      : ApiUserModel.fromJson(const {
          'id': 'user-1',
          'email': 'awa@example.com',
          'name': 'Awa Dossou',
          'isVerified': true,
        });

  @override
  Future<({ApiUserModel user, AuthTokensModel tokens, bool isProfileComplete})>
      login({required String email, required String password}) async {
    if (loginGate != null) await loginGate!.future;
    throw DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      type: DioExceptionType.badResponse,
      error: AppException.fromCode(
          'INVALID_CREDENTIALS', 'INVALID_CREDENTIALS', 401),
    );
  }

  @override
  Future<void> logout() async {}
}

ProviderContainer _container(_FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a session invalidation never shows "Session expirée" to a guest',
      () async {
    final container = _container(_FakeAuthRepository());
    container.read(authControllerProvider);
    await _settle();

    container.read(sessionInvalidationProvider.notifier).state++;
    await _settle();

    expect(container.read(authControllerProvider).error, isNull);
  });

  test('a signed-in user whose session expires is told so', () async {
    final container = _container(_FakeAuthRepository(hasTokens: true));
    container.read(authControllerProvider);
    for (var i = 0; i < 5; i++) {
      await _settle();
    }
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);

    container.read(sessionInvalidationProvider.notifier).state++;
    for (var i = 0; i < 5; i++) {
      await _settle();
    }

    final state = container.read(authControllerProvider);
    expect(state.isAuthenticated, isFalse);
    expect(state.error, 'Session expirée. Veuillez vous reconnecter.');
  });

  test('late guest invalidation preserves a wrong-password error', () async {
    final container = _container(_FakeAuthRepository());
    final controller = container.read(authControllerProvider.notifier);
    await _settle();
    expect(await controller.login(email: 'awa@example.com', password: 'wrong'),
        isFalse);
    container.read(sessionInvalidationProvider.notifier).state++;
    container.read(sessionInvalidationProvider.notifier).state++;
    await _settle();
    expect(container.read(authControllerProvider).error,
        'Email ou mot de passe incorrect.');
    expect(container.read(authControllerProvider).errorOrigin,
        AuthErrorOrigin.login);
  });

  test('guest invalidation during login does not discard the result', () async {
    final repo = _FakeAuthRepository()..loginGate = Completer<void>();
    final container = _container(repo);
    final controller = container.read(authControllerProvider.notifier);
    await _settle();
    final login = controller.login(email: 'awa@example.com', password: 'wrong');
    container.read(sessionInvalidationProvider.notifier).state++;
    await _settle();
    expect(container.read(authControllerProvider).isLoading, isTrue);
    repo.loginGate!.complete();
    expect(await login, isFalse);
    expect(container.read(authControllerProvider).error,
        'Email ou mot de passe incorrect.');
  });

  test('a delayed startup profile cannot overwrite a manual login error',
      () async {
    final gate = Completer<ApiUserModel>();
    final repo = _FakeAuthRepository(hasTokens: true)
      ..profile = () => gate.future;
    final container = _container(repo);
    final controller = container.read(authControllerProvider.notifier);
    for (var i = 0; i < 5; i++) {
      await _settle();
    }
    await controller.login(email: 'awa@example.com', password: 'wrong');
    gate.complete(ApiUserModel.fromJson(const {
      'id': 'old-user',
      'email': 'old@example.com',
      'name': 'Old User',
      'isVerified': true
    }));
    for (var i = 0; i < 5; i++) {
      await _settle();
    }
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(container.read(authControllerProvider).errorOrigin,
        AuthErrorOrigin.login);
  });

  test('session cleanup cannot erase a newer failed login', () async {
    final cache = _DelayedCache();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider
          .overrideWithValue(_FakeAuthRepository(hasTokens: true)),
      cacheServiceProvider.overrideWithValue(cache),
    ]);
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);
    for (var i = 0; i < 5; i++) {
      await _settle();
    }
    container.read(sessionInvalidationProvider.notifier).state++;
    await _settle();
    expect(container.read(authControllerProvider).errorOrigin,
        AuthErrorOrigin.session);
    await controller.login(email: 'awa@example.com', password: 'wrong');
    cache.cleanup.complete();
    for (var i = 0; i < 5; i++) {
      await _settle();
    }
    expect(container.read(authControllerProvider).error,
        'Email ou mot de passe incorrect.');
    expect(container.read(authControllerProvider).errorOrigin,
        AuthErrorOrigin.login);
  });

  test('a rejection of an old stored session is distinguished from first visit',
      () async {
    final repo = _FakeAuthRepository(hasTokens: true)
      ..profile = () async => throw AppException.unauthorized();
    final container = _container(repo);
    container.read(authControllerProvider);
    for (var i = 0; i < 8; i++) {
      await _settle();
    }
    expect(container.read(authControllerProvider).errorOrigin,
        AuthErrorOrigin.session);
    expect(container.read(authControllerProvider).error,
        contains('Session expirée'));
  });

  testWidgets('wrong credentials show an error on the login screen',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Session expirée'), findsNothing);
    expect(find.text('Email ou mot de passe incorrect.'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'awa@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'mauvais-mdp');
    await tester.ensureVisible(find.text('Se connecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

class _DelayedCache extends CacheService {
  final cleanup = Completer<void>();
  @override
  Future<void> clearAll(Iterable<String> keys) => cleanup.future;
}
