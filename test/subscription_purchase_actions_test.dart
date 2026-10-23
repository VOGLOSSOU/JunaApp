import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/features/subscriptions/presentation/widgets/subscription_purchase_actions.dart';

void main() {
  Future<void> showActions(WidgetTester tester,
      {double width = 360,
      double scale = 1,
      bool available = true,
      VoidCallback? onTap}) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: SizedBox(
          width: width,
          child: SubscriptionPurchaseActions(
            price: 3111,
            durationLabel: '1 semaine',
            isAvailable: available,
            onSubscribe: onTap ?? () {},
          )),
    ))));
  }

  testWidgets('price separates the amount and currency and subscribes',
      (tester) async {
    var tapped = false;
    await showActions(tester, onTap: () => tapped = true);
    final price = tester.widget<Text>(find.byWidgetPredicate((widget) =>
        widget is Text &&
        (widget.textSpan?.toPlainText().endsWith('FCFA') ?? false)));
    expect(price.textSpan!.toPlainText().replaceAll(RegExp(r'\s'), ' '),
        '3 111 FCFA');
    final buttonRect = tester.getRect(find.byType(ElevatedButton));
    expect(buttonRect.height, greaterThanOrEqualTo(50));
    final actionsRect =
        tester.getRect(find.byType(SubscriptionPurchaseActions));
    expect(buttonRect.right, closeTo(actionsRect.right, 1));
    expect(buttonRect.width, closeTo(actionsRect.width * 0.6, 1));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('S’abonner'));
    expect(tapped, isTrue);
  });

  testWidgets('small widths and large text stack the action without overflow',
      (tester) async {
    for (final setting in [(280.0, 1.0), (360.0, 2.0)]) {
      await showActions(tester, width: setting.$1, scale: setting.$2);
      final button = tester.getRect(find.byType(ElevatedButton));
      final duration = tester.getRect(find.text('1 semaine'));
      expect(button.top, greaterThan(duration.bottom));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('unavailable subscriptions cannot be purchased', (tester) async {
    await showActions(tester, available: false);
    expect(find.text('Indisponible'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
  });
}
