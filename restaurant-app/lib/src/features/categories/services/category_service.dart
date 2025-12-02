import 'package:restaurant_app/src/core/services/base_api_service.dart';

class CategoryService extends BaseApiService {
  Future<Map<String, dynamic>> fetchCategories() async {
    return await getRequest('/foodcategory');
  }

  Future<Map<String, dynamic>> createCategory({
    required String nom,
    required String description,
    required String? iconeUrl,
    required int ordreAffichage,
  }) async {
    return await postRequest(
      '/foodcategory',
      data: {
        'nom': nom,
        'description': description,
        'ordre_affichage': ordreAffichage,
      },
    );
  }

  Future<Map<String, dynamic>> updateCategory({
    required String id,
    required String nom,
    required String description,
    required String? iconeUrl,
    required int ordreAffichage,
  }) async {
    return await putRequest(
      '/foodcategory/$id',
      data: {
        'nom': nom,
        'description': description,
        'ordre_affichage': ordreAffichage,
      },
    );
  }

  Future<Map<String, dynamic>> deleteCategory(String id) async {
    return await deleteRequest('/foodcategory/$id');
  }
}
