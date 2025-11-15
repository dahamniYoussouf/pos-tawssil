import 'package:restaurant_app/src/core/config/api_config.dart';
import 'package:restaurant_app/src/core/services/base_api_service.dart';
import 'package:restaurant_app/src/core/services/token_storage_service.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';

class AuthService extends BaseApiService {
  final TokenStorageService _tokenStorageService = locator<TokenStorageService>();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await postRequest(
        ApiConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
          'role': 'restaurant',
        },
        includeAuth: false,
      );

      if (response['success'] == true || response['access_token'] != null) {
        final accessToken = response['access_token'] as String?;
        final refreshToken = response['refresh_token'] as String?;

        if (accessToken != null) {
          if (refreshToken != null) {
            await _tokenStorageService.setTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
          } else {
            await _tokenStorageService.setAccessToken(accessToken);
          }
        }

        return {
          'success': true,
          'message': response['message'] ?? 'Login successful',
          'user': response['user'],
          'profile': response['profile'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during login',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String restaurantName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required List<String> restaurantCategories,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String willaya,
    required String zone,
  }) async {
    try {
      final List<String> normalizedCategories = restaurantCategories.map((String category) => category.toLowerCase()).toList();
      final response = await postRequest(
        ApiConfig.registerEndpoint,
        data: {
          'email': email,
          'phone': phoneNumber,
          'name': restaurantName,
          'password': password,
          'confirm_password': confirmPassword,
          'categories': normalizedCategories,
          'willaya': willaya,
          'address': address,
          'description': description,
          'lat': latitude,
          'lng': longitude,
          'zone': zone,
          'role': 'restaurant',
          "opening_hours": {
            "mon": {"open": 900, "close": 1800},
            "tue": {"open": 900, "close": 1800},
            "wed": {"open": 900, "close": 2200},
            "thu": {"open": 400, "close": 2200},
            "fri": {"open": 1000, "close": 2300},
            "sat": {"open": 1000, "close": 2300},
            "sun": {"open": 1200, "close": 2000}
          }
        },
        includeAuth: false,
      );

      if (response['success'] == true || response['access_token'] != null) {
        final accessToken = response['access_token'] as String?;
        final refreshToken = response['refresh_token'] as String?;

        if (accessToken != null) {
          if (refreshToken != null) {
            await _tokenStorageService.setTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
          } else {
            await _tokenStorageService.setAccessToken(accessToken);
          }
        }

        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful',
          'user': response['user'],
          'profile': response['profile'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during registration',
      };
    }
  }

  Future<bool> logout() async {
    try {
      await _tokenStorageService.clearAllTokens();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      return await _tokenStorageService.hasAccessToken();
    } catch (e) {
      return false;
    }
  }
}
