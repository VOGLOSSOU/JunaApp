import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juna/core/api/current_account.dart';
import 'package:juna/features/favorites/data/favorite_repository.dart';
import 'package:juna/features/favorites/presentation/favorites_controller.dart';
import 'favorite_fakes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juna/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:juna/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:juna/features/subscriptions/presentation/widgets/subscription_card.dart';

SubscriptionEntity sample({int reviews = 12}) =>
    SubscriptionRepository.mapSubscription({
      'id': 'sub-1',
      'name': 'Riz, Atassi et Alloco, Vandzou : 6 jours',
      'price': 3111,
      'type': 'LUNCH',
      'duration': 'WEEK',
      'rating': 4.7,
      'reviewCount': reviews,
      'provider': {
        'id': 'provider-1',
        'name': 'Les délices de Maman Karel (Chez les Ivoiriens)',
        'isVerified': true
      },
    });

Future<void> showCard(WidgetTester tester,
    {double scale = 1, int reviews = 12}) async {
  await tester.pumpWidget(ProviderScope(
      overrides: [
        currentAccountIdProvider.overrideWithValue('test-user'),
        favoriteRepositoryProvider.overrideWithValue(FakeFavoriteRepository()),
        favoritesControllerProvider.overrideWith((ref) => FavoritesController(
            ref.read(favoriteRepositoryProvider), 'test-user')),
      ],
      child: MaterialApp(
          home: Scaffold(
              body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Builder(
            builder: (context) => SizedBox(
                width: 138,
                height:
                    subscriptionCardHeight(context, hasReviews: reviews > 0),
                child: SubscriptionCardCompact(
                    subscription: sample(reviews: reviews)))),
      )))));
}

void main() {
  testWidgets('card shows duration, provider, total price and real reviews',
      (tester) async {
    await showCard(tester);
    expect(find.text('1 semaine'), findsOneWidget);
    expect(find.text('pour toute la durée'), findsOneWidget);
    expect(find.text('4.7 (12 avis)'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.text('Voir →'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long names fit narrow cards and larger text', (tester) async {
    for (final scale in [1.0, 1.5, 2.0]) {
      await showCard(tester, scale: scale);
      expect(tester.takeException(), isNull);
      final title = tester
          .widget<Text>(find.text('Riz, Atassi et Alloco, Vandzou : 6 jours'));
      expect(title.maxLines, 2);
      final provider = tester.widget<Text>(
          find.text('Les délices de Maman Karel (Chez les Ivoiriens)'));
      expect(provider.maxLines, 2);
    }
  });

  testWidgets(
      'no review count means no rating, missing images have a placeholder',
      (tester) async {
    await showCard(tester, reviews: 0);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('heart toggles existing favorites without navigating',
      (tester) async {
    await showCard(tester);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(SubscriptionCardCompact)));
    expect(container.read(favoritesControllerProvider).flags['sub-1'], isTrue);
    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pump();
    expect(container.read(favoritesControllerProvider).flags['sub-1'], isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the entire card opens subscription details', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
              body: SizedBox(
                  width: 180,
                  height: 312,
                  child: SubscriptionCardCompact(subscription: sample())))),
      GoRoute(
          path: '/subscriptions/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Détail ${state.pathParameters['id']}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [currentAccountIdProvider.overrideWithValue(null)],
        child: MaterialApp.router(routerConfig: router)));
    await tester.tap(find.text('pour toute la durée'));
    await tester.pumpAndSettle();
    expect(find.text('Détail sub-1'), findsOneWidget);
  });
}
