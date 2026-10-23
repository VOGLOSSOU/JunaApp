import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/features/orders/domain/entities/active_subscription_entity.dart';
import 'package:juna/features/orders/presentation/widgets/subscriber_flip_card.dart';

ActiveSubscriptionEntity subscription(String? instructions) =>
    ActiveSubscriptionEntity(
      id: '12345678-abonnement',
      orderId: 'order-1',
      subscriptionId: 'sub-1',
      subscriptionName: 'Formule midi',
      instructions: instructions,
      subscriptionType: 'LUNCH',
      subscriptionCategory: 'AFRICAN',
      duration: 'WEEK',
      providerName: 'Prestataire test',
      startedAt: DateTime(2026, 10, 23),
      endsAt: DateTime(2026, 10, 30),
      deliveryMethod: 'PICKUP',
    );

Future<void> showCard(WidgetTester tester, String? instructions,
    {bool reducedMotion = false}) async {
  await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(16),
      child: SubscriberFlipCard(
          sub: subscription(instructions),
          userName: 'Client test',
          front: const SizedBox(
              width: double.infinity,
              height: 330,
              child: Center(child: Text('Recto de la carte')))),
    )),
  )));
}

void main() {
  testWidgets('card flips to instructions and returns to the front',
      (tester) async {
    await showCard(tester, 'Sauce à part\nPortion spéciale');
    await tester.tap(find.byType(SubscriberFlipCard));
    await tester.pumpAndSettle();
    final card = tester.widget<Semantics>(find
        .descendant(
            of: find.byType(SubscriberFlipCard),
            matching: find.byType(Semantics))
        .first);
    expect(card.properties.toggled, isTrue);
    expect(find.text('Sauce à part\nPortion spéciale'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Voir plus'), findsNothing);
    await tester.tap(find.byType(SubscriberFlipCard));
    await tester.pumpAndSettle();
    final front = tester.widget<Semantics>(find
        .descendant(
            of: find.byType(SubscriberFlipCard),
            matching: find.byType(Semantics))
        .first);
    expect(front.properties.toggled, isFalse);
  });

  testWidgets('missing instructions show the fallback on the back',
      (tester) async {
    await showCard(tester, null);
    await tester.tap(find.byType(SubscriberFlipCard));
    await tester.pumpAndSettle();
    expect(find.text('Aucune instruction particulière pour cet abonnement.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long instructions open in a dialog and keep the back visible',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showCard(tester,
        '${List.filled(60, 'Consigne de préparation').join('\n')}\nDernière consigne');
    await tester.tap(find.byType(SubscriberFlipCard));
    await tester.pumpAndSettle();
    expect(find.text('Voir plus'), findsOneWidget);
    await tester.tap(find.text('Voir plus'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final content = tester.widget<Text>(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate((widget) =>
          widget is Text &&
          (widget.data?.endsWith('Dernière consigne') ?? false)),
    ));
    expect(content.maxLines, isNull);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final card = tester.widget<Semantics>(find
        .descendant(
            of: find.byType(SubscriberFlipCard),
            matching: find.byType(Semantics))
        .first);
    expect(card.properties.toggled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion allows flipping immediately', (tester) async {
    await showCard(tester, 'Consigne', reducedMotion: true);
    await tester.tap(find.byType(SubscriberFlipCard));
    await tester.pumpAndSettle();
    expect(find.text('Consigne'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
