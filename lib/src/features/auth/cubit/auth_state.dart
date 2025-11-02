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

  const AuthCodeSent({
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationId];

  factory AuthCodeSent.fromJson(Map<String, dynamic> json) {
    return AuthCodeSent(
      phoneNumber: json['phoneNumber'] as String,
      verificationId: json['verificationId'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AuthCodeSent',
      'phoneNumber': phoneNumber,
      'verificationId': verificationId,
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

  const AuthSuccess({
    required this.userId,
    this.isNewUser = false,
  });

  @override
  List<Object?> get props => [userId, isNewUser];

  factory AuthSuccess.fromJson(Map<String, dynamic> json) {
    return AuthSuccess(
      userId: json['userId'] as String,
      isNewUser: json['isNewUser'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AuthSuccess',
      'userId': userId,
      'isNewUser': isNewUser,
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
