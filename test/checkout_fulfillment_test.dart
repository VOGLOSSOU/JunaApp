import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juna/features/checkout/data/repositories/payment_repository.dart';
import 'package:juna/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:juna/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:juna/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:juna/features/subscriptions/presentation/controllers/subscription_detail_controller.dart';

class _FakePaymentRepository extends PaymentRepository {
  final List<String> deliveryMethods = [];
  _FakePaymentRepository() : super(dio: Dio());

  @override
  Future<OrderCreatedResult> createOrder({
    required String subscriptionId,
    required String deliveryMethod,
    String? deliveryAddress,
    String? deliveryCity,
    String? pickupLocation,
    bool startAsap = true,
  }) async {
    deliveryMethods.add(deliveryMethod);
    return const OrderCreatedResult(
        orderId: 'order-1', orderNumber: 'JN-1', amount: 4200);
  }
}

SubscriptionEntity _subscription({
  required bool delivery,
  required bool pickup,
}) =>
    SubscriptionRepository.mapSubscription({
      'id': 'sub-1',
      'name': 'Formule semaine',
      'price': 4200,
      'deliveryZones': ['Cotonou · 500 FCFA'],
      'pickupPoints': ['Ancien point de retrait'],
      'provider': {
        'id': 'prov-1',
        'name': 'Chez Awa',
        'businessAddress': 'Rue 12, Akpakpa',
        'acceptsDelivery': delivery,
        'acceptsPickup': pickup,
      },
    });

void main() {
  late _FakePaymentRepository payments;

  Future<void> showCheckout(WidgetTester tester,
      {required bool delivery, required bool pickup}) async {
    payments = _FakePaymentRepository();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutScreen(subscriptionId: 'sub-1'),
        ),
        GoRoute(
          path: '/checkout/mobile-money',
          builder: (_, __) => const Text('mobile money'),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (_, __) => const Text('order'),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        checkoutSubscriptionProvider('sub-1').overrideWith(
            (_) async => _subscription(delivery: delivery, pickup: pickup)),
        paymentRepositoryProvider.overrideWithValue(payments),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final cta = find.text('Continuer vers le paiement');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
  }

  ElevatedButton cta(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  testWidgets('both modes offered: the user chooses', (tester) async {
    await showCheckout(tester, delivery: true, pickup: true);

    expect(find.text('Livraison\nà domicile'), findsOneWidget);
    expect(find.text('Retrait\nsur place'), findsOneWidget);

    await tester.tap(find.text('Retrait\nsur place'));
    await tester.pumpAndSettle();
    await submit(tester);

    expect(payments.deliveryMethods, ['PICKUP']);
  });

  testWidgets('pickup only: no selector, pickup is sent', (tester) async {
    await showCheckout(tester, delivery: false, pickup: true);

    expect(find.text('Livraison\nà domicile'), findsNothing);
    expect(find.text('Retrait\nsur place'), findsNothing);
    expect(find.text('Retrait sur place'), findsOneWidget);
    expect(find.text('Cotonou'), findsNothing);

    await submit(tester);

    expect(payments.deliveryMethods, ['PICKUP']);
  });

  testWidgets('delivery only: no selector, zones are shown', (tester) async {
    await showCheckout(tester, delivery: true, pickup: false);

    expect(find.text('Livraison\nà domicile'), findsNothing);
    expect(find.text('Retrait\nsur place'), findsNothing);
    expect(find.text('Livraison à domicile'), findsOneWidget);
    expect(find.text('Cotonou'), findsOneWidget);

    await tester.ensureVisible(find.text('Cotonou'));
    await tester.tap(find.text('Cotonou'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Maison bleue');
    await submit(tester);

    expect(payments.deliveryMethods, ['DELIVERY']);
  });

  testWidgets('payment is Mobile Money only, no cash option', (tester) async {
    await showCheckout(tester, delivery: true, pickup: true);

    expect(find.textContaining('Espèces'), findsNothing);
    expect(find.text('Mobile Money'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNothing);
  });

  testWidgets('no mode offered: ordering is blocked', (tester) async {
    await showCheckout(tester, delivery: false, pickup: false);

    expect(find.text('Commande indisponible'), findsOneWidget);
    expect(cta(tester).onPressed, isNull);
  });
}
