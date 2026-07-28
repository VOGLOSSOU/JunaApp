import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class CacheService {
  Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = CacheEntry(data: data, timestamp: DateTime.now());
    await prefs.setString(key, jsonEncode(entry.toJson()));
  }

  Future<dynamic> get(String key, {Duration? maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(key);
    if (str == null) return null;

    try {
      final json = jsonDecode(str);
      final entry = CacheEntry.fromJson(json);

      if (maxAge != null) {
        final age = DateTime.now().difference(entry.timestamp);
        if (age > maxAge) {
          await prefs.remove(key); // Expired
          return null;
        }
      }

      return entry.data;
    } catch (e) {
      await prefs.remove(key); // Invalid cache
      return null;
    }
  }

  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> clearAll(Iterable<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(keys.map(prefs.remove));
  }
}
