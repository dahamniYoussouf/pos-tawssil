import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_selection_state.dart';

class LocationSelectionCubit extends Cubit<LocationSelectionState> {
  LocationSelectionCubit({LatLng initialPosition = const LatLng(0, 0)})
      : super(LocationSelectionInitial(currentPosition: initialPosition));

  void updatePosition(LatLng position) {
    final currentState = state;
    if (currentState is LocationSelectionInitial) {
      emit(currentState.copyWith(currentPosition: position));
    }
  }

  void selectLocation(LatLng position) {
    final currentState = state;
    if (currentState is LocationSelectionInitial) {
      emit(currentState.copyWith(
        currentPosition: position,
        selectedPosition: position,
      ));
    }
  }

  void reset() {
    final currentState = state;
    if (currentState is LocationSelectionInitial) {
      emit(LocationSelectionInitial(
        currentPosition: currentState.currentPosition,
        selectedPosition: null,
      ));
    }
  }
}
