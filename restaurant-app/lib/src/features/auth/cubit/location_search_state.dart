import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/auth/models/location_selection.dart';

abstract class LocationSearchState extends Equatable {
  const LocationSearchState();

  @override
  List<Object?> get props => [];
}

class LocationSearchInitial extends LocationSearchState {
  const LocationSearchInitial();
}

class LocationSearchLoading extends LocationSearchState {
  const LocationSearchLoading();
}

class LocationSearchSuccess extends LocationSearchState {
  final LocationSelection selection;

  const LocationSearchSuccess({required this.selection});

  @override
  List<Object?> get props => [selection];
}

class LocationSearchError extends LocationSearchState {
  final String message;

  const LocationSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
