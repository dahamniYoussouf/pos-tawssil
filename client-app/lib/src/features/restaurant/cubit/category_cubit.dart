import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/restaurant_repository.dart';
import 'category_state.dart';

// Category Cubit
class CategoryCubit extends Cubit<CategoryState> {
  final RestaurantRepository _restaurantRepository;
  CategoryCubit({
    RestaurantRepository? restaurantRepository,
  })  : _restaurantRepository = restaurantRepository ?? RestaurantRepository(),
        super(CategoryInitial());

  Future<void> loadCategories() async {
    if (isClosed) return;
    try {
      emit(CategoryLoading());
      final categories = _restaurantRepository.getStaticCategories();
      if (!isClosed) {
        emit(CategoryLoaded(categories: categories));
      }
    } catch (e) {
      if (!isClosed) {
        emit(CategoryError(message: 'errorCategoriesLoading|${e.toString()}'));
      }
    }
  }

  void clearError() {
    if (!isClosed && state is CategoryError) {
      emit(CategoryInitial());
    }
  }

  void resetToInitial() {
    if (!isClosed) {
      emit(CategoryInitial());
    }
  }
}
