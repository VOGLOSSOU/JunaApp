import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juna/core/errors/app_exception.dart';
import 'package:juna/core/storage/cache_service.dart';
import 'package:juna/features/checkout/data/repositories/payment_repository.dart';
import 'package:juna/features/checkout/domain/mobile_money.dart';
import 'package:juna/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:juna/features/checkout/presentation/screens/mobile_money_screen.dart';
import 'package:juna/features/checkout/presentation/screens/payment_processing_screen.dart';
import 'package:juna/features/orders/data/repositories/order_repository.dart';
import 'package:juna/features/orders/presentation/controllers/orders_controller.dart';

class _InitiateCall {
  final String orderId;
  final String phoneNumber;
  final String provider;
  _InitiateCall(this.orderId, this.phoneNumber, this.provider);
}

class _FakePaymentRepository extends PaymentRepository {
  final List<_InitiateCall> calls = [];
  InitiatePaymentResult? result;
  Object? error;

  _FakePaymentRepository() : super(dio: Dio());

  @override
  Future<InitiatePaymentResult> initiatePayment({
    required String orderId,
    required String phoneNumber,
    required String provider,
  }) async {
    calls.add(_InitiateCall(orderId, phoneNumber, provider));
    if (error != null) throw error!;
    return result!;
  }
}

class _FakeOrdersController extends OrdersController {
  int refreshes = 0;
  _FakeOrdersController()
      : super(OrderRepository(dio: Dio(), cacheService: CacheService()));

  @override
  Future<void> load({bool forceRefresh = false}) async => refreshes++;
}

