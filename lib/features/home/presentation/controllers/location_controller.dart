import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCity    = 'location_city';
const _kCountry = 'location_country';
const _kCityId  = 'location_city_id';

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
  LocationController() : super(const CityState(city: '', country: '')) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final city    = prefs.getString(_kCity)    ?? '';
    final country = prefs.getString(_kCountry) ?? '';
    final cityId  = prefs.getString(_kCityId);
    if (city.isNotEmpty) {
      state = CityState(city: city, country: country, cityId: cityId);
    }
  }

  void selectCity(String city, String country, {String? cityId}) {
    state = CityState(city: city, country: country, cityId: cityId);
    _saveToPrefs(city, country, cityId);
  }

  Future<void> _saveToPrefs(String city, String country, String? cityId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCity, city);
    await prefs.setString(_kCountry, country);
    if (cityId != null) {
      await prefs.setString(_kCityId, cityId);
    } else {
      await prefs.remove(_kCityId);
    }
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, CityState>(
  (_) => LocationController(),
);
