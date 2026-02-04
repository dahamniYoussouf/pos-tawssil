import 'package:equatable/equatable.dart';

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

class AuthChecking extends AuthState {
  const AuthChecking();

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'AuthChecking'};
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

class AuthSuccess extends AuthState {
  final String userId;

  const AuthSuccess({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];

  factory AuthSuccess.fromJson(Map<String, dynamic> json) {
    return AuthSuccess(
      userId: json['userId'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AuthSuccess',
      'userId': userId,
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
