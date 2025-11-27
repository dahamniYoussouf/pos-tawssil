import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/restaurant_repository.dart';
import '../../auth/services/user_service.dart';
import 'restaurant_state.dart';

// Restaurant Cubit
class RestaurantCubit extends Cubit<RestaurantState> {
  final RestaurantRepository _restaurantRepository;
  final UserService _userService;

  RestaurantCubit({
    RestaurantRepository? restaurantRepository,
    UserService? userService,
  })  : _restaurantRepository = restaurantRepository ?? RestaurantRepository(),
        _userService = userService ?? UserService(),
        super(RestaurantInitial());

  Future<void> loadNearbyRestaurants({int radius = 5000}) async {
    if (isClosed) return;
    emit(RestaurantLoading());

    try {
      // Get user coordinates
      final coords = await _userService.getCurrentCoordinates();

      if (isClosed) return;
      if (coords == null) {
        emit(const RestaurantError(message: 'Unable to get location. Please enable location services.'));
        return;
      }

      final result = await _restaurantRepository.getNearbyRestaurants(
        lat: coords['lat'],
        lng: coords['lng'],
        radius: radius,
      );

      if (isClosed) return;
      result.fold(
        (error) {
          if (!isClosed) emit(RestaurantError(message: error));
        },
        (restaurants) async {
          final categories = _restaurantRepository.getStaticCategories();
          final userLocation = await _userService.getCurrentLocation();
          if (!isClosed) {
            emit(RestaurantLoaded(
              restaurants: restaurants,
              categories: categories,
              userLocation: userLocation,
            ));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(RestaurantError(message: 'errorRestaurantsLoading|${e.toString()}'));
      }
    }
  }

  Future<void> loadRestaurantDetails(String restaurantId) async {
    if (isClosed) return;
    try {
      emit(RestaurantLoading());

      final restaurantResult = await _restaurantRepository.getRestaurantById(restaurantId);
      if (isClosed) return;
      final menuItemsResult = await _restaurantRepository.getRestaurantMenuItems(restaurantId);
      if (isClosed) return;
      final categories = _restaurantRepository.getStaticCategories();

      restaurantResult.fold(
        (error) {
          if (!isClosed) emit(RestaurantError(message: error));
        },
        (restaurant) {
          menuItemsResult.fold(
            (error) {
              if (!isClosed) emit(RestaurantError(message: error));
            },
            (menuItems) {
              if (!isClosed) {
                emit(RestaurantDetailsLoaded(
                  restaurant: restaurant,
                  categories: categories,
                  menuItems: menuItems,
                ));
              }
            },
          );
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(RestaurantError(message: 'errorRestaurantDetailsLoading|${e.toString()}'));
      }
    }
  }

  Future<void> loadRestaurantsByLocation(double latitude, double longitude, {int radius = 5000}) async {
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

  Future<void> searchRestaurants(String query, {int maxResults = 50}) async {
    if (isClosed) return;
    if (query.trim().isEmpty) {
      if (!isClosed) emit(RestaurantInitial());
      return;
    }

    emit(RestaurantSearchLoading());

    try {
      // Get user coordinates for location-based search
      final coords = await _userService.getCurrentCoordinates();

      if (isClosed) return;
      final result = await _restaurantRepository.getNearbyRestaurants(
        lat: coords?['lat'],
        lng: coords?['lng'],
        radius: 5000,
        q: query.trim(),
        pageSize: maxResults,
      );

      if (isClosed) return;
      result.fold(
        (error) {
          if (!isClosed) emit(RestaurantError(message: error));
        },
        (restaurants) {
          if (!isClosed) {
            emit(RestaurantSearchResults(
              restaurants: restaurants,
              searchQuery: query.trim(),
              hasMore: restaurants.length >= maxResults,
            ));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(RestaurantError(message: 'errorSearchRestaurants|${e.toString()}'));
      }
    }
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
