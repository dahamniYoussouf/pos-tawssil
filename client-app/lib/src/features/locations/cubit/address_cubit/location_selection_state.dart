import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LocationSelectionState extends Equatable {
  const LocationSelectionState();

  @override
  List<Object?> get props => [];
}

class LocationSelectionInitial extends LocationSelectionState {
  final LatLng currentPosition;
  final LatLng? selectedPosition;

  const LocationSelectionInitial({
    required this.currentPosition,
    this.selectedPosition,
  });

  LocationSelectionInitial copyWith({
    LatLng? currentPosition,
    LatLng? selectedPosition,
  }) {
    return LocationSelectionInitial(
      currentPosition: currentPosition ?? this.currentPosition,
      selectedPosition: selectedPosition ?? this.selectedPosition,
    );
  }

  @override
  List<Object?> get props => [currentPosition, selectedPosition];
}

