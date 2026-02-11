import 'dart:io';
import 'package:restaurant_app/src/core/utils/either.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/menu_items/services/menu_item_service.dart';

class MenuItemRepository {
  final MenuItemService _menuItemService;

  MenuItemRepository({MenuItemService? menuItemService})
      : _menuItemService = menuItemService ?? MenuItemService();

  Future<Either<String, String>> uploadImage(File imageFile) async {
    try {
      final response = await _menuItemService.uploadImage(imageFile);
      if (response['success'] == true) {
        final imageUrl = response['data']?['url'] ??
            response['url'] ??
            response['data']?.toString();
        if (imageUrl != null && imageUrl is String) {
          return Right(imageUrl);
        }
        return const Left('Failed to get image URL from response');
      } else {
        return Left(response['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      return Left('Error uploading image: ${e.toString()}');
    }
  }

  Future<Either<String, MenuItemModel>> createMenuItem({
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
    try {
      final response = await _menuItemService.createMenuItem(
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        preparationTime: preparationTime,
        ingredients: ingredients,
        allergens: allergens,
        photoUrl: photoUrl,
        isAvailable: isAvailable,
        optionGroups: optionGroups,
      );
      if (response['success'] == true) {
        final data = response['data'] ?? response;
        final menuItem = MenuItemModel.fromJson(data as Map<String, dynamic>);
        return Right(menuItem);
      } else {
        return Left(response['message'] ?? 'Failed to create menu item');
      }
    } catch (e) {
      return Left('Error creating menu item: ${e.toString()}');
    }
  }

  Future<Either<String, MenuItemModel>> updateMenuItem({
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
    try {
      final response = await _menuItemService.updateMenuItem(
        id: id,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        preparationTime: preparationTime,
        ingredients: ingredients,
        allergens: allergens,
        photoUrl: photoUrl,
        isAvailable: isAvailable,
        optionGroups: optionGroups,
      );
      if (response['success'] == true) {
        final data = response['data'] ?? response;
        final menuItem = MenuItemModel.fromJson(data as Map<String, dynamic>);
        return Right(menuItem);
      } else {
        return Left(response['message'] ?? 'Failed to update menu item');
      }
    } catch (e) {
      return Left('Error updating menu item: ${e.toString()}');
    }
  }

  Future<Either<String, void>> deleteMenuItem(String id) async {
    try {
      final response = await _menuItemService.deleteMenuItem(id);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to delete menu item');
      }
    } catch (e) {
      return Left('Error deleting menu item: ${e.toString()}');
    }
  }
}
