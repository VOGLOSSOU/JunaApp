import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juna/core/api/current_account.dart';
import 'package:juna/core/errors/app_exception.dart';
import 'package:juna/core/storage/cache_service.dart';
import 'package:juna/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:juna/features/favorites/data/favorite_repository.dart';
import 'package:juna/features/favorites/presentation/favorites_controller.dart';
import 'package:juna/features/favorites/presentation/favorites_screen.dart';
import 'package:juna/features/favorites/presentation/favorite_button.dart';
import 'favorite_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('repository uses POST, DELETE and paginated GET contracts', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'data': options.method == 'GET'
            ? {
                'favorites': [
                  {'id': 'sub-1', 'isFavorite': true, 'isAvailable': false}
                ],
                'pagination': {'page': 2, 'totalPages': 3, 'total': 45}
              }
            : {
                'subscriptionId': 'sub-1',
                'isFavorite': options.method == 'POST'
              }
      }));
    }));
    final repo = FavoriteRepository(dio);
    expect(await repo.setFavorite('sub-1', true), isTrue);
    expect(await repo.setFavorite('sub-1', false), isFalse);
    final result = await repo.list(page: 2);
    expect(
        requests.map((request) => request.method), ['POST', 'DELETE', 'GET']);
    expect(requests[0].data, {'subscriptionId': 'sub-1'});
    expect(requests[1].path, '/favorites/sub-1');
    expect(requests[2].queryParameters, {'page': 2, 'limit': 20});
    expect(result.items.single.isFavorite, isTrue);
    expect(result.items.single.isAvailable, isFalse);
    expect(result.page, 2);
    dio.close();
  });

  test('authenticated discovery bypasses shared disk cache', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheService();
    await cache.save('subscription_sub-1',
        {'id': 'sub-1', 'name': 'Old', 'isFavorite': true});
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      calls++;
      handler.resolve(Response(requestOptions: options, data: {
        'data': {'id': 'sub-1', 'name': 'Current', 'isFavorite': false}
      }));
    }));
    final repo = SubscriptionRepository(
        dio: dio, cacheService: cache, personalized: true);
    expect((await repo.getSubscriptionById('sub-1')).isFavorite, isFalse);
    expect(calls, 1);
    expect((await cache.get('subscription_sub-1'))['name'], 'Old');
    dio.close();
  });

  test(
      'mutations wait for the server, block duplicates and preserve state on error',
      () async {
    final repo = FakeFavoriteRepository()..blockedMutation = Completer<bool>();
    final controller = FavoritesController(repo, 'A');
    addTearDown(controller.dispose);
    final sub = favoriteSample();
    final pending = controller.toggle(sub);
    await controller.toggle(sub);
    expect(repo.mutations.length, 1);
    expect(controller.state.flags['sub-1'], isNull);
    expect(controller.state.pending, contains('sub-1'));
    repo.blockedMutation!.complete(true);
    await pending;
    expect(controller.state.flags['sub-1'], isTrue);
    expect(controller.state.pending, isEmpty);
    repo.fail = true;
    await expectLater(controller.toggle(sub), throwsA(isA<AppException>()));
    expect(controller.state.flags['sub-1'], isTrue);
    expect(controller.state.pending, isEmpty);
  });

  test('pagination appends unique IDs and errors preserve the current list',
      () async {
    final repo = FakeFavoriteRepository()
      ..items = [favoriteSample(id: 'first', saved: true)];
    final controller = FavoritesController(repo, 'A');
    addTearDown(controller.dispose);
    await controller.load();
    repo.items = [favoriteSample(id: 'second', saved: true)];
    await controller.load(more: true);
    expect(repo.pages, [1, 2]);
    expect(controller.state.items.map((sub) => sub.id), ['first', 'second']);
    repo.fail = true;
    await controller.load();
    expect(controller.state.items.length, 2);
    expect(controller.state.error, isNotNull);
  });

  test('account changes discard the previous list and pending responses',
      () async {
    final account = StateProvider<String?>((ref) => 'A');
    final repo = FakeFavoriteRepository()
      ..blockedList = Completer<FavoritePage>();
    final container = ProviderContainer(overrides: [
      currentAccountIdProvider.overrideWith((ref) => ref.watch(account)),
      favoriteRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final old = container.read(favoritesControllerProvider.notifier);
    final response = old.load();
    container.read(account.notifier).state = 'B';
    expect(container.read(favoritesControllerProvider).items, isEmpty);
    repo.blockedList!.complete(FavoritePage(
        items: [favoriteSample(saved: true)],
        page: 1,
        totalPages: 1,
        total: 1));
    await response;
    expect(container.read(favoritesControllerProvider).items, isEmpty);
    container.read(account.notifier).state = null;
    expect(container.read(favoritesControllerProvider).flags, isEmpty);
  });

  testWidgets('guest heart asks for login without calling the API',
      (tester) async {
    final repo = FakeFavoriteRepository();
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: FavoriteButton(subscription: favoriteSample()))),
      GoRoute(
          path: '/login',
          builder: (_, state) => Scaffold(
              body: Text('Login ${state.uri.queryParameters['redirect']}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      currentAccountIdProvider.overrideWithValue(null),
      favoriteRepositoryProvider.overrideWithValue(repo),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();
    expect(find.text('Login /'), findsOneWidget);
    expect(repo.mutations, isEmpty);
  });

  testWidgets(
      'API favorite flag initializes the heart and failures show an error',
      (tester) async {
    final repo = FakeFavoriteRepository()..fail = true;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          currentAccountIdProvider.overrideWithValue('A'),
          favoriteRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: FavoriteButton(
                    subscription: favoriteSample(saved: true))))));
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    expect(find.text('Vérifiez votre connexion internet.'), findsOneWidget);
  });

  testWidgets('favorites page shows loading then retry on API failure',
      (tester) async {
    final repo = FakeFavoriteRepository()
      ..blockedList = Completer<FavoritePage>();
    await tester.pumpWidget(ProviderScope(overrides: [
      currentAccountIdProvider.overrideWithValue('A'),
      favoriteRepositoryProvider.overrideWithValue(repo),
    ], child: const MaterialApp(home: FavoritesScreen())));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.blockedList!.completeError(AppException.network());
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Vérifiez votre connexion internet.'), findsOneWidget);
    repo.blockedList = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun favori pour le moment.'), findsOneWidget);
  });

  testWidgets('favorites page displays empty state', (tester) async {
    final repo = FakeFavoriteRepository();
    await tester.pumpWidget(ProviderScope(overrides: [
      currentAccountIdProvider.overrideWithValue('A'),
      favoriteRepositoryProvider.overrideWithValue(repo),
    ], child: const MaterialApp(home: FavoritesScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Aucun favori pour le moment.'), findsOneWidget);
  });

  testWidgets(
      'unavailable saved subscriptions are displayed and remain removable',
      (tester) async {
    final repo = FakeFavoriteRepository()
      ..items = [favoriteSample(saved: true, available: false)];
    await tester.pumpWidget(ProviderScope(overrides: [
      currentAccountIdProvider.overrideWithValue('A'),
      favoriteRepositoryProvider.overrideWithValue(repo),
      favoritesControllerProvider
          .overrideWith((ref) => FavoritesController(repo, 'A')),
    ], child: const MaterialApp(home: FavoritesScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Indisponible'), findsOneWidget);
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    await tester.tap(find.text('Formule midi'));
    expect(tester.takeException(), isNull);
    repo.items = [];
    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pumpAndSettle();
    expect(repo.mutations, [('sub-1', false)]);
    expect(find.text('Aucun favori pour le moment.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
