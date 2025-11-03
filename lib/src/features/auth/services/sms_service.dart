import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/base_api_service.dart';

class SmsService extends BaseApiService {
  static final SmsService _instance = SmsService._internal();

  factory SmsService() {
    return _instance;
  }

  SmsService._internal() : super();

  /// Send OTP SMS using the login_check endpoint
  /// Returns true if SMS was sent successfully, false otherwise
  Future<bool> sendOtpSms({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      dio.options.headers = {
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        '${ApiConfig.smsBaseUrl}/login_check',
        data: {
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data is Map ? response.data : jsonDecode(response.data);

        if (data['message'] != null && data['message'].toString().contains('OTP envoyé')) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Send phone number to get OTP code
  /// This method calls the login_check endpoint and returns the API response
  Future<Map<String, dynamic>> requestOtpCode(String phoneNumber) async {
    try {
      dio.options.headers = {
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        '${ApiConfig.smsBaseUrl}/login_check',
        data: {
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data is Map ? response.data : jsonDecode(response.data);

        return {
          'success': true,
          'message': data['message'] ?? 'OTP envoyé avec succès',
          'phone_number': data['phone_number'],
          'is_new_user': data['is_new_user'] ?? false,
          'dev_otp': data['dev_otp'], // For development/testing
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de l\'envoi du code OTP',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion. Veuillez réessayer.',
        'error': e.toString(),
      };
    }
  }

  /// Verify OTP code using the auth/otp/verify endpoint
  /// Returns verification result with user information if successful
  Future<Map<String, dynamic>> verifyOtpCode({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      dio.options.headers = {
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        '${ApiConfig.smsBaseUrl}/auth/otp/verify',
        data: {
          'phone_number': phoneNumber,
          'otp': otpCode,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data is Map ? response.data : jsonDecode(response.data);

        return {
          'success': true,
          'message': data['message'] ?? 'Vérification réussie',
          'user_data': data,
          'is_verified': true,
        };
      } else if (response.statusCode == 400) {
        final data = response.data is Map ? response.data : jsonDecode(response.data);
        return {
          'success': false,
          'message': data['message'] ?? 'Code OTP incorrect',
          'is_verified': false,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la vérification',
          'status_code': response.statusCode,
          'is_verified': false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion. Veuillez réessayer.',
        'error': e.toString(),
        'is_verified': false,
      };
    }
  }

  /// Test method to check API connectivity
  Future<bool> testApiConnection() async {
    try {
      dio.options.headers = {
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        '${ApiConfig.smsBaseUrl}/login_check',
        data: {'phone_number': 'test'},
      );

      return response.statusCode != 404; // Any response except 404 means API is reachable
    } catch (e) {
      return false;
    }
  }
}
