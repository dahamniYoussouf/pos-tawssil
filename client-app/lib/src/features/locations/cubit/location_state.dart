import 'package:equatable/equatable.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationPermissionRequesting extends LocationState {}

class LocationPermissionGranted extends LocationState {}

class LocationPermissionDenied extends LocationState {
  final String message;

  const LocationPermissionDenied({required this.message});

  @override
  List<Object?> get props => [message];
}

class LocationLoading extends LocationState {}

class LocationGpsDisabled extends LocationState {}

class LocationSuccess extends LocationState {
  final String area;
  final String city;
  final String fullAddress;
  final double? latitude;
  final double? longitude;

  const LocationSuccess({
    required this.area,
    required this.city,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [area, city, fullAddress, latitude, longitude];
}

class LocationError extends LocationState {
  final String message;

  const LocationError({required this.message});

  @override
  List<Object?> get props => [message];
}
