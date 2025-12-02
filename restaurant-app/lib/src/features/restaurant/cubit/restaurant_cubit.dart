import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/restaurant/repositories/restaurant_repository.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  final RestaurantRepository _restaurantRepository;

  RestaurantCubit({RestaurantRepository? restaurantRepository})
      : _restaurantRepository =
            restaurantRepository ?? locator<RestaurantRepository>(),
        super(RestaurantInitial());

  Future<void> fetchRestaurantDetails() async {
    emit(RestaurantLoading());
    final result = await _restaurantRepository.getRestaurantDetails();
    result.fold(
      (error) => emit(RestaurantError(message: error)),
      (restaurant) => emit(RestaurantLoaded(restaurant: restaurant)),
    );
  }
}
