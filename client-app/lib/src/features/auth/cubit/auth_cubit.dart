import 'package:client_app/src/features/auth/models/profile_model.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';
import 'package:client_app/src/core/services/token_storage_service.dart';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import '../services/user_service.dart';

// Auth Cubit
class AuthCubit extends HydratedCubit<AuthState> {
  final AuthService _authService;
  final TokenStorageService _tokenStorageService;

  AuthCubit({
    AuthService? authService,
    TokenStorageService? tokenStorageService,
  })  : _authService = authService ?? AuthService(),
        _tokenStorageService = tokenStorageService ?? locator<TokenStorageService>(),
        super(const AuthInitial());

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String;
      switch (type) {
        case 'AuthInitial':
          return const AuthInitial();
        case 'AuthLoading':
          return const AuthLoading();
        case 'AuthPhoneNumberEntered':
          return AuthPhoneNumberEntered.fromJson(json);
        case 'AuthCodeSent':
          return AuthCodeSent.fromJson(json);
        case 'AuthVerificationLoading':
          return const AuthVerificationLoading();
        case 'AuthUpdatingProfile':
          return const AuthUpdatingProfile();
        case 'AuthSuccess':
          return AuthSuccess.fromJson(json);
        case 'AuthError':
          return AuthError.fromJson(json);
        default:
          return const AuthInitial();
      }
    } catch (e) {
      return const AuthInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    return state.toJson();
  }

  void resetAuth() {
    emit(const AuthInitial());
  }

  Future<void> checkAuthenticationStatus() async {
    try {
      final hasToken = await _tokenStorageService.hasAccessToken();
      if (!hasToken) {
        emit(const AuthInitial());
        return;
      }
      final userId = await _authService.getUserId();
      if (userId == null || userId.isEmpty) {
        emit(const AuthInitial());
        return;
      }
      final result = await _authService.getProfile();
      if (result['success'] == true) {
        final profile = ProfileModel.fromJson(result['profile'] as Map<String, dynamic>);
        final needsUserInfo = profile.firstName.trim().isEmpty || profile.lastName.trim().isEmpty;
        final needsLocation = await _checkLocationStatus();
        emit(AuthSuccess(
          userId: profile.id,
          isNewUser: needsUserInfo,
          needsLocation: needsLocation,
        ));
      } else {
        emit(const AuthInitial());
      }
    } catch (e) {
      emit(const AuthInitial());
    }
  }

  Future<bool> _checkLocationStatus() async {
    try {
      final userService = UserService();
      final coordinates = await userService.getCurrentCoordinates();
      return coordinates == null;
    } catch (e) {
      return true;
    }
  }

  /// Normalizes phone number by removing leading 0 after country code
  /// For Algeria (+213), removes leading 0 from phone number
  String _normalizePhoneNumber(String phoneNumber, String countryCode) {
    // For Algeria (+213), remove leading 0 if present
    if (countryCode == '+213' && phoneNumber.isNotEmpty && phoneNumber.startsWith('0')) {
      return phoneNumber.substring(1);
    }
    return phoneNumber;
  }

  /// Formats phone number for API (country code + phone number, no +)
  String _formatPhoneForApi(String phoneNumber, String countryCode) {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber, countryCode);
    return (countryCode + normalizedPhone).replaceAll('+', '');
  }

  Future<void> sendVerificationCode(String phoneNumber, String countryCode) async {
    try {
      emit(AuthLoading());

      // Validate phone number
      if (phoneNumber.isEmpty) {
        emit(const AuthError(message: 'errorPhoneNumberRequired'));
        return;
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
        emit(const AuthError(message: 'errorPhoneNumberInvalid'));
        return;
      }

      // Normalize phone number (remove leading 0 for Algeria)
      final normalizedPhone = _normalizePhoneNumber(phoneNumber, countryCode);

      if (normalizedPhone.length < 8) {
        emit(const AuthError(message: 'errorPhoneNumberMinLength'));
        return;
      }

      // Format phone number for API (strip '+' for backend)
      String formattedPhone = _formatPhoneForApi(phoneNumber, countryCode);
      final result = await _authService.sendVerificationCode(formattedPhone);

      if (result['success'] == true) {
        // Store normalized phone number in state
        emit(AuthCodeSent(
          phoneNumber: normalizedPhone,
          verificationId: result['verificationId'] ?? '',
        ));
      } else {
        emit(AuthError(message: result['message'] ?? 'errorCodeSendFailed'));
      }
    } catch (e) {
      emit(AuthError(message: 'errorConnection|${e.toString()}'));
    }
  }

  Future<void> verifyCode(String phoneNumber, String code) async {
    try {
      emit(AuthVerificationLoading());

      if (code.length != 6) {
        emit(const AuthError(message: 'errorCodeLength'));
        return;
      }

      final result = await _authService.verifyCode(phoneNumber, code);
      if (result['success'] == true) {
        final accessToken = result['access_token'] as String?;
        final refreshToken = result['refresh_token'] as String?;

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

        final ProfileModel profile = ProfileModel.fromJson(result['profile'] as Map<String, dynamic>);
        await _authService.saveUserId(profile.id);
        final needsUserInfo = profile.firstName.trim().isEmpty || profile.lastName.trim().isEmpty;
        final needsLocation = await _checkLocationStatus();
        emit(AuthSuccess(
          userId: profile.id,
          isNewUser: needsUserInfo,
          needsLocation: needsLocation,
        ));
      } else {
        emit(AuthError(message: result['message'] ?? 'errorCodeInvalid'));
      }
    } catch (e) {
      emit(AuthError(message: 'errorVerification|${e.toString()}'));
    }
  }

  void clearError() {
    if (state is AuthError) {
      emit(AuthInitial());
    }
  }

  Future<void> updateUserInfo({
    required String firstName,
    required String lastName,
    required String userId,
  }) async {
    try {
      emit(AuthUpdatingProfile());

      // Validate inputs
      if (firstName.trim().isEmpty) {
        emit(const AuthError(message: 'errorFirstNameRequired'));
        return;
      }

      if (lastName.trim().isEmpty) {
        emit(const AuthError(message: 'errorLastNameRequired'));
        return;
      }

      final result = await _authService.updateUserInfo(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        userId: userId,
      );

      if (result['success'] == true) {
        final needsLocation = await _checkLocationStatus();
        emit(AuthSuccess(userId: userId, isNewUser: false, needsLocation: needsLocation));
      } else {
        emit(AuthError(message: result['message'] ?? 'errorProfileUpdateFailed'));
      }
    } catch (e) {
      emit(AuthError(message: 'errorProfileUpdate|${e.toString()}'));
    }
  }

  Future<bool> logout() async {
    try {
      await locator<LocationCubit>().clearSavedLocation();
      final success = await _authService.logout();
      if (success) {
        emit(AuthInitial());
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
