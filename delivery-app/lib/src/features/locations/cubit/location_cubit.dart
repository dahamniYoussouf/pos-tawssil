import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/location_repository.dart';
import 'location_state.dart';
import '../usecases/get_gps_location_usecase.dart';
import '../usecases/save_manual_address_usecase.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationRepository _locationRepository;
  final GetGpsLocationUseCase _getGpsLocationUseCase;
  final SaveManualAddressUseCase _saveManualAddressUseCase;

  LocationCubit({
    LocationRepository? locationRepository,
    GetGpsLocationUseCase? getGpsLocationUseCase,
    SaveManualAddressUseCase? saveManualAddressUseCase,
  })  : _locationRepository = locationRepository ?? LocationRepository(),
        _getGpsLocationUseCase =
            getGpsLocationUseCase ?? GetGpsLocationUseCase(),
        _saveManualAddressUseCase =
            saveManualAddressUseCase ?? SaveManualAddressUseCase(),
        super(LocationInitial());

  Future<void> requestLocationPermission() async {
    emit(LocationPermissionRequesting());
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        emit(const LocationPermissionDenied(
            message: 'Location permissions are permanently denied.'));
        return;
      }
      if (permission == LocationPermission.denied) {
        emit(const LocationPermissionDenied(
            message: 'Location permission denied.'));
        return;
      }
      // Permission granted → auto-fetch GPS location
      await getGpsLocation();
    } catch (e) {
      emit(LocationError(
          message: 'Error requesting permission: ${e.toString()}'));
    }
  }

  Future<void> getGpsLocation() async {
    emit(LocationLoading());
    final result = await _getGpsLocationUseCase.execute();
    if (result.isGpsDisabled) {
      emit(LocationGpsDisabled());
    } else if (result.isSuccess) {
      emit(LocationSuccess(
        area: result.area!,
        city: result.city!,
        fullAddress: result.fullAddress!,
        latitude: result.latitude,
        longitude: result.longitude,
      ));
    } else {
      emit(LocationError(message: result.errorMessage ?? 'Unknown error'));
    }
  }

  Future<void> saveManualAddress(String address) async {
    emit(LocationLoading());
    final result = await _saveManualAddressUseCase.execute(address);
    if (result.isSuccess) {
      emit(LocationSuccess(
        area: result.area!,
        city: result.city!,
        fullAddress: result.fullAddress!,
        latitude: result.latitude,
        longitude: result.longitude,
      ));
    } else {
      emit(LocationError(message: result.errorMessage ?? 'Unknown error'));
    }
  }

  void clearError() {
    if (state is LocationError) {
      emit(LocationInitial());
    }
  }

  void resetToInitial() {
    emit(LocationInitial());
  }

  void resetToPermissionGranted() {
    emit(LocationPermissionGranted());
  }

  Future<void> loadSavedLocation() async {
    try {
      // 1. Check if location is already saved in SharedPreferences
      final data = await _locationRepository.getLocationData();
      final area = data['area'];
      final city = data['city'];
      final fullAddress = data['fullAddress'];
      double? latitude = double.tryParse(data['latitude'].toString());
      double? longitude = double.tryParse(data['longitude'].toString());

      if (area != null && city != null && fullAddress != null) {
        // Location already saved → go straight to HomePage
        emit(LocationSuccess(
          area: area,
          city: city,
          fullAddress: fullAddress,
          latitude: latitude,
          longitude: longitude,
        ));
        return;
      }

      // 2. No saved location — check if OS permission was already granted
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // OS permission already granted → skip permission screen,
        // show sharing screen directly
        emit(LocationPermissionGranted());
        return;
      }

      // 3. No saved location AND no OS permission → show full flow
      emit(LocationInitial());
    } catch (e) {
      emit(LocationInitial());
    }
  }

  Future<void> clearSavedLocation() async {
    await _locationRepository.clearLocation();
    emit(LocationInitial());
  }

  void openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  void openAppSettings() {
    Geolocator.openAppSettings();
  }
}
