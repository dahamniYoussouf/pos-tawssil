import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;

  // Getters
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  // Initialiser le service depuis le stockage local
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConfig.tokenKey);
    _refreshToken = prefs.getString(AppConfig.refreshTokenKey);
    final userJson = prefs.getString(AppConfig.userKey);
    if (userJson != null) {
      try {
        _user = jsonDecode(userJson) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Error parsing user data: $e');
        await clearSession();
      }
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'type': 'admin',
        }),
      ).timeout(AppConfig.networkTimeout);

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid email or password');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Vérifier que c'est un admin
      final user = data['user'] as Map<String, dynamic>;
      if (user['role'] != 'admin') {
        throw Exception('Access denied. Admin privileges required.');
      }

      // Stocker les tokens
      _token = data['access_token'] as String;
      _refreshToken = data['refresh_token'] as String?;
      _user = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.tokenKey, _token!);
      if (_refreshToken != null) {
        await prefs.setString(AppConfig.refreshTokenKey, _refreshToken!);
      }
      await prefs.setString(AppConfig.userKey, jsonEncode(_user));

      print('✅ Login successful for: ${user['email']}');
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    await clearSession();
  }

  // Effacer la session
  Future<void> clearSession() async {
    _token = null;
    _refreshToken = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.refreshTokenKey);
    await prefs.remove(AppConfig.userKey);
  }

  // Rafraîchir le token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      ).timeout(AppConfig.networkTimeout);

      if (response.statusCode != 200) {
        await clearSession();
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['access_token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.tokenKey, _token!);

      return true;
    } catch (e) {
      print('❌ Token refresh error: $e');
      await clearSession();
      return false;
    }
  }

  // Obtenir le JavaScript pour injecter les tokens dans localStorage
  String getLocalStorageInjectionScript() {
    if (_token == null) return '';

    final userJson = _user != null ? jsonEncode(_user) : 'null';
    final refreshTokenJs = _refreshToken != null ? "'$_refreshToken'" : 'null';

    return '''
      (function() {
        try {
          localStorage.setItem('access_token', '$_token');
          localStorage.setItem('token', '$_token');
          if ($refreshTokenJs) {
            localStorage.setItem('refresh_token', $refreshTokenJs);
          }
          if ($userJson) {
            localStorage.setItem('user', $userJson);
          }
          console.log('✅ Tokens injected into localStorage');
        } catch (e) {
          console.error('❌ Error injecting tokens:', e);
        }
      })();
    ''';
  }
}
