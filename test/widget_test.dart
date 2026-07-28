import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': false,
    });

    await tester.pumpWidget(const ProviderScope(child: JunaApp()));
    expect(find.byType(JunaApp), findsOneWidget);

    // Le splash contient des animations et des délais intentionnels.
    for (var i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Démonter proprement l'app pour annuler les contrôleurs d'animation.
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
