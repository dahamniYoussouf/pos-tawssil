import 'package:client_app/src/features/restaurant/cubit/restaurant_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/restaurant_repository.dart';

// Restaurant Search Cubit
class RestaurantSearchCubit extends Cubit<RestaurantSearchState> {
  final RestaurantRepository _restaurantRepository;

  RestaurantSearchCubit({
    RestaurantRepository? restaurantRepository,
  })  : _restaurantRepository = restaurantRepository ?? RestaurantRepository(),
        super(RestaurantSearchInitial());

  /// Search restaurants using getNearbyRestaurants with query parameter
  Future<void> searchRestaurants({
    required String query,
    double? lat,
    double? lng,
    String? address,
    int radius = 5000,
    List<String>? categories,
    int page = 1,
    int pageSize = 50,
  }) async {
    if (isClosed) return;

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      if (!isClosed) emit(RestaurantSearchInitial());
      return;
    }

    emit(RestaurantSearchLoading(query: trimmedQuery));

    try {
      final result = await _restaurantRepository.getNearbyRestaurants(
        address: address,
        lat: lat,
        lng: lng,
        radius: radius,
        q: trimmedQuery,
        categories: [],
        page: page,
        pageSize: pageSize,
      );

      if (isClosed) return;

      result.fold(
        (error) {
          if (!isClosed) {
            emit(RestaurantSearchError(message: error));
          }
        },
        (restaurants) {
          if (!isClosed) {
            emit(RestaurantSearchResults(
              restaurants: restaurants,
              searchQuery: trimmedQuery,
              hasMore: restaurants.length >= pageSize,
            ));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(RestaurantSearchError(
          message: 'An unexpected error occurred: ${e.toString()}',
        ));
      }
    }
  }

  /// Clear search and reset to initial state
  void clearSearch() {
    if (!isClosed) {
      emit(RestaurantSearchInitial());
    }
  }

  /// Clear error state
  void clearError() {
    if (!isClosed && state is RestaurantSearchError) {
      emit(RestaurantSearchInitial());
    }
  }

  /// Reset to initial state
  void resetToInitial() {
    if (!isClosed) {
      emit(RestaurantSearchInitial());
    }
  }
}
