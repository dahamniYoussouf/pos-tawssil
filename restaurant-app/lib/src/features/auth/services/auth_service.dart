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
    required String restaurantType,
    required String willaya,
    required String zone,
  }) async {
    try {
      final response = await postRequest(
        ApiConfig.registerEndpoint,
        data: {
          'restaurant_name': restaurantName,
          'email': email,
          'phone': phoneNumber,
          'password': password,
          'confirm_password': confirmPassword,
          'restaurant_type': restaurantType,
          'willaya': willaya,
          'zone': zone,
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

