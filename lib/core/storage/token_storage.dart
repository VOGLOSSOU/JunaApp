import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Web fallback via shared_preferences (no encryption but avoids WebCrypto crash)
  Future<void> _webWrite(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> _webRead(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _webDelete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      await Future.wait([
        _webWrite(_accessKey, accessToken),
        _webWrite(_refreshKey, refreshToken),
      ]);
      return;
    }
    try {
      await Future.wait([
        _storage.write(key: _accessKey, value: accessToken),
        _storage.write(key: _refreshKey, value: refreshToken),
      ]);
    } catch (_) {
      await Future.wait([
        _webWrite(_accessKey, accessToken),
        _webWrite(_refreshKey, refreshToken),
      ]);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return _webRead(_accessKey);
    try {
      return await _storage.read(key: _accessKey);
    } catch (_) {
      return _webRead(_accessKey);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return _webRead(_refreshKey);
    try {
      return await _storage.read(key: _refreshKey);
    } catch (_) {
      return _webRead(_refreshKey);
    }
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      await Future.wait([
        _webDelete(_accessKey),
        _webDelete(_refreshKey),
      ]);
      return;
    }
    try {
      await Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
      ]);
    } catch (_) {
      await Future.wait([
        _webDelete(_accessKey),
        _webDelete(_refreshKey),
      ]);
    }
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
