import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../errors/app_exception.dart';
import '../../features/auth/data/models/auth_models.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(dio: ref.read(dioProvider));
});

class LocationRepository {
  final Dio _dio;

  LocationRepository({required Dio dio}) : _dio = dio;

  // ── Pays ──────────────────────────────────────────────────────────────────
  Future<List<CountryModel>> getCountries() async {
    // Cache local (les pays changent rarement)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cache_countries');
      if (cached != null) {
        final list = (cached.split('||'))
            .where((s) => s.isNotEmpty)
            .map((s) {
              final parts = s.split('|');
              return CountryModel(
                id: parts[0],
                code: parts[1],
                nameFr: parts[2],
                nameEn: parts[3],
                isActive: true,
              );
            })
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    try {
      final response = await _dio.get(ApiEndpoints.countries);
      final list = (response.data['data'] as List)
          .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
          .where((c) => c.isActive)
          .toList();

      // Mise en cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final encoded = list
            .map((c) => '${c.id}|${c.code}|${c.nameFr}|${c.nameEn}')
            .join('||');
        await prefs.setString('cache_countries', encoded);
      } catch (_) {}

      return list;
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // ── Villes ────────────────────────────────────────────────────────────────
  Future<List<CityModel>> getCitiesByCountry(String countryCode) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.citiesByCountry(countryCode));
      return (response.data['data'] as List)
          .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
          .where((c) => c.isActive)
          .toList();
    } on DioException catch (e) {
      throw extractException(e);
    }
  }

  // ── Landmarks ─────────────────────────────────────────────────────────────
  Future<List<LandmarkModel>> getLandmarksByCity(String cityId) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.landmarksByCity(cityId));
      return (response.data['data'] as List)
          .map((e) => LandmarkModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw extractException(e);
    }
  }
}
