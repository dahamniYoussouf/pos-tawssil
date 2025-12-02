import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_state.dart';
import 'package:restaurant_app/src/features/categories/repositories/category_repository.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _categoryRepository;

  CategoryCubit({CategoryRepository? categoryRepository})
      : _categoryRepository =
            categoryRepository ?? locator<CategoryRepository>(),
        super(CategoryInitial());

  Future<void> createCategory({
    required String nom,
    required String description,
    required String? iconeUrl,
    required int ordreAffichage,
  }) async {
    if (state is CategoryLoaded) {
      final currentState = state as CategoryLoaded;
      emit(CategoryActionLoading(categories: currentState.categories));
    } else {
      emit(CategoryLoading());
    }
    final result = await _categoryRepository.createCategory(
      nom: nom,
      description: description,
      iconeUrl: iconeUrl,
      ordreAffichage: ordreAffichage,
    );
    result.fold(
      (error) {
        if (state is CategoryActionLoading) {
          final currentState = state as CategoryActionLoading;
          emit(CategoryActionError(
            categories: currentState.categories,
            message: error,
          ));
        } else {
          emit(CategoryError(message: error));
        }
      },
      (category) {
        if (state is CategoryActionLoading) {
          final currentState = state as CategoryActionLoading;
          final updatedCategories = [...currentState.categories, category];
          emit(CategoryActionSuccess(
            categories: updatedCategories,
            message: 'Category created successfully',
          ));
          emit(CategoryLoaded(categories: updatedCategories));
        } else {
          emit(CategoryActionSuccess(
            categories: [category],
            message: 'Category created successfully',
          ));
          emit(CategoryLoaded(categories: [category]));
        }
      },
    );
  }

  Future<void> updateCategory({
    required String id,
    required String nom,
    required String description,
    required String? iconeUrl,
    required int ordreAffichage,
  }) async {
    if (state is! CategoryLoaded) {
      emit(CategoryError(
        message: 'Cannot update category: categories not loaded',
      ));
      return;
    }
    final currentState = state as CategoryLoaded;
    emit(CategoryActionLoading(categories: currentState.categories));
    final result = await _categoryRepository.updateCategory(
      id: id,
      nom: nom,
      description: description,
      iconeUrl: iconeUrl,
      ordreAffichage: ordreAffichage,
    );
    result.fold(
      (error) => emit(CategoryActionError(
        categories: currentState.categories,
        message: error,
      )),
      (updatedCategory) {
        final updatedCategories = currentState.categories.map((cat) {
          return cat.id == id ? updatedCategory : cat;
        }).toList();
        emit(CategoryActionSuccess(
          categories: updatedCategories,
          message: 'Category updated successfully',
        ));
        emit(CategoryLoaded(categories: updatedCategories));
      },
    );
  }

  Future<void> deleteCategory(String id) async {
    if (state is! CategoryLoaded) return;
    final currentState = state as CategoryLoaded;
    emit(CategoryActionLoading(categories: currentState.categories));
    final result = await _categoryRepository.deleteCategory(id);
    result.fold(
      (error) => emit(CategoryActionError(
        categories: currentState.categories,
        message: error,
      )),
      (_) {
        final updatedCategories =
            currentState.categories.where((cat) => cat.id != id).toList();
        emit(CategoryActionSuccess(
          categories: updatedCategories,
          message: 'Category deleted successfully',
        ));
        emit(CategoryLoaded(categories: updatedCategories));
      },
    );
  }
}
