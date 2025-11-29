import 'package:equatable/equatable.dart';
import '../models/menu_model.dart';

abstract class RestaurantDetailsState extends Equatable {
  const RestaurantDetailsState();

  @override
  List<Object?> get props => [];
}

class RestaurantDetailsInitial extends RestaurantDetailsState {}

class RestaurantDetailsLoading extends RestaurantDetailsState {}

class RestaurantDetailsLoaded extends RestaurantDetailsState {
  final List<MenuModel> menuItems;
  final List<MenuItemCategory> categories;
  final String? selectedCategoryId;
  final Set<String> favoriteFoods;
  final String? selectedItemId;

  const RestaurantDetailsLoaded({
    required this.menuItems,
    required this.categories,
    this.selectedCategoryId,
    this.favoriteFoods = const {},
    this.selectedItemId,
  });

  @override
  List<Object?> get props => [
        menuItems,
        categories,
        selectedCategoryId,
        favoriteFoods,
        selectedItemId,
      ];

  RestaurantDetailsLoaded copyWith({
    List<MenuModel>? menuItems,
    List<MenuItemCategory>? categories,
    String? selectedCategoryId,
    Set<String>? favoriteFoods,
    String? selectedItemId,
    bool clearSelectedItemId = false,
  }) {
    return RestaurantDetailsLoaded(
      menuItems: menuItems ?? this.menuItems,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      selectedItemId: clearSelectedItemId ? null : (selectedItemId ?? this.selectedItemId),
    );
  }
}

class RestaurantDetailsError extends RestaurantDetailsState {
  final String message;

  const RestaurantDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

