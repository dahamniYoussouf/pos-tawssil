import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';
import 'package:frontend/src/core/services/token_storage_service.dart';
import 'package:frontend/src/core/utils/dependency_injection.dart';

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
    emit(AuthInitial());
  }

  Future<void> sendVerificationCode(String phoneNumber, String countryCode) async {
    try {
      emit(AuthLoading());

      // Validate phone number
      if (phoneNumber.isEmpty) {
        emit(const AuthError(message: 'Veuillez entrer votre numéro de téléphone'));
        return;
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
        emit(const AuthError(message: 'Numéro de téléphone invalide'));
        return;
      }

      if (phoneNumber.length < 8) {
        emit(const AuthError(message: 'Le numéro de téléphone doit contenir au moins 8 chiffres'));
        return;
      }

      // Send verification code (strip '+' for backend)
      String formattedPhone = (countryCode + phoneNumber).replaceAll('+', '');
      final result = await _authService.sendVerificationCode(formattedPhone);

      if (result['success'] == true) {
        emit(AuthCodeSent(
          phoneNumber: phoneNumber,
          verificationId: result['verificationId'] ?? '',
        ));
      } else {
        emit(AuthError(message: result['message'] ?? 'Erreur lors de l\'envoi du code'));
      }
    } catch (e) {
      emit(AuthError(message: 'Erreur de connexion: ${e.toString()}'));
    }
  }

  Future<void> verifyCode(String phoneNumber, String code) async {
    try {
      emit(AuthVerificationLoading());

      if (code.length != 6) {
        emit(const AuthError(message: 'Le code doit contenir 6 chiffres'));
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

        print('[OTP] Access Token: ${result['access_token']}');
        print('[OTP] Refresh Token: ${result['refresh_token']}');
        print('[OTP] User: ${result['user']}');
        print('[OTP] Profile: ${result['profile']}');
        emit(AuthSuccess(userId: result['user']?['id'] ?? ''));
      } else {
        emit(AuthError(message: result['message'] ?? 'Code de vérification invalide'));
      }
    } catch (e) {
      emit(AuthError(message: 'Erreur de vérification: ${e.toString()}'));
    }
  }

  void clearError() {
    if (state is AuthError) {
      emit(AuthInitial());
    }
  }
}
