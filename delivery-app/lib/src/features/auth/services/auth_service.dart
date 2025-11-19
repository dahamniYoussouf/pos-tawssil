import 'package:delivery_app/src/core/config/api_config.dart';
import 'package:delivery_app/src/core/services/base_api_service.dart';
import 'package:delivery_app/src/core/services/token_storage_service.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';

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
          "type": "driver",
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
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
    required String willaya,
    required String zone,
  }) async {
    try {
      final response = await postRequest(
        ApiConfig.registerEndpoint,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phoneNumber,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'willaya': willaya,
          'zone': zone,
          "type": "driver",
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
