import 'package:equatable/equatable.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/homepage_models.dart';

abstract class HomepageState extends Equatable {
  const HomepageState();
  @override
  List<Object?> get props => [];
}

class HomepageInitial extends HomepageState {}

class HomepageLoading extends HomepageState {}

class HomepageLoaded extends HomepageState {
  final List<RestaurantModel> restaurants;
  final List<CategoryModel> categories;
  final HomepageDataModel homepageData;

  const HomepageLoaded({
    required this.restaurants,
    required this.categories,
    required this.homepageData,
  });

  @override
  List<Object?> get props => [restaurants, categories, homepageData];
}

class HomepageError extends HomepageState {
  final String message;

  const HomepageError({required this.message});

  @override
  List<Object?> get props => [message];
}
