import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/restaurant_repository.dart';
import 'restaurant_state.dart';

// Restaurant Cubit
class RestaurantCubit extends Cubit<RestaurantState> {
  final RestaurantRepository _restaurantRepository;

  RestaurantCubit({
    RestaurantRepository? restaurantRepository,
  })  : _restaurantRepository = restaurantRepository ?? RestaurantRepository(),
        super(RestaurantInitial());

  Future<void> loadRestaurantsByLocation(double latitude, double longitude,
      {int radius = 5000}) async {
    if (isClosed) return;
    emit(RestaurantLoading());

    final result = await _restaurantRepository.getNearbyRestaurants(
      lat: latitude,
      lng: longitude,
      radius: radius,
    );

    if (isClosed) return;
    result.fold(
      (error) {
        if (!isClosed) emit(RestaurantError(message: error));
      },
      (restaurants) {
        final categories = _restaurantRepository.getStaticCategories();
        if (!isClosed) {
          emit(RestaurantLoaded(
            restaurants: restaurants,
            categories: categories,
          ));
        }
      },
    );
  }

  void clearError() {
    if (!isClosed && state is RestaurantError) {
      emit(RestaurantInitial());
    }
  }

  void clearSearch() {
    if (!isClosed) {
      emit(RestaurantInitial());
    }
  }

  void resetToInitial() {
    if (!isClosed) {
      emit(RestaurantInitial());
    }
  }
}
