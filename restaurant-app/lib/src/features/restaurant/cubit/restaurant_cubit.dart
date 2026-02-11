import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/restaurant/repositories/restaurant_repository.dart';
import 'package:restaurant_app/src/features/restaurant/models/restaurant_model.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  final RestaurantRepository _restaurantRepository;

  RestaurantCubit({RestaurantRepository? restaurantRepository})
      : _restaurantRepository =
            restaurantRepository ?? locator<RestaurantRepository>(),
        super(RestaurantInitial());

  Future<void> fetchRestaurantDetails() async {
    if (state is RestaurantLoading) return;
    emit(RestaurantLoading());
    final result = await _restaurantRepository.getRestaurantDetails();
    result.fold(
      (error) => emit(RestaurantError(message: error)),
      (restaurant) {
        // Initialize status based on isActive or default to 'open' if null
        final initialStatus = restaurant.status ??
            (restaurant.isActive == true
                ? RestaurantStatus.open
                : RestaurantStatus.closed);
        emit(RestaurantLoaded(
          restaurant: restaurant.copyWith(status: initialStatus),
        ));
      },
    );
  }

  void updateStatus(String status) {
    if (state is! RestaurantLoaded) return;
    final currentState = state as RestaurantLoaded;

    // Static update only - update local model
    emit(RestaurantLoaded(
      restaurant: currentState.restaurant.copyWith(status: status),
    ));
  }

  Future<void> updateProfile(RestaurantModel restaurant) async {
    if (state is! RestaurantLoaded) return;

    emit(
        RestaurantLoading()); // Reuse loading or create specific for silent update
    final result =
        await _restaurantRepository.updateRestaurantProfile(restaurant);

    result.fold(
      (error) => emit(RestaurantError(message: error)),
      (_) => emit(RestaurantLoaded(restaurant: restaurant)),
    );
  }

  Future<void> updateImage(String path) async {
    if (state is! RestaurantLoaded) return;
    final currentState = state as RestaurantLoaded;

    emit(RestaurantLoading());
    final result = await _restaurantRepository.updateRestaurantImage(path);

    result.fold(
      (error) => emit(RestaurantError(message: error)),
      (imageUrl) {
        final updatedRestaurant =
            currentState.restaurant.copyWith(imageUrl: imageUrl);
        emit(RestaurantLoaded(restaurant: updatedRestaurant));
      },
    );
  }
}
