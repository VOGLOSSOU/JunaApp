import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juna/features/subscriptions/domain/entities/provider_entity.dart';
import 'package:juna/features/subscriptions/presentation/widgets/provider_cover_badge.dart';

ProviderEntity provider(String name, {bool verified = true}) => ProviderEntity(
      id: 'provider-1',
      name: name,
      description: '',
      avatarUrl: '',
      logo: '',
      rating: 0,
      reviewCount: 0,
      isVerified: verified,
      acceptsDelivery: true,
      acceptsPickup: true,
      businessAddress: '',
      city: const ProviderCity(id: 'city', name: 'Cotonou'),
    );

Future<void> showBadge(WidgetTester tester, String name,
    {bool verified = true, double textScale = 1}) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: SizedBox(
        width: 280,
        height: 288,
        child: Stack(children: [
          Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ProviderCoverBadge(
                  provider: provider(name, verified: verified))),
        ])),
  ))));
  await tester.pump();
}

void main() {
  testWidgets('long name stays within the photo with fixed margins',
      (tester) async {
    const name = 'Les délices de Maman Karel (Chez les Ivoiriens)';
    await showBadge(tester, name);
    final badge = tester.getRect(find.byType(ProviderCoverBadge));
    expect(badge.left, 12);
    expect(badge.right, 268);
    final nameRect = tester.getRect(find.text(name));
    final iconRect = tester.getRect(find.byIcon(Icons.verified));
    expect(nameRect.left, greaterThan(badge.left));
    expect(nameRect.right, lessThan(iconRect.left));
    expect(tester.widget<Text>(find.text(name)).maxLines, 2);
    expect(find.byTooltip(name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text and very long names keep the badge inside the photo',
      (tester) async {
    await showBadge(tester, List.filled(12, 'Restaurant').join(), textScale: 2);
    final badge = tester.getRect(find.byType(ProviderCoverBadge));
    expect(badge.top, greaterThanOrEqualTo(0));
    expect(badge.right, 268);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unverified provider has no verification icon', (tester) async {
    await showBadge(tester, 'Chez Marie', verified: false);
    expect(find.byIcon(Icons.verified), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the banner opens the provider profile', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
              body: SizedBox(
                  width: 280,
                  child:
                      ProviderCoverBadge(provider: provider('Chez Marie'))))),
      GoRoute(
          path: '/providers/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Profil ${state.pathParameters['id']}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Chez Marie'));
    await tester.pumpAndSettle();
    expect(find.text('Profil provider-1'), findsOneWidget);
  });
}
