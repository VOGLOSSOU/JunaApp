import 'package:flutter_riverpod/flutter_riverpod.dart';

class CityState {
  final String city;
  final String country;
  final String? cityId;

  const CityState({required this.city, required this.country, this.cityId});

  String get display =>
      city.isEmpty ? 'Localisation non définie' : '$city, $country';
  String get short => city;
}

class LocationController extends StateNotifier<CityState> {
  LocationController() : super(const CityState(city: '', country: ''));

  void selectCity(String city, String country, {String? cityId}) {
    state = CityState(city: city, country: country, cityId: cityId);
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, CityState>(
  (_) => LocationController(),
);
