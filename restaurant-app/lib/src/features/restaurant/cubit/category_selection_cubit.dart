import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/category_selection_state.dart';

class CategorySelectionCubit extends Cubit<CategorySelectionState> {
  CategorySelectionCubit() : super(const CategorySelectionInitial());

  void selectCategory(CategoryModel category) {
    final currentState = state;
    if (currentState is CategorySelectionInitial) {
      emit(currentState.copyWith(selectedCategory: category));
    }
  }

  void updateSearchQuery(String query) {
    final currentState = state;
    if (currentState is CategorySelectionInitial) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void clearSearch() {
    final currentState = state;
    if (currentState is CategorySelectionInitial) {
      emit(currentState.copyWith(searchQuery: ''));
    }
  }

  void initializeWithCategories(List<CategoryModel> categories) {
    if (categories.isNotEmpty) {
      final currentState = state;
      if (currentState is CategorySelectionInitial) {
        if (currentState.selectedCategory == null ||
            !categories.contains(currentState.selectedCategory)) {
          emit(currentState.copyWith(selectedCategory: categories[0]));
        }
      }
    }
  }
}
