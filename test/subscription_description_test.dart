import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/features/subscriptions/presentation/widgets/subscription_description.dart';

Future<void> showDescription(WidgetTester tester, String text) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SingleChildScrollView(
              child: SubscriptionDescription(text: text)))));
}

void main() {
  testWidgets('16 words or fewer are shown without a read-more button',
      (tester) async {
    for (final count in [0, 1, 16]) {
      final text = List.filled(count, 'mot').join(' ');
      await showDescription(tester, text);
      expect(find.text(text), findsOneWidget);
      expect(find.text('Voir plus'), findsNothing);
    }
  });

  testWidgets('long description shows 16 words then expands and collapses',
      (tester) async {
    final preview = List.filled(16, 'mot').join(' ');
    final full = '$preview dernier';
    await showDescription(tester, full);
    expect(find.text('$preview…'), findsOneWidget);
    expect(find.text(full), findsNothing);
    await tester.ensureVisible(find.text('Voir plus'));
    await tester.tap(find.text('Voir plus'));
    await tester.pump();
    expect(find.text(full), findsOneWidget);
    await tester.ensureVisible(find.text('Voir moins'));
    await tester.tap(find.text('Voir moins'));
    await tester.pump();
    expect(find.text('$preview…'), findsOneWidget);
  });

  testWidgets('repeated whitespace and line breaks are preserved',
      (tester) async {
    final first = List.filled(16, 'repas,').join('  \n');
    await showDescription(tester, '$first\n  suite');
    expect(find.text('$first…'), findsOneWidget);
  });
}
