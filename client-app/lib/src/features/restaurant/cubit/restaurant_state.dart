import 'package:equatable/equatable.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/menu_model.dart';
import '../../auth/services/user_service.dart';

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
  final UserLocation? userLocation;

  const RestaurantLoaded({
    required this.restaurants,
    required this.categories,
    this.searchQuery,
    this.selectedCategory,
    this.userLocation,
  });

  @override
  List<Object?> get props => [restaurants, categories, searchQuery, selectedCategory, userLocation];

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
