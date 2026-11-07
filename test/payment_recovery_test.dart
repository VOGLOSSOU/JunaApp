import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juna/core/api/current_account.dart';
import 'package:juna/core/errors/app_exception.dart';
import 'package:juna/core/storage/cache_service.dart';
import 'package:juna/core/utils/enums.dart';
import 'package:juna/features/checkout/data/repositories/payment_repository.dart';
import 'package:juna/features/checkout/domain/mobile_money.dart';
import 'package:juna/features/checkout/presentation/screens/payment_processing_screen.dart';
import 'package:juna/features/checkout/presentation/widgets/order_payment_button.dart';
import 'package:juna/features/orders/data/repositories/order_repository.dart';
import 'package:juna/features/orders/domain/entities/order_entity.dart';
import 'package:juna/features/orders/presentation/controllers/orders_controller.dart';

OrderEntity sample(
        {OrderPayment? payment, OrderStatus status = OrderStatus.pending}) =>
    OrderEntity(
        id: 'order-1',
        orderNumber: 'JUNA-1',
        status: status,
        deliveryMethod: DeliveryMethod.pickup,
        amount: 3111,
        qrCode: 'qr',
        createdAt: DateTime(2026),
        subscriptionName: 'Menu',
        payment: payment);
const pending = OrderPayment(
    id: 'pay-1', status: 'PROCESSING', method: 'MOBILE_MONEY_MOOV');

class Payments extends PaymentRepository {
  int statusCalls = 0;
  int initiationCalls = 0;
  Future<PaymentStatusResult> Function()? response;
  Payments() : super(dio: Dio());
  @override
  Future<PaymentStatusResult> getPaymentStatus(String id) async {
    statusCalls++;
    return response == null
        ? const PaymentStatusResult(
            paymentId: 'pay-1',
            orderId: 'order-1',
            amount: 3111,
            status: 'PROCESSING')
        : await response!();
  }

  @override
  Future<InitiatePaymentResult> initiatePayment(
      {required String orderId,
      required String phoneNumber,
      required String provider}) async {
    initiationCalls++;
    throw StateError('Recovery must not initiate a new debit');
  }
}

class Orders extends OrderRepository {
  OrderEntity order = sample(payment: pending);
  Object? error;
  int detailCalls = 0;
  Orders() : super(dio: Dio(), cacheService: CacheService());
  @override
  Future<OrderEntity> getOrderById(String id) async {
    detailCalls++;
    if (error != null) throw error!;
    return order;
  }
}

class ListController extends OrdersController {
  int refreshes = 0;
  ListController(super.repo);
  @override
  Future<void> load({bool forceRefresh = false}) async {
    if (forceRefresh) refreshes++;
  }
}

