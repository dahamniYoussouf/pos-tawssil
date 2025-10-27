import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/restaurant_service.dart';
import '../../services/user_service.dart';
import '../../models/restaurant.dart';
import '../../models/category.dart';
import '../../models/menu_item.dart';

// Restaurant States
abstract class RestaurantState extends Equatable {
  const RestaurantState();

  @override
  List<Object?> get props => [];
}

class RestaurantInitial extends RestaurantState {}

class RestaurantLoading extends RestaurantState {}

class RestaurantSearchLoading extends RestaurantState {}

class RestaurantLoaded extends RestaurantState {
  final List<Restaurant> restaurants;
  final List<Category> categories;
  final String? searchQuery;
  final String? selectedCategory;

  const RestaurantLoaded({
    required this.restaurants,
    required this.categories,
    this.searchQuery,
    this.selectedCategory,
  });

  @override
  List<Object?> get props =>
      [restaurants, categories, searchQuery, selectedCategory];

  RestaurantLoaded copyWith({
    List<Restaurant>? restaurants,
    List<Category>? categories,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return RestaurantLoaded(
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class RestaurantSearchResults extends RestaurantState {
  final List<Restaurant> restaurants;
  final String searchQuery;
  final bool hasMore;

  const RestaurantSearchResults({
    required this.restaurants,
    required this.searchQuery,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [restaurants, searchQuery, hasMore];
}

class RestaurantDetailsLoaded extends RestaurantState {
  final Restaurant restaurant;
  final List<Category> categories;
  final List<MenuItem> menuItems;

  const RestaurantDetailsLoaded({
    required this.restaurant,
    required this.categories,
    required this.menuItems,
  });

  @override
  List<Object?> get props => [restaurant, categories, menuItems];
}

class RestaurantError extends RestaurantState {
  final String message;

  const RestaurantError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Restaurant Cubit
class RestaurantCubit extends Cubit<RestaurantState> {
  final RestaurantService _restaurantService;
  final UserService _userService;

  RestaurantCubit({
    RestaurantService? restaurantService,
    UserService? userService,
  })  : _restaurantService = restaurantService ?? RestaurantService(),
        _userService = userService ?? UserService(),
        super(RestaurantInitial());

  Future<void> loadNearbyRestaurants({int radius = 2000}) async {
    try {
      emit(RestaurantLoading());

      final restaurants =
          await _restaurantService.getNearbyRestaurantsFromStoredLocation(
        radius: radius,
      );
      final categories = await _restaurantService.getCategories();

      emit(RestaurantLoaded(
        restaurants: restaurants,
        categories: categories,
      ));
    } catch (e) {
      emit(RestaurantError(
          message:
              'Erreur lors du chargement des restaurants: ${e.toString()}'));
    }
  }

  Future<void> loadAllRestaurants() async {
    try {
      emit(RestaurantLoading());

      final restaurants = await _restaurantService.getRestaurants();
      final categories = await _restaurantService.getCategories();

      emit(RestaurantLoaded(
        restaurants: restaurants,
        categories: categories,
      ));
    } catch (e) {
      emit(RestaurantError(
          message:
              'Erreur lors du chargement des restaurants: ${e.toString()}'));
    }
  }

  Future<void> searchRestaurants(String query, {int maxResults = 50}) async {
    try {
      if (query.trim().length < 2) {
        emit(const RestaurantSearchResults(restaurants: [], searchQuery: ''));
        return;
      }

      emit(RestaurantSearchLoading());

      final restaurants = await _restaurantService.searchRestaurants(
        query: query,
        maxResults: maxResults,
      );

      emit(RestaurantSearchResults(
        restaurants: restaurants,
        searchQuery: query,
        hasMore: restaurants.length >= maxResults,
      ));
    } catch (e) {
      emit(RestaurantError(
          message: 'Erreur lors de la recherche: ${e.toString()}'));
    }
  }

  Future<void> loadRestaurantDetails(String restaurantId) async {
    try {
      emit(RestaurantLoading());

      final restaurant =
          await _restaurantService.getRestaurantById(restaurantId);
      final categories =
          await _restaurantService.getRestaurantCategories(restaurantId);
      final menuItems =
          await _restaurantService.getRestaurantMenuItems(restaurantId);

      emit(RestaurantDetailsLoaded(
        restaurant: restaurant,
        categories: categories,
        menuItems: menuItems,
      ));
    } catch (e) {
      emit(RestaurantError(
          message: 'Erreur lors du chargement des détails: ${e.toString()}'));
    }
  }

  Future<void> filterRestaurantsByCategory(String categoryName) async {
    final currentState = state;
    if (currentState is RestaurantLoaded) {
      try {
        // You need to pass both categoryId and userAddress (dummy address for now)
        final restaurants = await _restaurantService.getRestaurantsByCategory(
            categoryName, "user address");
        emit(currentState.copyWith(
          restaurants: restaurants,
          selectedCategory: categoryName,
        ));
      } catch (e) {
        emit(RestaurantError(
            message: 'Erreur lors du filtrage par catégorie: ${e.toString()}'));
      }
    }
  }

  Future<void> loadRestaurantsByLocation(double latitude, double longitude,
      {int radius = 5000}) async {
    emit(RestaurantLoading());

    try {
      final restaurants = await _restaurantService.getNearbyRestaurants(
          lat: latitude, lng: longitude, radius: radius);
      final categories = await _restaurantService.getCategories();

      emit(RestaurantLoaded(
        restaurants: restaurants,
        categories: categories,
      ));
    } catch (e) {
      emit(RestaurantError(
          message: 'Erreur de chargement des restaurants: ${e.toString()}'));
    }
  }

  void clearError() {
    if (state is RestaurantError) {
      emit(RestaurantInitial());
    }
  }

  void clearSearch() {
    emit(RestaurantInitial());
  }

  void resetToInitial() {
    emit(RestaurantInitial());
  }
}
