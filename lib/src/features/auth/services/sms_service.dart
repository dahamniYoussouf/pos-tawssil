import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/api_config.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();

  factory SmsService() {
    return _instance;
  }

  SmsService._internal();

  /// Send OTP SMS using the login_check endpoint
  /// Returns true if SMS was sent successfully, false otherwise
  Future<bool> sendOtpSms({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      print('📤 Sending OTP SMS to: $phoneNumber');

      final url = '${ApiConfig.smsBaseUrl}/login_check';
      print('📡 POST: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'phone_number': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['message'] != null && data['message'].toString().contains('OTP envoyé')) {
          print('✅ SMS sent successfully via API');
          return true;
        } else {
          print('⚠️ API response indicates SMS not sent: ${data['message']}');
          return false;
        }
      } else {
        print('❌ Failed to send SMS. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Send phone number to get OTP code
  /// This method calls the login_check endpoint and returns the API response
  Future<Map<String, dynamic>> requestOtpCode(String phoneNumber) async {
    try {
      print('📞 Requesting OTP for phone: $phoneNumber');

      final url = '${ApiConfig.smsBaseUrl}/login_check';
      print('📡 POST: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'phone_number': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

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
      print('❌ Error requesting OTP: $e');
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
      print('🔐 Verifying OTP: $otpCode for phone: $phoneNumber');

      final url = '${ApiConfig.smsBaseUrl}/auth/otp/verify';
      print('📡 POST: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'phone_number': phoneNumber,
              'otp': otpCode,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'success': true,
          'message': data['message'] ?? 'Vérification réussie',
          'user_data': data,
          'is_verified': true,
        };
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
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
      print('❌ Error verifying OTP: $e');
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
      final url = '${ApiConfig.smsBaseUrl}/login_check';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'phone_number': 'test'}),
          )
          .timeout(const Duration(seconds: 10));

      print('🔍 API Test - Status: ${response.statusCode}');
      return response.statusCode != 404; // Any response except 404 means API is reachable
    } catch (e) {
      print('❌ API Test failed: $e');
      return false;
    }
  }
}
