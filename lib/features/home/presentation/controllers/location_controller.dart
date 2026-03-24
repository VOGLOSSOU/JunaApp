import 'package:flutter_riverpod/flutter_riverpod.dart';

class CityState {
  final String city;
  final String country;

  const CityState({required this.city, required this.country});

  String get display => '$city, $country';
  String get short => city;
}

class LocationController extends StateNotifier<CityState> {
  LocationController() : super(const CityState(city: 'Cotonou', country: 'BJ'));

  void selectCity(String city, String country) {
    state = CityState(city: city, country: country);
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, CityState>(
  (_) => LocationController(),
);
