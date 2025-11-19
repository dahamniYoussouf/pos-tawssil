import 'package:delivery_app/src/features/driver/models/driver_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:delivery_app/src/features/driver/repositories/driver_repository.dart';

class DriverCubit extends Cubit<DriverState> {
  final DriverRepository _driverRepository;

  DriverCubit({
    DriverRepository? driverRepository,
  })  : _driverRepository = driverRepository ?? locator<DriverRepository>(),
        super(const DriverInitial());

  Future<void> fetchDriverProfile() async {
    emit(const DriverLoading());
    final result = await _driverRepository.fetchDriverProfile();
    result.fold(
      (error) => emit(DriverError(message: error)),
      (driver) => emit(DriverLoaded(driver: driver)),
    );
  }

  DriverModel? get driver => state is DriverLoaded ? (state as DriverLoaded).driver : null;
}
