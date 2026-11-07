import 'package:dio/dio.dart';
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
  _FakeAuthRepository({this.hasTokens = false})
      : super(dio: Dio(), tokenStorage: TokenStorage());

  @override
  Future<bool> isAuthenticated() async => hasTokens;

  @override
  Future<ApiUserModel> getMe() async => ApiUserModel.fromJson(const {
        'id': 'user-1',
        'email': 'awa@example.com',
        'name': 'Awa Dossou',
        'isVerified': true,
      });

  @override
  Future<({ApiUserModel user, AuthTokensModel tokens, bool isProfileComplete})>
      login({required String email, required String password}) async {
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
