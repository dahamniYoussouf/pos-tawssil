import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../screens/auth_service.dart';

// Auth States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthPhoneNumberEntered extends AuthState {
  final String phoneNumber;
  final String countryCode;

  const AuthPhoneNumberEntered({
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [phoneNumber, countryCode];
}

class AuthCodeSent extends AuthState {
  final String phoneNumber;
  final String verificationId;

  const AuthCodeSent({
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationId];
}

class AuthVerificationLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String userId;

  const AuthSuccess({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial());

  void resetAuth() {
    emit(AuthInitial());
  }

  Future<void> sendVerificationCode(
      String phoneNumber, String countryCode) async {
    try {
      emit(AuthLoading());

      // Validate phone number
      if (phoneNumber.isEmpty) {
        emit(const AuthError(
            message: 'Veuillez entrer votre numéro de téléphone'));
        return;
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
        emit(const AuthError(message: 'Numéro de téléphone invalide'));
        return;
      }

      if (phoneNumber.length < 8) {
        emit(const AuthError(
            message:
                'Le numéro de téléphone doit contenir au moins 8 chiffres'));
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
        emit(AuthError(
            message: result['message'] ?? 'Erreur lors de l\'envoi du code'));
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
        // Optionally store tokens and user info here
        // e.g. SharedPreferences, or pass to next screen
        // debugPrint tokens for now
  print('[OTP] Access Token: ${result['access_token']}');
  print('[OTP] Refresh Token: ${result['refresh_token']}');
  print('[OTP] User: ${result['user']}');
  print('[OTP] Profile: ${result['profile']}');
        emit(AuthSuccess(userId: result['user']?['id'] ?? ''));
      } else {
        emit(AuthError(
            message: result['message'] ?? 'Code de vérification invalide'));
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
