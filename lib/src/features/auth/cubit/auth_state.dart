import 'package:equatable/equatable.dart';

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
