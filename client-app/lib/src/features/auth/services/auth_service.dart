import 'package:client_app/src/features/auth/services/sms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/utils/dependency_injection.dart';
import '../../../core/services/base_api_service.dart';

class AuthService extends BaseApiService {
  static final AuthService _instance = AuthService._internal();
  final SmsService _smsService = SmsService();
  final TokenStorageService _tokenStorageService =
      locator<TokenStorageService>();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() : super();

  static const String _phoneKey = 'user_phone';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';

  /// Send a verification code to the user's phone number using the correct API
  Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return {
        'success': false,
        'message': 'Numéro de téléphone invalide',
      };
    }

    final response = await postRequest(
      '/auth/otp/request',
      data: {"phone_number": phoneNumber},
      includeAuth: false,
    );

    // BaseApiService returns data directly for 200-299 status codes
    // If status is null, HTTP request was successful (200-299)
    // Then check the API's success field
    if (response['status'] == null && (response['success'] != false)) {
      return {
        'success': true,
        'message': response['message'] ?? 'Code de vérification envoyé',
        'dev_otp': response['dev_otp']?.toString() ??
            response['data']?['dev_otp']?.toString() ??
            '',
        'is_new_user': response['is_new_user'] ??
            response['data']?['is_new_user'] ??
            false,
      };
    } else {
      return {
        'success': false,
        'message': response['message'] ?? 'Erreur lors de l\'envoi du code',
      };
    }
  }

  /// Send phone number and request verification code
  /// This calls the API to send OTP via SMS
  Future<Map<String, dynamic>> sendPhoneNumber(String phoneNumber) async {
    try {
      // Request OTP from API
      final apiResult = await _smsService.requestOtpCode(phoneNumber);

      if (apiResult['success']) {
        return {
          'success': true,
          'message':
              apiResult['message'] ?? 'Code de vérification envoyé par SMS',
          'is_new_user': apiResult['is_new_user'] ?? false,
          'dev_otp': apiResult['dev_otp'] ?? '',
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
  Future<Map<String, dynamic>> verifyCode(
      String phoneNumber, String otp) async {
    final response = await postRequest(
      '/auth/otp/verify',
      data: {"phone_number": phoneNumber, "otp": otp},
      includeAuth: false,
    );

    // BaseApiService returns data directly for 200-299 status codes
    // If status is null, HTTP request was successful (200-299)
    if (response['status'] == null) {
      // Response data is at root level (BaseApiService returns Map directly)
      final result = response;

      // Check for message and tokens
      if (result['message'] == 'Login successful' &&
          result['access_token'] != null) {
        // Check if this is a new user by checking if profile is missing or has default values
        final profile = result['profile'];
        final isNewUser = profile == null ||
            profile['first_name'] == null ||
            profile['first_name'].toString().toLowerCase() == 'user';

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
        'message': response['message'] ?? 'Code incorrect. Veuillez réessayer.',
      };
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
    // Check if user is authenticated (BaseApiService will handle token, but we check first for better error message)
    final accessToken = await _tokenStorageService.getAccessToken();
    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Non authentifié. Veuillez vous reconnecter.',
      };
    }

    final response = await putRequest(
      '/client/profile',
      data: {
        'first_name': firstName,
        'last_name': lastName,
      },
      includeAuth: true,
    );

    if (response['success'] == true) {
      return {
        'success': true,
        'message': 'Profil mis à jour avec succès',
        'user': response['data'],
      };
    } else {
      return {
        'success': false,
        'message':
            response['message'] ?? 'Erreur lors de la mise à jour du profil',
      };
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    // Check if user is authenticated (BaseApiService will handle token, but we check first for better error message)
    final accessToken = await _tokenStorageService.getAccessToken();
    if (accessToken == null) {
      return {
        'success': false,
        'message': 'Non authentifié. Veuillez vous reconnecter.',
      };
    }

    final response = await getRequest(
      '/client/profile/me',
      includeAuth: true,
    );

    if (response['success'] == true) {
      return {
        'success': true,
        'profile': response['data'],
      };
    } else {
      final message =
          response['message'] ?? 'Erreur lors de la récupération du profil';
      // If user not found, automatically logout
      if (message == 'User not found') {
        await logout();
      }
      return {
        'success': false,
        'message': message,
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
      await _tokenStorageService.clearAllTokens();
      return true;
    } catch (e) {
      return false;
    }
  }
}
