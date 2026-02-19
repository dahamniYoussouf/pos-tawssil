import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:delivery_app/src/core/services/location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:delivery_app/src/features/driver/repositories/driver_repository.dart';
import 'dart:developer' as dev;

class DriverCubit extends Cubit<DriverState> {
  final DriverRepository _driverRepository;
  final LocationService _locationService;

  DriverCubit({
    DriverRepository? driverRepository,
    LocationService? locationService,
  })  : _driverRepository = driverRepository ?? locator<DriverRepository>(),
        _locationService = locationService ?? locator<LocationService>(),
        super(const DriverInitial());

  Future<void> fetchDriverProfile() async {
    emit(const DriverLoading());
    final result = await _driverRepository.fetchDriverProfile();
    result.fold(
      (error) => emit(DriverError(message: error)),
      (driver) {
        emit(DriverLoaded(driver: driver));
        if (driver.isActive) {
          _startLocationTracking(driver.id);
        }
      },
    );
  }

  void _startLocationTracking(String driverId) {
    _locationService.startTracking((position) async {
      final result = await _driverRepository.updateGPS(
        driverId,
        position.latitude,
        position.longitude,
      );
      result.fold(
        (error) => dev.log('[DriverCubit] Failed to update GPS: $error',
            name: 'DriverCubit'),
        (_) => dev.log('[DriverCubit] GPS updated successfully',
            name: 'DriverCubit'),
      );
    });
  }

  Future<void> toggleActiveStatus() async {
    if (state is DriverLoaded) {
      final currentDriver = (state as DriverLoaded).driver;
      final newIsActive = !currentDriver.isActive;
      final apiStatus = newIsActive ? 'available' : 'offline';

      // Optimistic update
      emit(DriverLoaded(
        driver: currentDriver.copyWith(
          isActive: newIsActive,
          status: apiStatus,
        ),
      ));

      if (newIsActive) {
        _startLocationTracking(currentDriver.id);
      } else {
        _locationService.stopTracking();
      }

      // Call API
      final result = await _driverRepository.updateStatus(apiStatus);
      result.fold(
        (error) {
          dev.log('[DriverCubit] Failed to update status: $error',
              name: 'DriverCubit');
          // Revert on failure
          emit(DriverLoaded(
            driver: currentDriver.copyWith(
              isActive: !newIsActive,
              status: !newIsActive ? 'available' : 'offline',
            ),
          ));
          if (!newIsActive) {
            _startLocationTracking(currentDriver.id);
          } else {
            _locationService.stopTracking();
          }
        },
        (_) => dev.log('[DriverCubit] Status updated to $apiStatus',
            name: 'DriverCubit'),
      );
    }
  }

  @override
  Future<void> close() {
    _locationService.stopTracking();
    return super.close();
  }

  DriverModel? get driver =>
      state is DriverLoaded ? (state as DriverLoaded).driver : null;
}
