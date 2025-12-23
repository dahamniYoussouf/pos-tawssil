import 'package:equatable/equatable.dart';

abstract class AddressSearchState extends Equatable {
  const AddressSearchState();

  @override
  List<Object?> get props => [];
}

class AddressSearchInitial extends AddressSearchState {}

class AddressSearchLoading extends AddressSearchState {}

class AddressSearchSuccess extends AddressSearchState {
  final String address;
  final double latitude;
  final double longitude;

  const AddressSearchSuccess({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [address, latitude, longitude];
}

class AddressSearchError extends AddressSearchState {
  final String message;

  const AddressSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}