void main() {
  late Payments payments;
  late Orders orders;
  late ListController list;
  Future<void> show(WidgetTester tester,
      {String? paymentId = 'pay-1', OrderEntity? buttonOrder}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    list = ListController(orders);
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(
          path: '/start',
          builder: (_, __) => buttonOrder == null
              ? PaymentProcessingScreen(
                  extra: PaymentProcessingExtra(
                      orderId: 'order-1',
                      paymentId: paymentId,
                      phoneNumber: '',
                      amount: 3111,
                      subscriptionName: 'Menu',
                      subscriptionImageUrl: '',
                      paymentMethod: 'MOBILE_MONEY_MOOV'))
              : Scaffold(body: OrderPaymentButton(order: buttonOrder))),
      GoRoute(
          path: '/checkout/processing',
          builder: (_, state) => Text(
              'resume ${(state.extra as PaymentProcessingExtra).paymentId}')),
      GoRoute(
          path: '/checkout/mobile-money',
          builder: (_, __) => const Text('new-payment')),
      GoRoute(
          path: '/checkout/failed',
          builder: (_, __) => const Text('confirmed-failure')),
      GoRoute(path: '/orders', builder: (_, __) => const Text('orders-list')),
      GoRoute(
          path: '/orders/:id', builder: (_, __) => const Text('paid-order')),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
    await tester.pumpWidget(ProviderScope(overrides: [
      currentAccountIdProvider.overrideWithValue('account-A'),
      paymentRepositoryProvider.overrideWithValue(payments),
      orderRepositoryProvider.overrideWithValue(orders),
      ordersControllerProvider.overrideWith((ref) => list),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    payments = Payments();
    orders = Orders();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'three minute wait is pending, never failed and has no retry debit',
      (tester) async {
    await show(tester);
    await tester.pump(const Duration(minutes: 3));
    await tester.pump();
    expect(find.text('Confirmation en attente'), findsOneWidget);
    expect(find.text('confirmed-failure'), findsNothing);
    expect(find.text('Réessayer'), findsNothing);
    expect(payments.initiationCalls, 0);
    expect(find.text('Vérifier le paiement'), findsOneWidget);
  });
  testWidgets('slow status requests never overlap, even beyond the wait limit',
      (tester) async {
    final gate = Completer<PaymentStatusResult>();
    payments.response = () => gate.future;
    await show(tester);
    await tester.pump(const Duration(minutes: 4));
    expect(payments.statusCalls, 1);
    gate.complete(const PaymentStatusResult(
        paymentId: 'pay-1',
        orderId: 'order-1',
        amount: 3111,
        status: 'SUCCESS'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('paid-order'), findsOneWidget);
    expect(list.refreshes, 1);
  });
  testWidgets('manual verification after long wait opens a late success',
      (tester) async {
    await show(tester);
    await tester.pump(const Duration(minutes: 3));
    await tester.pump();
    payments.response = () async => const PaymentStatusResult(
        paymentId: 'pay-1',
        orderId: 'order-1',
        amount: 3111,
        status: 'SUCCESS');
    await tester.tap(find.text('Vérifier le paiement'));
    await tester.pumpAndSettle();
    expect(find.text('paid-order'), findsOneWidget);
    expect(payments.initiationCalls, 0);
  });
  testWidgets('only a server-confirmed failure opens failure screen',
      (tester) async {
    payments.response = () async => const PaymentStatusResult(
        paymentId: 'pay-1', orderId: 'order-1', amount: 3111, status: 'FAILED');
    await show(tester);
    await tester.pumpAndSettle();
    expect(find.text('confirmed-failure'), findsOneWidget);
  });
  testWidgets('network error remains pending and a later poll recovers',
      (tester) async {
    payments.response = () async => throw AppException.network();
    await show(tester);
    expect(find.text('confirmed-failure'), findsNothing);
    payments.response = () async => const PaymentStatusResult(
        paymentId: 'pay-1',
        orderId: 'order-1',
        amount: 3111,
        status: 'SUCCESS');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('paid-order'), findsOneWidget);
  });
  testWidgets(
      'lost initiation response recovers payment ID from the server order',
      (tester) async {
    await show(tester, paymentId: null);
    expect(orders.detailCalls, 1);
    expect(payments.statusCalls, 1);
    expect(payments.initiationCalls, 0);
  });
  testWidgets('no recorded payment does not trigger an automatic debit',
      (tester) async {
    orders.order = sample();
    await show(tester, paymentId: null);
    await tester.pump(const Duration(minutes: 3));
    await tester.pump();
    expect(find.text('Confirmation en attente'), findsOneWidget);
    expect(payments.statusCalls, 0);
    expect(payments.initiationCalls, 0);
  });
  testWidgets('backend-confirmed order recovers even without a payment ID',
      (tester) async {
    orders.order = sample(status: OrderStatus.confirmed);
    await show(tester, paymentId: null);
    await tester.pumpAndSettle();
    expect(find.text('paid-order'), findsOneWidget);
    expect(payments.statusCalls, 0);
  });
  testWidgets('return from background checks status immediately',
      (tester) async {
    await show(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(payments.statusCalls, 1);
    payments.response = () async => const PaymentStatusResult(
        paymentId: 'pay-1',
        orderId: 'order-1',
        amount: 3111,
        status: 'SUCCESS');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('paid-order'), findsOneWidget);
  });
  testWidgets('leaving the screen ignores a late response', (tester) async {
    final gate = Completer<PaymentStatusResult>();
    payments.response = () => gate.future;
    await show(tester);
    await tester.tap(find.text('Voir mes commandes'));
    await tester.pumpAndSettle();
    gate.complete(const PaymentStatusResult(
        paymentId: 'pay-1',
        orderId: 'order-1',
        amount: 3111,
        status: 'SUCCESS'));
    await tester.pumpAndSettle();
    expect(find.text('orders-list'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'cached unpaid order is freshly checked and resumes an existing payment',
      (tester) async {
    await show(tester, buttonOrder: sample());
    await tester.tap(find.text('Payer maintenant'));
    await tester.pumpAndSettle();
    expect(find.text('resume pay-1'), findsOneWidget);
    expect(find.text('new-payment'), findsNothing);
  });
  testWidgets('pending payment button clearly says verify', (tester) async {
    await show(tester, buttonOrder: sample(payment: pending));
    expect(find.text('Vérifier le paiement'), findsOneWidget);
  });
  testWidgets('a fresh final failure allows another payment for the same order',
      (tester) async {
    orders.order = sample(
        payment: const OrderPayment(
            id: 'pay-1', status: 'FAILED', method: 'MOBILE_MONEY_MOOV'));
    await show(tester, buttonOrder: orders.order);
    await tester.tap(find.text('Payer maintenant'));
    await tester.pumpAndSettle();
    expect(find.text('new-payment'), findsOneWidget);
  });
  testWidgets('failed fresh verification never opens a new collection form',
      (tester) async {
    orders.error = AppException.network();
    await show(tester, buttonOrder: sample());
    await tester.tap(find.text('Payer maintenant'));
    await tester.pump();
    await tester.pump();
    expect(find.text('new-payment'), findsNothing);
    expect(find.textContaining('Impossible de vérifier cette commande'),
        findsOneWidget);
  });

  test('lost responses need verification while explicit input errors do not',
      () {
    expect(paymentInitiationNeedsVerification(AppException.timeout()), isTrue);
    expect(
        paymentInitiationNeedsVerification(
            const AppException(message: 'x', statusCode: 503)),
        isTrue);
    expect(
        paymentInitiationNeedsVerification(const AppException(
            message: 'x', code: 'PAYMENT_ALREADY_PROCESSED', statusCode: 409)),
        isTrue);
    expect(
        paymentInitiationNeedsVerification(const AppException(
            message: 'x', code: 'INVALID_PAYMENT_REQUEST', statusCode: 400)),
        isFalse);
  });
  test('API contracts retain the payment ID and longer per-request timeouts',
      () async {
    final dio = Dio();
    final calls = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      calls.add(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'data': options.method == 'POST'
            ? {
                'paymentId': 'pay-1',
                'reference': null,
                'status': 'PROCESSING',
                'message': 'pending'
              }
            : {
                'id': 'pay-1',
                'orderId': 'order-1',
                'amount': 3111,
                'status': 'PROCESSING'
              }
      }));
    }));
    final repo = PaymentRepository(dio: dio);
    expect(
        (await repo.initiatePayment(
                orderId: 'order-1',
                phoneNumber: '2290166000000',
                provider: 'MOOV'))
            .paymentId,
        'pay-1');
    await repo.getPaymentStatus('pay-1');
    expect(calls[0].receiveTimeout, const Duration(seconds: 90));
    expect(calls[1].receiveTimeout, const Duration(seconds: 45));
    dio.close();
  });
  test('server and disk order parsing preserve payment ID, status and operator',
      () async {
    final dio = Dio();
    int gets = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      gets++;
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'data': [
          {
            'id': 'order-1',
            'orderNumber': 'JUNA-1',
            'status': 'PENDING',
            'amount': 3111,
            'payment': {
              'id': 'pay-1',
              'status': 'PROCESSING',
              'method': 'MOBILE_MONEY_MOOV'
            }
          }
        ]
      }));
    }));
    final repo = OrderRepository(dio: dio, cacheService: CacheService());
    final fresh = (await repo.getMyOrders(forceRefresh: true)).single;
    expect(fresh.payment?.id, 'pay-1');
    expect(fresh.payment?.method, 'MOBILE_MONEY_MOOV');
    expect(fresh.copyWith(status: OrderStatus.confirmed).payment?.id, 'pay-1');
    expect((await repo.getMyOrders()).single.payment?.status, 'PROCESSING');
    expect(gets, 1);
    await repo.getMyOrders(forceRefresh: true);
    expect(gets, 2);
    dio.close();
  });
}
