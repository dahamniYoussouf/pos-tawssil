import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/restaurant_service.dart';
import '../../auth/services/user_service.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/menu_model.dart';

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
  final List<RestaurantModel> restaurants;
  final List<CategoryModel> categories;
  final String? searchQuery;
  final String? selectedCategory;
  final String? username;
  final UserLocation? userLocation;

  const RestaurantLoaded({
    required this.restaurants,
    required this.categories,
    this.searchQuery,
    this.selectedCategory,
    this.username,
    this.userLocation,
  });

  @override
  List<Object?> get props => [restaurants, categories, searchQuery, selectedCategory, username, userLocation];

  RestaurantLoaded copyWith({
    List<RestaurantModel>? restaurants,
    List<CategoryModel>? categories,
    String? searchQuery,
    String? selectedCategory,
    String? username,
    UserLocation? userLocation,
  }) {
    return RestaurantLoaded(
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      username: username ?? this.username,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

class RestaurantSearchResults extends RestaurantState {
  final List<RestaurantModel> restaurants;
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
  final RestaurantModel restaurant;
  final List<CategoryModel> categories;
  final List<MenuModel> menuItems;

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

  Future<void> loadNearbyRestaurants({int radius = 5000}) async {
    try {
      emit(RestaurantLoading());
      final restaurants = await _restaurantService.getNearbyRestaurantsFromStoredLocation(
        radius: radius,
      );
      final categories = await _restaurantService.getCategories();
      final username = await _userService.getCurrentUsername();
      final userLocation = await _userService.getCurrentLocation();
      emit(RestaurantLoaded(
        restaurants: restaurants,
        categories: categories,
        username: username,
        userLocation: userLocation,
      ));
    } catch (e) {
      emit(RestaurantError(message: 'Erreur lors du chargement des restaurants: ${e.toString()}'));
    }
  }

  Future<void> loadAllRestaurants() async {
    try {
      emit(RestaurantLoading());
      final restaurants = await _restaurantService.getRestaurants();
      final categories = await _restaurantService.getCategories();
      final username = await _userService.getCurrentUsername();
      final userLocation = await _userService.getCurrentLocation();
      emit(RestaurantLoaded(
        restaurants: restaurants,
        categories: categories,
        username: username,
        userLocation: userLocation,
      ));
    } catch (e) {
      emit(RestaurantError(message: 'Erreur lors du chargement des restaurants: ${e.toString()}'));
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
      emit(RestaurantError(message: 'Erreur lors de la recherche: ${e.toString()}'));
    }
  }

  Future<void> loadRestaurantDetails(String restaurantId) async {
    try {
      emit(RestaurantLoading());

      final restaurant = await _restaurantService.getRestaurantById(restaurantId);
      final categories = await _restaurantService.getRestaurantCategories(restaurantId);
      final menuItems = await _restaurantService.getRestaurantMenuItems(restaurantId);

      emit(RestaurantDetailsLoaded(
        restaurant: restaurant,
        categories: categories,
        menuItems: menuItems,
      ));
    } catch (e) {
      emit(RestaurantError(message: 'Erreur lors du chargement des détails: ${e.toString()}'));
    }
  }

  Future<void> filterRestaurantsByCategory(String categoryName) async {
    final currentState = state;
    if (currentState is RestaurantLoaded) {
      try {
        // Use static example coordinates for testing
        final double latitude = 36.7309787;
        final double longitude = 3.1670409;
        final restaurants = await _restaurantService.getRestaurantsByCategory([categoryName], latitude, longitude);
        emit(currentState.copyWith(
          restaurants: restaurants,
          selectedCategory: categoryName,
        ));
      } catch (e) {
        emit(RestaurantError(message: 'Erreur lors du filtrage par catégorie: ${e.toString()}'));
      }
    }
  }

  Future<void> loadRestaurantsByLocation(double latitude, double longitude, {int radius = 5000}) async {
    emit(RestaurantLoading());

    try {
      final restaurants = await _restaurantService.getNearbyRestaurants(lat: latitude, lng: longitude, radius: radius);
      final categories = await _restaurantService.getCategories();

      emit(RestaurantLoaded(
        restaurants: restaurants,
        categories: categories,
      ));
    } catch (e) {
      emit(RestaurantError(message: 'Erreur de chargement des restaurants: ${e.toString()}'));
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
