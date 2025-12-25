import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class CreateAddressUiState extends Equatable {
  const CreateAddressUiState();

  @override
  List<Object?> get props => [];
}

class CreateAddressUiInitial extends CreateAddressUiState {
  final LatLng currentPosition;
  final String selectedAddress;
  final double? selectedLat;
  final double? selectedLng;
  final bool isDefault;

  const CreateAddressUiInitial({
    this.currentPosition = const LatLng(36.747385, 6.27404),
    this.selectedAddress = '',
    this.selectedLat,
    this.selectedLng,
    this.isDefault = false,
  });

  CreateAddressUiInitial copyWith({
    LatLng? currentPosition,
    String? selectedAddress,
    double? selectedLat,
    double? selectedLng,
    bool? isDefault,
  }) {
    return CreateAddressUiInitial(
      currentPosition: currentPosition ?? this.currentPosition,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedLat: selectedLat ?? this.selectedLat,
      selectedLng: selectedLng ?? this.selectedLng,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
        currentPosition,
        selectedAddress,
        selectedLat,
        selectedLng,
        isDefault,
      ];
}

class CreateAddressUiCubit extends Cubit<CreateAddressUiState> {
  CreateAddressUiCubit() : super(const CreateAddressUiInitial());

  void updatePosition(LatLng position) {
    final currentState = state;
    if (currentState is CreateAddressUiInitial) {
      emit(currentState.copyWith(currentPosition: position));
    }
  }

  void updateSelectedAddress({
    required String address,
    required double lat,
    required double lng,
  }) {
    final currentState = state;
    if (currentState is CreateAddressUiInitial) {
      emit(
        currentState.copyWith(
          selectedAddress: address,
          selectedLat: lat,
          selectedLng: lng,
        ),
      );
    }
  }

  void updatePositionAndAddress({
    required LatLng position,
    required String address,
    required double lat,
    required double lng,
    bool? isDefault,
  }) {
    final currentState = state;
    if (currentState is CreateAddressUiInitial) {
      emit(
        currentState.copyWith(
          currentPosition: position,
          selectedAddress: address,
          selectedLat: lat,
          selectedLng: lng,
          isDefault: isDefault ?? currentState.isDefault,
        ),
      );
    }
  }

  void toggleDefault() {
    final currentState = state;
    if (currentState is CreateAddressUiInitial) {
      emit(currentState.copyWith(isDefault: !currentState.isDefault));
    }
  }

  void reset() {
    emit(const CreateAddressUiInitial());
  }
}
