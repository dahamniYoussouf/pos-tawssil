import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';

abstract class CategorySelectionState extends Equatable {
  const CategorySelectionState();

  @override
  List<Object?> get props => [];
}

class CategorySelectionInitial extends CategorySelectionState {
  final CategoryModel? selectedCategory;
  final String searchQuery;

  const CategorySelectionInitial({
    this.selectedCategory,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [selectedCategory, searchQuery];

  CategorySelectionInitial copyWith({
    CategoryModel? selectedCategory,
    String? searchQuery,
  }) {
    return CategorySelectionInitial(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
