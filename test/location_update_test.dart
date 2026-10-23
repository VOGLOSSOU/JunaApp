import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juna/core/errors/app_exception.dart';
import 'package:juna/features/auth/data/models/auth_models.dart';
import 'package:juna/features/auth/data/repositories/auth_repository.dart';
import 'package:juna/features/auth/presentation/controllers/auth_controller.dart';
import 'package:juna/features/home/presentation/controllers/location_controller.dart';

class _LocationRepository extends Fake implements AuthRepository {
  bool fail = false;
  String? requestedCity;
  int profileReads = 0;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<void> updateLocation(String cityId) async {
    requestedCity = cityId;
    if (fail) throw AppException.network();
  }

  @override
  Future<ApiUserModel> getMe() async {
    profileReads++;
    return ApiUserModel.fromJson({
      'id': 'user-1',
      'name': 'Client test',
      'email': 'test@example.com',
      'profile': {
        'city': {
          'id': 'city-new',
          'name': 'Lokossa',
          'country': {
            'code': 'BJ',
            'translations': {'fr': 'Bénin'}
          }
        }
      },
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> setup(_LocationRepository repository) async {
    SharedPreferences.setMockInitialValues({
      'location_city': 'Cotonou',
      'location_country': 'BJ',
      'location_city_id': 'city-old',
    });
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    container.read(locationControllerProvider);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('failed save preserves the current city and exposes an error', () async {
    final repository = _LocationRepository()..fail = true;
    final container = await setup(repository);
    final result = await container
        .read(authControllerProvider.notifier)
        .updateLocation('city-new');
    expect(result, isFalse);
    expect(repository.requestedCity, 'city-new');
    expect(repository.profileReads, 0);
    expect(container.read(locationControllerProvider).cityId, 'city-old');
    expect(container.read(authControllerProvider).error, isNotEmpty);
  });

  test('retry synchronizes profile, country, city and saved location',
      () async {
    final repository = _LocationRepository()..fail = true;
    final container = await setup(repository);
    final controller = container.read(authControllerProvider.notifier);
    expect(await controller.updateLocation('city-new'), isFalse);
    repository.fail = false;
    expect(await controller.updateLocation('city-new'), isTrue);
    final location = container.read(locationControllerProvider);
    expect(location.cityId, 'city-new');
    expect(location.city, 'Lokossa');
    expect(location.country, 'BJ');
    expect(container.read(authControllerProvider).user?.profile.city?.id,
        'city-new');
    expect(container.read(authControllerProvider).error, isNull);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('location_city_id'), 'city-new');
    expect(prefs.getString('location_country'), 'BJ');
  });
}
