import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juna/core/storage/cache_service.dart';
import 'package:juna/core/widgets/subscription_instructions.dart';
import 'package:juna/features/orders/data/repositories/order_repository.dart';
import 'package:juna/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:juna/core/utils/enums.dart';

void main() {
  test('subscription parsing preserves instructions and accepts older data',
      () {
    final sub = SubscriptionRepository.mapSubscription({
      'id': 'subscription-1',
      'name': 'Formule midi',
      'instructions': 'Portion spéciale\nSauce à part',
      'providerSubscriptions': [
        {
          'id': 'subscription-2',
          'name': 'Autre formule',
          'instructions': 'Autre consigne'
        },
      ],
    });
    expect(sub.instructions, 'Portion spéciale\nSauce à part');
    expect(SubscriptionRepository.mapSubscription({'id': 'old'}).instructions,
        isNull);
    expect(
        SubscriptionRepository.mapSubscription(
            {'id': 'old', 'instructions': null}).instructions,
        isNull);
  });

  test(
      'order API parsing and status changes preserve subscription instructions',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'data': {
          'id': 'order-12345678',
          'subscription': {
            'id': 'subscription-1',
            'name': 'Formule midi',
            'instructions': 'Sauce à part',
          }
        },
      }));
    }));
    final repository = OrderRepository(dio: dio, cacheService: CacheService());
    final order = await repository.getOrderById('order-12345678');
    expect(order.subscriptionInstructions, 'Sauce à part');
    expect(order.copyWith(status: OrderStatus.active).subscriptionInstructions,
        'Sauce à part');
    dio.close();
  });

  testWidgets('empty instructions show no heading or text', (tester) async {
    for (final text in <String?>[null, '', '   ']) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: SubscriptionInstructions(instructions: text),
      )));
      expect(find.text('Précisions du prestataire'), findsNothing);
      expect(find.byType(Container), findsNothing);
    }
  });

  testWidgets('instructions render as plain multiline text without truncation',
      (tester) async {
    const text = '<b>Portion spéciale</b>\nSauce à part';
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: SubscriptionInstructions(instructions: text),
    )));
    expect(find.text('Précisions du prestataire'), findsOneWidget);
    final widget = tester.widget<Text>(find.text(text));
    expect(widget.maxLines, isNull);
    expect(widget.data, text);
  });
}
