import 'package:restaurant_app/src/features/auth/services/auth_service.dart';
import 'package:restaurant_app/src/core/services/token_storage_service.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/core/utils/either.dart';
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
    required String restaurantName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required List<String> restaurantCategories,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String willaya,
    required String zone,
  }) async {
    emit(const AuthLoading());
    final validationResult = _validateRegisterInput(
      restaurantName: restaurantName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
      restaurantCategories: restaurantCategories,
      willaya: willaya,
      zone: zone,
    );
    if (validationResult.isLeft) {
      emit(AuthError(message: validationResult.left!));
      return;
    }
    final registerResult = await _performRegister(
      restaurantName: restaurantName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
      restaurantCategories: restaurantCategories,
      description: description,
      address: address,
      latitude: latitude,
      longitude: longitude,
      willaya: willaya,
      zone: zone,
    );
    registerResult.fold(
      (error) => emit(AuthError(message: error)),
      (userId) => emit(AuthSuccess(userId: userId)),
    );
  }

  Either<String, void> _validateRegisterInput({
    required String restaurantName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required List<String> restaurantCategories,
    required String willaya,
    required String zone,
  }) {
    if (restaurantName.isEmpty) {
      return const Left('errorRestaurantNameRequired');
    }
    if (email.isEmpty) {
      return const Left('errorEmailRequired');
    }
    if (phoneNumber.isEmpty) {
      return const Left('errorPhoneNumberRequired');
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
    if (restaurantCategories.isEmpty) {
      return const Left('errorRestaurantTypeRequired');
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
    required String restaurantName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required List<String> restaurantCategories,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String willaya,
    required String zone,
  }) async {
    try {
      final result = await _authService.register(
        restaurantName: restaurantName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
        restaurantCategories: restaurantCategories,
        description: description,
        address: address,
        latitude: latitude,
        longitude: longitude,
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
