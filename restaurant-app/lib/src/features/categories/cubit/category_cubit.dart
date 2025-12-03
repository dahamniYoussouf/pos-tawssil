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
    emit(CategoryLoading());
    final result = await _categoryRepository.createCategory(
      nom: nom,
      description: description,
      iconeUrl: iconeUrl,
      ordreAffichage: ordreAffichage,
    );
    result.fold(
      (error) => emit(CategoryError(message: error)),
      (_) {
        emit(const CategorySuccess(message: 'Category created successfully'));
        emit(CategoryInitial());
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
    emit(CategoryLoading());
    final result = await _categoryRepository.updateCategory(
      id: id,
      nom: nom,
      description: description,
      iconeUrl: iconeUrl,
      ordreAffichage: ordreAffichage,
    );
    result.fold(
      (error) => emit(CategoryError(message: error)),
      (_) {
        emit(const CategorySuccess(message: 'Category updated successfully'));
        emit(CategoryInitial());
      },
    );
  }

  Future<void> deleteCategory(String id) async {
    emit(CategoryLoading());
    final result = await _categoryRepository.deleteCategory(id);
    result.fold(
      (error) => emit(CategoryError(message: error)),
      (_) {
        emit(const CategorySuccess(message: 'Category deleted successfully'));
        emit(CategoryInitial());
      },
    );
  }
}
