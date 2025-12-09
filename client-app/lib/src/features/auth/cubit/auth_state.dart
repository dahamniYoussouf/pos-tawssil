import 'package:equatable/equatable.dart';

// Auth States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];

  Map<String, dynamic> toJson();
}

class AuthInitial extends AuthState {
  const AuthInitial();

  factory AuthInitial.fromJson(Map<String, dynamic> json) {
    return const AuthInitial();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'AuthInitial'};
  }
}

class AuthLoading extends AuthState {
  const AuthLoading();

  factory AuthLoading.fromJson(Map<String, dynamic> json) {
    return const AuthLoading();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'AuthLoading'};
  }
}

class AuthPhoneNumberEntered extends AuthState {
  final String phoneNumber;
  final String countryCode;

  const AuthPhoneNumberEntered({
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [phoneNumber, countryCode];

  factory AuthPhoneNumberEntered.fromJson(Map<String, dynamic> json) {
    return AuthPhoneNumberEntered(
      phoneNumber: json['phoneNumber'] as String,
      countryCode: json['countryCode'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AuthPhoneNumberEntered',
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
    };
  }
}

class AuthCodeSent extends AuthState {
  final String phoneNumber;
  final String verificationId;
  final int resendCountdown;
  final bool canResend;
  final bool isNewUser;

  const AuthCodeSent({
    required this.phoneNumber,
    required this.verificationId,
    this.resendCountdown = 60,
    this.canResend = false,
    this.isNewUser = false,
  });

  @override
  List<Object?> get props =>
      [phoneNumber, verificationId, resendCountdown, canResend, isNewUser];

  AuthCodeSent copyWith({
    String? phoneNumber,
    String? verificationId,
    int? resendCountdown,
    bool? canResend,
    bool? isNewUser,
  }) {
    return AuthCodeSent(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      canResend: canResend ?? this.canResend,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  factory AuthCodeSent.fromJson(Map<String, dynamic> json) {
    return AuthCodeSent(
      phoneNumber: json['phoneNumber'] as String,
      verificationId: json['dev_otp'] as String,
      resendCountdown: json['resendCountdown'] as int? ?? 60,
      canResend: json['canResend'] as bool? ?? false,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AuthCodeSent',
      'phoneNumber': phoneNumber,
      'dev_otp': verificationId,
      'resendCountdown': resendCountdown,
      'canResend': canResend,
      'is_new_user': isNewUser,
    };
  }
}

class AuthVerificationLoading extends AuthState {
  const AuthVerificationLoading();

  factory AuthVerificationLoading.fromJson(Map<String, dynamic> json) {
    return const AuthVerificationLoading();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'AuthVerificationLoading'};
  }
}

class AuthUpdatingProfile extends AuthState {
  const AuthUpdatingProfile();

  factory AuthUpdatingProfile.fromJson(Map<String, dynamic> json) {
    return const AuthUpdatingProfile();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'AuthUpdatingProfile'};
  }
}

class AuthSuccess extends AuthState {
  final String userId;
  final bool isNewUser;
  final bool needsLocation;

  const AuthSuccess({
    required this.userId,
    this.isNewUser = false,
    this.needsLocation = false,
  });

  @override
  List<Object?> get props => [userId, isNewUser, needsLocation];

  factory AuthSuccess.fromJson(Map<String, dynamic> json) {
    return AuthSuccess(
      userId: json['userId'] as String,
      isNewUser: json['is_new_user'] as bool? ?? false,
      needsLocation: json['needsLocation'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AuthSuccess',
      'userId': userId,
      'is_new_user': isNewUser,
      'needsLocation': needsLocation,
    };
  }
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];

  factory AuthError.fromJson(Map<String, dynamic> json) {
    return AuthError(
      message: json['message'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AuthError',
      'message': message,
    };
  }
}
