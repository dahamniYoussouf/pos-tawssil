import 'package:equatable/equatable.dart';

abstract class MapLocationState extends Equatable {
  const MapLocationState();

  @override
  List<Object?> get props => [];
}

class MapLocationInitial extends MapLocationState {}

class MapLocationLoading extends MapLocationState {}

class MapLocationSuccess extends MapLocationState {
  final String address;
  final double latitude;
  final double longitude;

  const MapLocationSuccess({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [address, latitude, longitude];
}

class MapLocationError extends MapLocationState {
  final String message;

  const MapLocationError({required this.message});

  @override
  List<Object?> get props => [message];
}
