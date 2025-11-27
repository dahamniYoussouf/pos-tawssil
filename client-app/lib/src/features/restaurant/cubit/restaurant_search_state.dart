import 'package:equatable/equatable.dart';
import '../models/restaurant_model.dart';

// Restaurant Search States
abstract class RestaurantSearchState extends Equatable {
  const RestaurantSearchState();

  @override
  List<Object?> get props => [];
}

class RestaurantSearchInitial extends RestaurantSearchState {}

class RestaurantSearchLoading extends RestaurantSearchState {
  final String query;

  const RestaurantSearchLoading({required this.query});

  @override
  List<Object?> get props => [query];
}

class RestaurantSearchResults extends RestaurantSearchState {
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

class RestaurantSearchError extends RestaurantSearchState {
  final String message;

  const RestaurantSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
