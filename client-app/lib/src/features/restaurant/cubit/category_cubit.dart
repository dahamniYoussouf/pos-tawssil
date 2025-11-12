import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/restaurant_service.dart';
import '../models/category_model.dart';

// Category States
abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  const CategoryLoaded({required this.categories});
  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError({required this.message});
  @override
  List<Object?> get props => [message];
}

// Category Cubit
class CategoryCubit extends Cubit<CategoryState> {
  final RestaurantService _restaurantService;
  CategoryCubit({
    RestaurantService? restaurantService,
  })  : _restaurantService = restaurantService ?? RestaurantService(),
        super(CategoryInitial());

  Future<void> loadCategories() async {
    try {
      emit(CategoryLoading());
      final categories = await _restaurantService.getStaticCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: 'errorCategoriesLoading|${e.toString()}'));
    }
  }

  void clearError() {
    if (state is CategoryError) {
      emit(CategoryInitial());
    }
  }

  void resetToInitial() {
    emit(CategoryInitial());
  }
}
