import 'dart:io';
import 'package:restaurant_app/src/core/services/base_api_service.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';

class MenuItemService extends BaseApiService {
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    return await uploadMultipartFile(
      '/api/upload',
      file: imageFile,
      fileFieldName: 'file',
    );
  }

  Future<Map<String, dynamic>> createMenuItem({
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required int preparationTime,
    String? ingredients,
    String? allergens,
    String? photoUrl,
    required bool isAvailable,
    List<MenuItemOptionGroup> optionGroups = const [],
  }) async {
    final data = {
      'category_id': categoryId,
      'nom': name,
      'description': description,
      'prix': price,
      'temps_preparation': preparationTime,
      'ingredients': ingredients,
      'allergenes': allergens,
      'photo_url': photoUrl,
      'disponible': isAvailable,
    };
    if (optionGroups.isNotEmpty) {
      data['option_groups'] =
          optionGroups.map((g) => g.toJson()).toList();
    }
    return await postRequest('/menuitem/create', data: data);
  }

  Future<Map<String, dynamic>> updateMenuItem({
    required String id,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required int preparationTime,
    String? ingredients,
    String? allergens,
    String? photoUrl,
    required bool isAvailable,
    List<MenuItemOptionGroup> optionGroups = const [],
  }) async {
    final data = {
      'category_id': categoryId,
      'nom': name,
      'description': description,
      'prix': price,
      'temps_preparation': preparationTime,
      'ingredients': ingredients,
      'allergenes': allergens,
      'photo_url': photoUrl,
      'is_available': isAvailable,
    };
    if (optionGroups.isNotEmpty) {
      data['option_groups'] =
          optionGroups.map((g) => g.toJson()).toList();
    }
    return await putRequest('/menuitem/update/$id', data: data);
  }

  Future<Map<String, dynamic>> deleteMenuItem(String id) async {
    return await deleteRequest('/menuitem/delete/$id');
  }
}
