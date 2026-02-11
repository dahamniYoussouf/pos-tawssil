import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_state.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/menu_items/repositories/menu_item_repository.dart';

class MenuItemCubit extends Cubit<MenuItemState> {
  final MenuItemRepository _menuItemRepository;

  MenuItemCubit({MenuItemRepository? menuItemRepository})
      : _menuItemRepository =
            menuItemRepository ?? locator<MenuItemRepository>(),
        super(MenuItemInitial());

  Future<void> uploadImage(File imageFile) async {
    emit(MenuItemImageUploading());
    final result = await _menuItemRepository.uploadImage(imageFile);
    result.fold(
      (error) => emit(MenuItemImageUploadError(message: error)),
      (imageUrl) => emit(MenuItemImageUploadSuccess(imageUrl: imageUrl)),
    );
  }

  Future<void> createMenuItem({
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
    emit(MenuItemActionLoading());
    final result = await _menuItemRepository.createMenuItem(
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
    result.fold(
      (error) => emit(MenuItemActionError(message: error)),
      (menuItem) => emit(MenuItemActionSuccess(
        menuItem: menuItem,
        message: 'Menu item created successfully',
      )),
    );
  }

  Future<void> updateMenuItem({
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
    emit(MenuItemActionLoading());
    final result = await _menuItemRepository.updateMenuItem(
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
    result.fold(
      (error) => emit(MenuItemActionError(message: error)),
      (menuItem) => emit(MenuItemActionSuccess(
        menuItem: menuItem,
        message: 'Menu item updated successfully',
      )),
    );
  }

  Future<void> deleteMenuItem(String id) async {
    emit(MenuItemActionLoading());
    final result = await _menuItemRepository.deleteMenuItem(id);
    result.fold(
      (error) => emit(MenuItemActionError(message: error)),
      (_) => emit(MenuItemActionSuccess(
        menuItem: MenuItemModel(id: id, name: '', price: 0.0),
        message: 'Menu item deleted successfully',
      )),
    );
  }

  void reset() {
    emit(MenuItemInitial());
  }
}
