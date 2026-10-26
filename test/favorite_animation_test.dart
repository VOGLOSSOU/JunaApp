import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/core/api/current_account.dart';
import 'package:juna/features/favorites/data/favorite_repository.dart';
import 'package:juna/features/favorites/presentation/favorites_controller.dart';
import 'package:juna/features/favorites/presentation/favorite_button.dart';
import 'favorite_fakes.dart';

void main() {
  Future<ProviderContainer> showButton(
      WidgetTester tester, FakeFavoriteRepository repo,
      {bool saved = false, bool reducedMotion = false}) async {
    final container = ProviderContainer(overrides: [
      currentAccountIdProvider.overrideWithValue('A'),
      favoriteRepositoryProvider.overrideWithValue(repo),
      favoritesControllerProvider
          .overrideWith((ref) => FavoritesController(repo, 'A')),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(
            body: Center(
                child: FavoriteButton(
                    subscription: favoriteSample(saved: saved)))),
      )),
    ));
    return container;
  }

  testWidgets('heart lands only after confirmation and animation cleans up',
      (tester) async {
    final repo = FakeFavoriteRepository()..blockedMutation = Completer<bool>();
    await showButton(tester, repo);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pump();
    expect(find.byKey(const Key('favorite-landing-heart')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.blockedMutation!.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('favorite-landing-heart')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorite-landing-heart')), findsNothing);
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
  });

  testWidgets('existing favorite and removal never animate', (tester) async {
    await showButton(tester, FakeFavoriteRepository(), saved: true);
    expect(find.byKey(const Key('favorite-landing-heart')), findsNothing);
    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('favorite-landing-heart')), findsNothing);
    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
  });

  testWidgets('failed additions do not animate', (tester) async {
    await showButton(tester, FakeFavoriteRepository()..fail = true);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorite-landing-heart')), findsNothing);
    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
  });

  testWidgets('reduced motion saves the favorite without animation',
      (tester) async {
    await showButton(tester, FakeFavoriteRepository(), reducedMotion: true);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('favorite-landing-heart')), findsNothing);
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
  });

  testWidgets('disposing the button during a request is safe', (tester) async {
    final repo = FakeFavoriteRepository()..blockedMutation = Completer<bool>();
    await showButton(tester, repo);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    repo.blockedMutation!.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
