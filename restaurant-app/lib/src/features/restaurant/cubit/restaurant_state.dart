import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/restaurant/models/restaurant_model.dart';

abstract class RestaurantState extends Equatable {
  const RestaurantState();

  @override
  List<Object?> get props => [];
}

class RestaurantInitial extends RestaurantState {}

class RestaurantLoading extends RestaurantState {}

class RestaurantLoaded extends RestaurantState {
  final RestaurantModel restaurant;
  final String status;

  const RestaurantLoaded({
    required this.restaurant,
    this.status = 'open',
  });

  @override
  List<Object?> get props => [restaurant, status];
}

class RestaurantError extends RestaurantState {
  final String message;

  const RestaurantError({required this.message});

  @override
  List<Object?> get props => [message];
}
