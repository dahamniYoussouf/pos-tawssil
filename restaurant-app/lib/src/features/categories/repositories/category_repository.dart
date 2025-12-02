import 'package:restaurant_app/src/core/utils/either.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/categories/services/category_service.dart';

class CategoryRepository {
  final CategoryService _categoryService;

  CategoryRepository({CategoryService? categoryService})
      : _categoryService = categoryService ?? CategoryService();

  Future<Either<String, List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await _categoryService.fetchCategories();
      if (response['success'] == true) {
        final data = response['data'] ?? response['categories'] ?? [];
        if (data is List) {
          final categories = data
              .map((json) =>
                  CategoryModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return Right(categories);
        }
        return const Right([]);
      } else {
        return Left(response['message'] ?? 'Failed to fetch categories');
      }
    } catch (e) {
      return Left('Error fetching categories: ${e.toString()}');
    }
  }

  Future<Either<String, CategoryModel>> createCategory({
    required String nom,
    required String description,
    required String? iconeUrl,
    required int ordreAffichage,
  }) async {
    try {
      final response = await _categoryService.createCategory(
        nom: nom,
        description: description,
        iconeUrl: iconeUrl,
        ordreAffichage: ordreAffichage,
      );
      if (response['success'] == true) {
        final data = response['data'] ?? response;
        final category = CategoryModel.fromJson(data as Map<String, dynamic>);
        return Right(category);
      } else {
        return Left(response['message'] ?? 'Failed to create category');
      }
    } catch (e) {
      return Left('Error creating category: ${e.toString()}');
    }
  }

  Future<Either<String, CategoryModel>> updateCategory({
    required String id,
    required String nom,
    required String description,
    required String? iconeUrl,
    required int ordreAffichage,
  }) async {
    try {
      final response = await _categoryService.updateCategory(
        id: id,
        nom: nom,
        description: description,
        iconeUrl: iconeUrl,
        ordreAffichage: ordreAffichage,
      );
      if (response['success'] == true) {
        final data = response['data'] ?? response;
        final category = CategoryModel.fromJson(data as Map<String, dynamic>);
        return Right(category);
      } else {
        return Left(response['message'] ?? 'Failed to update category');
      }
    } catch (e) {
      return Left('Error updating category: ${e.toString()}');
    }
  }

  Future<Either<String, void>> deleteCategory(String id) async {
    try {
      final response = await _categoryService.deleteCategory(id);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to delete category');
      }
    } catch (e) {
      return Left('Error deleting category: ${e.toString()}');
    }
  }
}
