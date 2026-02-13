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
    // Only show loading if we don't have data already
    if (state is! RestaurantLoaded) {
      emit(RestaurantLoading());
    }

    final result = await _restaurantRepository.getRestaurantDetails();
    result.fold(
      (error) {
        if (state is! RestaurantLoaded) {
          emit(RestaurantError(message: error));
        }
      },
      (restaurant) {
        if (state is RestaurantLoaded) {
          // hna ndiro Merge details fI nafs state but keep profile info
          final current = (state as RestaurantLoaded).restaurant;
          emit(RestaurantLoaded(
            restaurant: current.copyWith(
              categories: restaurant.categories,
            ),
          ));
        } else {
          final initialStatus = restaurant.status ??
              (restaurant.isActive == true
                  ? RestaurantStatus.open
                  : RestaurantStatus.closed);
          emit(RestaurantLoaded(
            restaurant: restaurant.copyWith(status: initialStatus),
          ));
        }
      },
    );
  }

  Future<void> fetchRestaurantProfile() async {
    if (state is! RestaurantLoaded) {
      emit(RestaurantLoading());
    }

    final result = await _restaurantRepository.getRestaurantProfile();
    result.fold(
      (error) {
        if (state is! RestaurantLoaded) {
          emit(RestaurantError(message: error));
        }
      },
      (restaurant) {
        if (state is RestaurantLoaded) {
          // hna ndiro Merge profile info fI nafs state but keep details like categories
          final current = (state as RestaurantLoaded).restaurant;
          emit(RestaurantLoaded(
            restaurant: restaurant.copyWith(
              categories: current.categories ?? restaurant.categories,
              status: current.status ?? restaurant.status,
            ),
          ));
        } else {
          final initialStatus = restaurant.status ??
              (restaurant.isActive == true
                  ? RestaurantStatus.open
                  : RestaurantStatus.closed);
          emit(RestaurantLoaded(
            restaurant: restaurant.copyWith(status: initialStatus),
          ));
        }
      },
    );
  }

  Future<void> updateStatus(String status, {String? note}) async {
    if (state is! RestaurantLoaded) return;
    final currentState = state as RestaurantLoaded;

    final previousRestaurant = currentState.restaurant;
    final updatedRestaurant = previousRestaurant.copyWith(status: status);

    emit(RestaurantLoading());

    final result =
        await _restaurantRepository.updateRestaurantStatus(status, note: note);

    result.fold(
      (error) => emit(RestaurantError(message: error)),
      (_) => emit(RestaurantLoaded(restaurant: updatedRestaurant)),
    );
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
