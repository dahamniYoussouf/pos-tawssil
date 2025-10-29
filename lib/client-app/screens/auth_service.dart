import 'dart:async';
import 'dart:io';

import 'package:frontend/client-app/screens/sms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final SmsService _smsService = SmsService();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static const String _phoneKey = 'user_phone';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _verificationCodeKey = 'verification_code';

  /// Send a verification code to the user's phone number using the correct API
Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
  print('🟢 sendVerificationCode function started');
  print('📞 Sending verification code to: $phoneNumber');
  
  if (phoneNumber.isEmpty) {
    print('❌ Phone number is empty!');
    return {
      'success': false,
      'message': 'Numéro de téléphone invalide',
    };
  }

  try {
    final url = 'https://tawssilbackyou.onrender.com/auth/otp/request';
    print('🌐 Calling URL: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"phone_number": phoneNumber}),
    ).timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('La requête a expiré');
      },
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    final result = json.decode(response.body);
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': result['message'] ?? 'Code de vérification envoyé',
        'verificationId': result['dev_otp'] ?? '',
        'isNewUser': result['is_new_user'] ?? false,
      };
    } else {
      print('❌ Error in response: ${result['message']}');
      return {
        'success': false,
        'message': result['message'] ?? 'Erreur lors de l\'envoi du code',
      };
    }
  } on TimeoutException catch (e) {
    print('❌ Timeout: $e');
    return {
      'success': false,
      'message': 'La connexion a expiré. Veuillez réessayer.',
    };
  } on SocketException catch (e) {
    print('❌ SocketException: ${e.message}');
    return {
      'success': false,
      'message': 'Pas de connexion Internet',
    };
  } on FormatException catch (e) {
    print('❌ FormatException: $e');
    return {
      'success': false,
      'message': 'Erreur de format de réponse',
    };
  } catch (e) {
    print('❌ Exception caught: $e');
    print('❌ Exception type: ${e.runtimeType}');
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
      print('📞 Sending phone number: $phoneNumber');

      // Save phone number
      await _savePhoneNumber(phoneNumber);

      // Request OTP from API
      print('📤 Requesting OTP from API...');
      final apiResult = await _smsService.requestOtpCode(phoneNumber);

      if (apiResult['success']) {
        // Save the dev_otp for verification if provided
        if (apiResult['dev_otp'] != null) {
          await _saveVerificationCode(apiResult['dev_otp']);
          print('✅ Dev OTP saved: ${apiResult['dev_otp']}');
        }

        print('✅ OTP request successful!');
        return {
          'success': true,
          'message':
              apiResult['message'] ?? 'Code de vérification envoyé par SMS',
          'is_new_user': apiResult['is_new_user'] ?? false,
          // Include dev_otp for testing purposes
          if (apiResult['dev_otp'] != null) 'dev_otp': apiResult['dev_otp'],
        };
      } else {
        print('❌ API request failed: ${apiResult['message']}');
        return {
          'success': false,
          'message': apiResult['message'] ?? 'Erreur lors de l\'envoi du code',
        };
      }
    } catch (e) {
      print('❌ Error sending phone number: $e');
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du code',
      };
    }
  }

  /// Verify the code entered by user using the correct API
  Future<Map<String, dynamic>> verifyCode(
      String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"phone_number": phoneNumber, "otp": otp}),
      );
      final result = json.decode(response.body);
      // Treat 200 as success, regardless of 'success' field
      if (response.statusCode == 200) {
        // Check for message and tokens
        if (result['message'] == 'Connexion réussie' &&
            result['access_token'] != null) {
          return {
            'success': true,
            'message': result['message'],
            'access_token': result['access_token'],
            'refresh_token': result['refresh_token'],
            'user': result['user'],
            'profile': result['profile'],
          };
        } else {
          // If message is not 'Connexion réussie', treat as error
          return {
            'success': false,
            'message':
                result['message'] ?? 'Code incorrect. Veuillez réessayer.',
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
  Future<Map<String, dynamic>> _getOrCreateUserInBackend(
      String phoneNumber) async {
    try {
      print('🌐 Calling backend API to get/create user...');

      // First, try to get all clients to check if user exists
      final getAllUrl = '${ApiConfig.baseUrl}/client/getall';
      print('📡 GET: $getAllUrl');

      final getResponse = await http.get(
        Uri.parse(getAllUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (getResponse.statusCode == 200) {
        final data = json.decode(getResponse.body);
        print(
            '✅ Got response from backend: ${data['data']?.length ?? 0} clients');

        // Check if user with this phone number exists
        if (data['success'] && data['data'] != null) {
          final clients = data['data'] as List;
          final existingClient = clients.firstWhere(
            (client) => client['phone_number'] == phoneNumber,
            orElse: () => null,
          );

          if (existingClient != null) {
            // User exists
            print('✅ Existing user found: ${existingClient['id']}');
            return {
              'success': true,
              'userId': existingClient['id'],
              'userName':
                  '${existingClient['first_name']} ${existingClient['last_name']}',
              'isNewUser': false,
            };
          }
        }
      }

      // User doesn't exist, create new one
      print('👤 Creating new user in backend...');
      final phoneDigits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final lastFourDigits = phoneDigits.substring(phoneDigits.length - 4);

      final createUrl = '${ApiConfig.baseUrl}/client/create';
      print('📡 POST: $createUrl');

      final createResponse = await http
          .post(
            Uri.parse(createUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'first_name': 'User',
              'last_name': lastFourDigits,
              'email': 'user$phoneDigits@tawsil.app',
              'phone_number': phoneNumber,
              'is_verified': true,
              'is_active': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response status: ${createResponse.statusCode}');
      print('📥 Response body: ${createResponse.body}');

      if (createResponse.statusCode == 201) {
        final data = json.decode(createResponse.body);
        if (data['success']) {
          final client = data['data'];
          print('✅ New user created: ${client['id']}');
          return {
            'success': true,
            'userId': client['id'],
            'userName': '${client['first_name']} ${client['last_name']}',
            'isNewUser': true,
          };
        }
      }

      // If backend call fails, return error
      print('❌ Failed to create user in backend');
      return {
        'success': false,
        'message': 'Impossible de créer le compte',
      };
    } catch (e) {
      print('❌ Error in _getOrCreateUserInBackend: $e');
      // Fallback to local user creation if backend is unavailable
      print('⚠️ Backend unavailable, using local fallback');
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

  /// Generate random 6-digit verification code
  String _generateVerificationCode() {
    return (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  }

  /// Save phone number
  Future<bool> _savePhoneNumber(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_phoneKey, phone);
    } catch (e) {
      print('Error saving phone: $e');
      return false;
    }
  }

  /// Get saved phone number
  Future<String?> getPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_phoneKey);
    } catch (e) {
      print('Error getting phone: $e');
      return null;
    }
  }

  /// Save verification code
  Future<bool> _saveVerificationCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_verificationCodeKey, code);
    } catch (e) {
      print('Error saving code: $e');
      return false;
    }
  }

  /// Get verification code
  Future<String?> _getVerificationCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_verificationCodeKey);
    } catch (e) {
      print('Error getting code: $e');
      return null;
    }
  }

  /// Clear verification code
  Future<bool> _clearVerificationCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_verificationCodeKey);
    } catch (e) {
      print('Error clearing code: $e');
      return false;
    }
  }

  /// Set logged in status
  Future<bool> _setLoggedIn(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_isLoggedInKey, status);
    } catch (e) {
      print('Error setting logged in status: $e');
      return false;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking logged in status: $e');
      return false;
    }
  }

  /// Save user ID
  Future<bool> _saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userIdKey, userId);
    } catch (e) {
      print('Error saving user ID: $e');
      return false;
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  /// Save user name
  Future<bool> _saveUserName(String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userNameKey, userName);
    } catch (e) {
      print('Error saving user name: $e');
      return false;
    }
  }

  /// Get user name
  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      print('Error getting user name: $e');
      return null;
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
      print('✅ User logged out successfully');
      return true;
    } catch (e) {
      print('❌ Error logging out: $e');
      return false;
    }
  }
}
