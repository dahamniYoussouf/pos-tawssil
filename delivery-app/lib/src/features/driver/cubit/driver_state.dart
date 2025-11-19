import 'package:equatable/equatable.dart';
import 'package:delivery_app/src/features/driver/models/driver_model.dart';

abstract class DriverState extends Equatable {
  const DriverState();

  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {
  const DriverInitial();
}

class DriverLoading extends DriverState {
  const DriverLoading();
}

class DriverLoaded extends DriverState {
  final DriverModel driver;

  const DriverLoaded({required this.driver});

  @override
  List<Object?> get props => [driver];
}

class DriverError extends DriverState {
  final String message;

  const DriverError({required this.message});

  @override
  List<Object?> get props => [message];
}