void main() {
  group('toBeninPaymentPhone', () {
    test('prefixes a local 10-digit number with 229', () {
      expect(toBeninPaymentPhone('0166000000'), '2290166000000');
      expect(toBeninPaymentPhone(' 01 66 00 00 00 '), '2290166000000');
    });

    test('accepts a number already carrying the country code', () {
      expect(toBeninPaymentPhone('2290166000000'), '2290166000000');
      expect(toBeninPaymentPhone('+229 0166000000'), '2290166000000');
    });

    test('rejects numbers that are not 10 digits starting with 01', () {
      expect(toBeninPaymentPhone(''), isNull);
      expect(toBeninPaymentPhone('66000000'), isNull);
      expect(toBeninPaymentPhone('9766000000'), isNull);
      expect(toBeninPaymentPhone('01660000001'), isNull);
    });
  });

  test('operators map to the FeexPay provider and status method', () {
    expect(MobileMoneyOperator.values.map((o) => o.provider),
        ['MTN', 'MOOV', 'CELTIIS']);
    expect(MobileMoneyOperator.fromMethod('MOBILE_MONEY_CELTIIS'),
        MobileMoneyOperator.celtiis);
    expect(MobileMoneyOperator.fromMethod('MOBILE_MONEY'), isNull);
    expect(MobileMoneyOperator.fromMethod('MOBILE_MONEY_ORANGE'), isNull);
  });

  test('payment outcome parsing keeps unknown statuses in polling', () {
    expect(PaymentOutcome.parse('SUCCESS'), PaymentOutcome.success);
    expect(PaymentOutcome.parse('FAILED'), PaymentOutcome.failed);
    expect(PaymentOutcome.parse('PROCESSING'), PaymentOutcome.processing);
    expect(PaymentOutcome.parse('PENDING'), PaymentOutcome.processing);
  });

  test('initiation errors map to user messages', () {
    expect(
      paymentInitiationErrorMessage(const AppException(
          message: 'x', code: 'PAYMENT_ALREADY_PROCESSED', statusCode: 409)),
      contains('déjà en cours'),
    );
    expect(
      paymentInitiationErrorMessage(const AppException(
          message: 'x', code: 'INVALID_PAYMENT_REQUEST', statusCode: 400)),
      contains('Numéro invalide'),
    );
    expect(paymentInitiationErrorMessage(AppException.network()),
        contains('indisponible'));
    expect(
      paymentInitiationErrorMessage(
          const AppException(message: 'gateway', statusCode: 502)),
      contains('indisponible'),
    );
  });

  group('MobileMoneyScreen', () {
    late _FakePaymentRepository payments;
    late _FakeOrdersController orders;

    Future<void> showScreen(WidgetTester tester,
        {String paymentMethod = 'MOBILE_MONEY'}) async {
      payments = _FakePaymentRepository();
      orders = _FakeOrdersController();
      final router = GoRouter(
        initialLocation: '/pay',
        routes: [
          GoRoute(
            path: '/pay',
            builder: (_, __) => MobileMoneyScreen(
              extra: CheckoutMobileExtra(
                orderId: 'order-1',
                amount: 4200,
                subscriptionName: 'Formule semaine',
                subscriptionImageUrl: '',
                paymentMethod: paymentMethod,
              ),
            ),
          ),
          GoRoute(
            path: '/checkout/processing',
            builder: (_, state) => Text(
                'processing ${(state.extra as PaymentProcessingExtra).paymentId}'),
          ),
          GoRoute(
            path: '/checkout/failed',
            builder: (_, state) => Text(
                'failed ${(state.extra as PaymentFailedExtra).errorMessage}'),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (_, state) => Text('order ${state.pathParameters['id']}'),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(payments),
          ordersControllerProvider.overrideWith((_) => orders),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> pay(WidgetTester tester,
        {String? operator, String phone = '0166000000'}) async {
      if (operator != null) {
        await tester.ensureVisible(find.text(operator));
        await tester.tap(find.text(operator));
        // Le champ numéro apparaît après le choix du réseau.
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextField), phone);
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    testWidgets('the number field only appears once a network is chosen',
        (tester) async {
      await showScreen(tester);
      expect(find.text('Orange Money'), findsNothing);
      expect(find.text('Pays *'), findsNothing);

      // Pas de réseau : pas de champ numéro, bouton désactivé et explicite.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Choisissez votre réseau'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull);

      await tester.tap(find.text('Moov'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('2. Votre numéro Moov'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull);
      expect(payments.calls, isEmpty);
    });

    testWidgets('rejects a malformed number without calling the backend',
        (tester) async {
      await showScreen(tester);
      await pay(tester, operator: 'Moov', phone: '97123456');

      expect(payments.calls, isEmpty);
      expect(
          find.textContaining('10 chiffres commençant par 01'), findsOneWidget);
    });

    testWidgets('PROCESSING sends provider and 229 number, then polls',
        (tester) async {
      await showScreen(tester);
      payments.result = const InitiatePaymentResult(
          paymentId: 'pay-1', status: 'PROCESSING', message: '');

      await pay(tester, operator: 'Celtiis');

      expect(payments.calls.single.orderId, 'order-1');
      expect(payments.calls.single.provider, 'CELTIIS');
      expect(payments.calls.single.phoneNumber, '2290166000000');
      expect(find.text('processing pay-1'), findsOneWidget);
    });

    testWidgets('immediate SUCCESS opens the order without polling',
        (tester) async {
      await showScreen(tester);
      payments.result = const InitiatePaymentResult(
          paymentId: 'pay-1', status: 'SUCCESS', message: 'Paiement confirmé.');

      await pay(tester, operator: 'Moov');

      expect(payments.calls.single.provider, 'MOOV');
      expect(orders.refreshes, 1);
      expect(find.text('order order-1'), findsOneWidget);
      expect(find.textContaining('processing'), findsNothing);
    });

    testWidgets('immediate FAILED shows the operator message', (tester) async {
      await showScreen(tester);
      payments.result = const InitiatePaymentResult(
          paymentId: 'pay-1',
          status: 'FAILED',
          message: 'Paiement refusé par l\'opérateur.');

      await pay(tester, operator: 'Moov');

      expect(find.text('failed Paiement refusé par l\'opérateur.'),
          findsOneWidget);
    });

    testWidgets('retry keeps the operator chosen before the failure',
        (tester) async {
      await showScreen(tester, paymentMethod: 'MOBILE_MONEY_MOOV');
      payments.result = const InitiatePaymentResult(
          paymentId: 'pay-2', status: 'PROCESSING', message: '');

      await pay(tester);

      expect(payments.calls.single.provider, 'MOOV');
    });

    testWidgets('backend errors stay on screen and allow a retry',
        (tester) async {
      await showScreen(tester);
      payments.error = const AppException(
          message: 'x', code: 'INVALID_PAYMENT_REQUEST', statusCode: 400);

      await pay(tester, operator: 'MTN');

      expect(find.textContaining('Numéro invalide'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull);
    });
  });
}
