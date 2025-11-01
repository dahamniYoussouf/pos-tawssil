import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial());

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
      print('vlivked the buttom');
      emit(AuthVerificationLoading());

      if (code.length != 6) {
        emit(const AuthError(message: 'Le code doit contenir 6 chiffres'));
        return;
      }

      final result = await _authService.verifyCode(phoneNumber, code);

      if (result['success'] == true) {
        // Store access token in UserService
        await UserService().setAccessToken(result['access_token']);

        // Optionally store tokens and user info here
        // e.g. SharedPreferences, or pass to next screen
        // debugPrint tokens for now
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

class UserService {
  Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
