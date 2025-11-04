import 'dart:async';

import 'package:frontend/src/features/auth/services/sms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/utils/dependency_injection.dart';
import '../../../core/services/base_api_service.dart';

class AuthService extends BaseApiService {
  static final AuthService _instance = AuthService._internal();
  final SmsService _smsService = SmsService();
  final TokenStorageService _tokenStorageService = locator<TokenStorageService>();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() : super();

  static const String _phoneKey = 'user_phone';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _verificationCodeKey = 'verification_code';

  /// Send a verification code to the user's phone number using the correct API
  Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return {
        'success': false,
        'message': 'Numéro de téléphone invalide',
      };
    }

    try {
      dio.options.headers = {'Content-Type': 'application/json'};

      final response = await dio.post(
        '${ApiConfig.baseUrl}/auth/otp/request',
        data: {"phone_number": phoneNumber},
      );

      final result = response.data is Map ? response.data : jsonDecode(response.data);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': result['message'] ?? 'Code de vérification envoyé',
          'verificationId': result['dev_otp'] ?? '',
          'isNewUser': result['is_new_user'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Erreur lors de l\'envoi du code',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion. Veuillez réessayer.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du code',
        'error': e.toString(),
      };
    }
  }

  /// Send phone number and request verification code
  /// This calls the API to send OTP via SMS
  Future<Map<String, dynamic>> sendPhoneNumber(String phoneNumber) async {
    try {
      // Save phone number
      await _savePhoneNumber(phoneNumber);

      // Request OTP from API
      final apiResult = await _smsService.requestOtpCode(phoneNumber);

      if (apiResult['success']) {
        // Save the dev_otp for verification if provided
        if (apiResult['dev_otp'] != null) {
          await _saveVerificationCode(apiResult['dev_otp']);
        }

        return {
          'success': true,
          'message': apiResult['message'] ?? 'Code de vérification envoyé par SMS',
          'is_new_user': apiResult['is_new_user'] ?? false,
          // Include dev_otp for testing purposes
          if (apiResult['dev_otp'] != null) 'dev_otp': apiResult['dev_otp'],
        };
      } else {
        return {
          'success': false,
          'message': apiResult['message'] ?? 'Erreur lors de l\'envoi du code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du code',
      };
    }
  }

  /// Verify the code entered by user using the correct API
  Future<Map<String, dynamic>> verifyCode(String phoneNumber, String otp) async {
    try {
      dio.options.headers = {'Content-Type': 'application/json'};

      final response = await dio.post(
        '${ApiConfig.baseUrl}/auth/otp/verify',
        data: {"phone_number": phoneNumber, "otp": otp},
      );

      final result = response.data is Map ? response.data : jsonDecode(response.data);

      // Treat 200 as success, regardless of 'success' field
      if (response.statusCode == 200) {
        // Check for message and tokens
        if (result['message'] == 'Login successful' && result['access_token'] != null) {
          // Check if this is a new user by checking if profile is missing or has default values
          final profile = result['profile'];
          final isNewUser = profile == null || profile['first_name'] == null || profile['first_name'].toString().toLowerCase() == 'user';

          return {
            'success': true,
            'message': result['message'],
            'access_token': result['access_token'],
            'refresh_token': result['refresh_token'],
            'user': result['user'],
            'profile': profile,
            'isNewUser': isNewUser,
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'Code incorrect. Veuillez réessayer.',
          };
        }
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Code incorrect. Veuillez réessayer.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la vérification',
      };
    }
  }

  /// Get or create user in backend based on phone number
  /// Calls the backend API to check if user exists or creates a new one
  Future<Map<String, dynamic>> _getOrCreateUserInBackend(String phoneNumber) async {
    try {
      // First, try to get all clients to check if user exists

      dio.options.headers = {'Content-Type': 'application/json'};

      final getResponse = await dio.get('${ApiConfig.baseUrl}/client/getall');

      if (getResponse.statusCode == 200) {
        final data = getResponse.data is Map ? getResponse.data : jsonDecode(getResponse.data);

        // Check if user with this phone number exists
        if (data['success'] && data['data'] != null) {
          final clients = data['data'] as List;
          final existingClient = clients.firstWhere(
            (client) => client['phone_number'] == phoneNumber,
            orElse: () => null,
          );

          if (existingClient != null) {
            // User exists
            return {
              'success': true,
              'userId': existingClient['id'],
              'userName': '${existingClient['first_name']} ${existingClient['last_name']}',
              'isNewUser': false,
            };
          }
        }
      }

      // User doesn't exist, create new one
      final phoneDigits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final lastFourDigits = phoneDigits.substring(phoneDigits.length - 4);

      final createUrl = '${ApiConfig.baseUrl}/client/create';

      final createResponse = await dio.post(
        createUrl,
        data: {
          'first_name': 'User',
          'last_name': lastFourDigits,
          'email': 'user$phoneDigits@tawsil.app',
          'phone_number': phoneNumber,
          'is_verified': true,
          'is_active': true,
        },
      );

      if (createResponse.statusCode == 201) {
        final data = createResponse.data is Map ? createResponse.data : jsonDecode(createResponse.data);
        if (data['success']) {
          final client = data['data'];
          return {
            'success': true,
            'userId': client['id'],
            'userName': '${client['first_name']} ${client['last_name']}',
            'isNewUser': true,
          };
        }
      }

      // If backend call fails, return error
      return {
        'success': false,
        'message': 'Impossible de créer le compte',
      };
    } catch (e) {
      // Fallback to local user creation if backend is unavailable
      final phoneDigits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final userId = 'local_$phoneDigits';
      final userName = 'User ${phoneDigits.substring(phoneDigits.length - 4)}';

      return {
        'success': true,
        'userId': userId,
        'userName': userName,
        'isNewUser': true,
      };
    }
  }

  /// Save phone number
  Future<bool> _savePhoneNumber(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_phoneKey, phone);
    } catch (e) {
      return false;
    }
  }

  /// Get saved phone number
  Future<String?> getPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_phoneKey);
    } catch (e) {
      return null;
    }
  }

  /// Save verification code
  Future<bool> _saveVerificationCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_verificationCodeKey, code);
    } catch (e) {
      return false;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Save user ID
  Future<bool> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user profile with first name and last name
  Future<Map<String, dynamic>> updateUserInfo({
    required String firstName,
    required String lastName,
    required String userId,
  }) async {
    try {
      // Get access token
      final accessToken = await _tokenStorageService.getAccessToken();

      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Non authentifié. Veuillez vous reconnecter.',
        };
      }

      // Call backend API to update user profile

      dio.options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await dio.put(
        "${ApiConfig.baseUrl}/client/profile",
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      final result = response.data is Map ? response.data : jsonDecode(response.data);

      if (response.statusCode == 200 && result['success'] == true) {
        return {
          'success': true,
          'message': 'Profil mis à jour avec succès',
          'user': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Erreur lors de la mise à jour du profil',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion. Veuillez réessayer.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour du profil',
      };
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final accessToken = await _tokenStorageService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Non authentifié. Veuillez vous reconnecter.',
        };
      }
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      final response = await dio.get('${ApiConfig.baseUrl}/client/profile/me');
      final result = response.data is Map ? response.data : jsonDecode(response.data);
      if (response.statusCode == 200 && result['success'] == true) {
        return {
          'success': true,
          'profile': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Erreur lors de la récupération du profil',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion. Veuillez réessayer.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la récupération du profil',
      };
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_verificationCodeKey);
      await _tokenStorageService.clearAllTokens();
      return true;
    } catch (e) {
      return false;
    }
  }
}
