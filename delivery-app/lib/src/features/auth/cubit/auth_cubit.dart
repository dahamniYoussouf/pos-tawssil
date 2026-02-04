import 'package:delivery_app/src/features/auth/services/auth_service.dart';
import 'package:delivery_app/src/core/services/token_storage_service.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/core/utils/either.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends HydratedCubit<AuthState> {
  final AuthService _authService;
  final TokenStorageService _tokenStorageService;

  AuthCubit({
    AuthService? authService,
    TokenStorageService? tokenStorageService,
  })  : _authService = authService ?? AuthService(),
        _tokenStorageService =
            tokenStorageService ?? locator<TokenStorageService>(),
        super(const AuthInitial());

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String;
      switch (type) {
        case 'AuthChecking':
          return const AuthChecking();
        case 'AuthInitial':
          return const AuthInitial();
        case 'AuthLoading':
          return const AuthLoading();
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

  Future<void> checkAuthenticationStatus() async {
    emit(const AuthChecking());
    final result = await _checkAuthenticationStatusEither();
    result.fold(
      (error) => emit(const AuthInitial()),
      (userId) => emit(AuthSuccess(userId: userId)),
    );
  }

  Future<Either<String, String>> _checkAuthenticationStatusEither() async {
    try {
      final hasToken = await _tokenStorageService.hasAccessToken();
      if (!hasToken) {
        return const Left('no_token');
      }
      final isAuthenticated = await _authService.isAuthenticated();
      if (isAuthenticated) {
        return const Right('');
      } else {
        return const Left('not_authenticated');
      }
    } catch (e) {
      return Left('check_auth_error|${e.toString()}');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    final validationResult =
        _validateLoginInput(email: email, password: password);
    if (validationResult.isLeft) {
      emit(AuthError(message: validationResult.left!));
      return;
    }
    final loginResult = await _performLogin(email: email, password: password);
    loginResult.fold(
      (error) => emit(AuthError(message: error)),
      (userId) => emit(AuthSuccess(userId: userId)),
    );
  }

  Either<String, void> _validateLoginInput({
    required String email,
    required String password,
  }) {
    if (email.isEmpty) {
      return const Left('errorEmailRequired');
    }
    if (password.isEmpty) {
      return const Left('errorPasswordRequired');
    }
    return const Right(null);
  }

  Future<Either<String, String>> _performLogin({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );
      if (result['success'] == true) {
        final userId = result['user']?['id']?.toString() ??
            result['profile']?['id']?.toString() ??
            '';
        return Right(userId);
      } else {
        return Left(result['message'] ?? 'errorLoginFailed');
      }
    } catch (e) {
      return Left('errorLogin|${e.toString()}');
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
    required String willaya,
    required String zone,
  }) async {
    emit(const AuthLoading());
    final validationResult = _validateRegisterInput(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      willaya: willaya,
      zone: zone,
    );
    if (validationResult.isLeft) {
      emit(AuthError(message: validationResult.left!));
      return;
    }
    final registerResult = await _performRegister(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      willaya: willaya,
      zone: zone,
    );
    registerResult.fold(
      (error) => emit(AuthError(message: error)),
      (userId) => emit(AuthSuccess(userId: userId)),
    );
  }

  Either<String, void> _validateRegisterInput({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
    required String willaya,
    required String zone,
  }) {
    if (firstName.isEmpty) {
      return const Left('errorFirstNameRequired');
    }
    if (lastName.isEmpty) {
      return const Left('errorLastNameRequired');
    }
    if (phoneNumber.isEmpty) {
      return const Left('errorPhoneNumberRequired');
    }
    if (email.isEmpty) {
      return const Left('errorEmailRequired');
    }
    if (password.isEmpty) {
      return const Left('errorPasswordRequired');
    }
    if (confirmPassword.isEmpty) {
      return const Left('errorConfirmPasswordRequired');
    }
    if (password != confirmPassword) {
      return const Left('errorPasswordMismatch');
    }
    if (willaya.isEmpty) {
      return const Left('errorWillayaRequired');
    }
    if (zone.isEmpty) {
      return const Left('errorZoneRequired');
    }
    return const Right(null);
  }

  Future<Either<String, String>> _performRegister({
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
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        willaya: willaya,
        zone: zone,
      );
      if (result['success'] == true) {
        final userId = result['user']?['id']?.toString() ??
            result['profile']?['id']?.toString() ??
            '';
        return Right(userId);
      } else {
        return Left(result['message'] ?? 'errorRegistrationFailed');
      }
    } catch (e) {
      return Left('errorRegistration|${e.toString()}');
    }
  }

  Future<void> logout() async {
    final result = await _performLogout();
    result.fold(
      (error) => emit(AuthError(message: error)),
      (success) => emit(const AuthInitial()),
    );
  }

  Future<Either<String, void>> _performLogout() async {
    try {
      final success = await _authService.logout();
      if (success) {
        return const Right(null);
      } else {
        return const Left('errorLogoutFailed');
      }
    } catch (e) {
      return Left('errorLogout|${e.toString()}');
    }
  }

  void clearError() {
    if (state is AuthError) {
      emit(const AuthInitial());
    }
  }
}
