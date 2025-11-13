import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/dependency_injection.dart';

class TokenStorageService {
  final FlutterSecureStorage _storage;

  TokenStorageService({FlutterSecureStorage? storage}) : _storage = storage ?? locator<FlutterSecureStorage>();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> setAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
    } catch (e) {
      throw Exception('Failed to store access token: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      throw Exception('Failed to retrieve access token: $e');
    }
  }

  Future<void> setRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      throw Exception('Failed to store refresh token: $e');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw Exception('Failed to retrieve refresh token: $e');
    }
  }

  Future<void> setTokens({required String accessToken, required String refreshToken}) async {
    try {
      await Future.wait([
        setAccessToken(accessToken),
        setRefreshToken(refreshToken),
      ]);
    } catch (e) {
      throw Exception('Failed to store tokens: $e');
    }
  }

  Future<bool> hasAccessToken() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
    } catch (e) {
      throw Exception('Failed to clear access token: $e');
    }
  }

  Future<void> clearRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      throw Exception('Failed to clear refresh token: $e');
    }
  }

  Future<void> clearAllTokens() async {
    try {
      await Future.wait([
        clearAccessToken(),
        clearRefreshToken(),
      ]);
    } catch (e) {
      throw Exception('Failed to clear tokens: $e');
    }
  }
}

