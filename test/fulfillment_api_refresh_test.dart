import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juna/core/storage/cache_service.dart';
import 'package:juna/features/checkout/data/repositories/payment_repository.dart';
import 'package:juna/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:juna/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:juna/features/subscriptions/presentation/controllers/subscription_detail_controller.dart';
import 'package:juna/features/subscriptions/presentation/screens/subscription_detail_screen.dart';

Map<String, dynamic> data({bool delivery = false, bool pickup = true}) => {
      'id': 'sub-1', 'name': 'Menu', 'price': 3111,
      // Old zones/points must never enable a disabled mode.
      'deliveryZones': ['Cotonou · 500 FCFA'], 'pickupPoints': ['Point ancien'],
      'provider': {
        'id': 'provider-1',
        'businessName': 'Test',
        'businessAddress': 'Rue 12',
        'acceptsDelivery': delivery,
        'acceptsPickup': pickup
      },
    };

class MemoryCache extends CacheService {
  dynamic value;
  MemoryCache(this.value);
  @override
  Future<dynamic> get(String key, {Duration? maxAge}) async => value;
  @override
  Future<void> save(String key, dynamic data) async {
    value = data;
  }
}

class Payments extends PaymentRepository {
  final List<String> modes = [];
  Payments() : super(dio: Dio());
  @override
  Future<OrderCreatedResult> createOrder(
      {required String subscriptionId,
      required String deliveryMethod,
      String? deliveryAddress,
      String? deliveryCity,
      String? pickupLocation,
      bool startAsap = true}) async {
    modes.add(deliveryMethod);
    return const OrderCreatedResult(
        orderId: 'order-1', orderNumber: 'JN-1', amount: 3111);
  }
}

void main() {
  testWidgets('detail respects pickup-only even with old delivery zones',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SubscriptionDeliveryModes(
                sub: SubscriptionRepository.mapSubscription(data())))));
    expect(find.text('Retrait sur place'), findsOneWidget);
    expect(find.text('Livraison à domicile'), findsNothing);
    expect(find.text('Zones desservies'), findsNothing);
  });
  testWidgets('detail respects delivery-only even with old pickup points',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SubscriptionDeliveryModes(
                sub: SubscriptionRepository.mapSubscription(
                    data(delivery: true, pickup: false))))));
    expect(find.text('Livraison à domicile'), findsOneWidget);
    expect(find.text('Retrait sur place'), findsNothing);
    expect(find.text('Point ancien'), findsNothing);
  });
  testWidgets('detail invents neither mode when provider flags are absent',
      (tester) async {
    final json = data();
    json['provider'] = {'id': 'provider-1'};
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SubscriptionDeliveryModes(
                sub: SubscriptionRepository.mapSubscription(json)))));
    expect(find.text('Livraison à domicile'), findsNothing);
    expect(find.text('Retrait sur place'), findsNothing);
  });

  late Map<String, dynamic> response;
  late Dio dio;
  late Payments payments;
  late ProviderContainer container;
  int requests = 0;
  bool fail = false;
  setUp(() {
    response = data();
    requests = 0;
    fail = false;
    payments = Payments();
    dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests++;
      if (fail) {
        handler.reject(DioException(
            requestOptions: options, type: DioExceptionType.connectionError));
        return;
      }
      handler.resolve(Response(
          requestOptions: options, statusCode: 200, data: {'data': response}));
    }));
    container = ProviderContainer(overrides: [
      subscriptionRepositoryProvider.overrideWithValue(SubscriptionRepository(
          dio: dio,
          cacheService: MemoryCache(data(delivery: true, pickup: true)))),
      paymentRepositoryProvider.overrideWithValue(payments),
    ]);
  });
  tearDown(() {
    container.dispose();
    dio.close();
  });
  Future<void> showCheckout(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/checkout', routes: [
      GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutScreen(subscriptionId: 'sub-1')),
      GoRoute(
          path: '/checkout/mobile-money',
          builder: (_, __) => const Text('payment-step')),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Continuer vers le paiement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer vers le paiement'));
    await tester.pumpAndSettle();
  }

  testWidgets('checkout bypasses both disk cache and browsing session data',
      (tester) async {
    final cached =
        await container.read(subscriptionDetailProvider('sub-1').future);
    expect(cached.provider.acceptsDelivery, isTrue);
    expect(requests, 0);
    await showCheckout(tester);
    expect(requests, 1);
    expect(find.text('Retrait sur place'), findsOneWidget);
    expect(find.text('Livraison\nà domicile'), findsNothing);
    await submit(tester);
    expect(requests, 2);
    expect(payments.modes, ['PICKUP']);
  });
  testWidgets('checkout does not fall back to old capabilities on API failure',
      (tester) async {
    await container.read(subscriptionDetailProvider('sub-1').future);
    fail = true;
    await showCheckout(tester);
    expect(find.text('Impossible de vérifier les options de ce prestataire.'),
        findsOneWidget);
    expect(find.text('Continuer vers le paiement'), findsNothing);
    expect(payments.modes, isEmpty);
    fail = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Retrait sur place'), findsOneWidget);
  });
  testWidgets(
      'mode changed before submit is refreshed and blocks unsupported delivery',
      (tester) async {
    response = data(delivery: true, pickup: true);
    await showCheckout(tester);
    await tester.tap(find.text('Cotonou'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Maison bleue');
    response = data(delivery: false, pickup: true);
    await submit(tester);
    expect(payments.modes, isEmpty);
    expect(find.text('Retrait sur place'), findsOneWidget);
    expect(find.text('Livraison\nà domicile'), findsNothing);
    expect(find.textContaining('Les modes de réception ont changé'),
        findsOneWidget);
    await submit(tester);
    expect(payments.modes, ['PICKUP']);
  });
  testWidgets('return from background reloads current provider capabilities',
      (tester) async {
    response = data(delivery: true, pickup: true);
    await showCheckout(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    response = data(delivery: false, pickup: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final refreshed =
        container.read(checkoutSubscriptionProvider('sub-1').future);
    await tester.pumpAndSettle();
    await refreshed;
    expect(requests, 2);
    expect(find.text('Retrait sur place'), findsOneWidget);
    expect(find.text('Livraison\nà domicile'), findsNothing);
  });
}
