import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:juna/core/storage/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and restores JSON data', () async {
    final cache = CacheService();
    final value = {
      'id': 'subscription-1',
      'items': ['a', 'b'],
    };

    await cache.save('detail', value);

    expect(await cache.get('detail'), value);
  });

  test('removes expired data', () async {
    final oldEntry = {
      'data': {'id': 'old'},
      'timestamp':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    };
    SharedPreferences.setMockInitialValues({
      'detail': jsonEncode(oldEntry),
    });
    final cache = CacheService();

    expect(
      await cache.get('detail', maxAge: const Duration(minutes: 30)),
      isNull,
    );
    expect(
      (await SharedPreferences.getInstance()).containsKey('detail'),
      isFalse,
    );
  });

  test('removes invalid cache data', () async {
    SharedPreferences.setMockInitialValues({'detail': '{invalid json'});
    final cache = CacheService();

    expect(await cache.get('detail'), isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey('detail'),
      isFalse,
    );
  });

  test('clears private cache keys together', () async {
    SharedPreferences.setMockInitialValues({
      'user_profile': 'profile',
      'my_orders': 'orders',
      'active_subscriptions': 'subscriptions',
      'onboarding_completed': true,
    });
    final cache = CacheService();

    await cache.clearAll(const [
      'user_profile',
      'my_orders',
      'active_subscriptions',
    ]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('user_profile'), isFalse);
    expect(prefs.containsKey('my_orders'), isFalse);
    expect(prefs.containsKey('active_subscriptions'), isFalse);
    expect(prefs.getBool('onboarding_completed'), isTrue);
  });
}
