import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/restaurant_repository.dart';
import '../models/menu_model.dart';
import 'restaurant_details_state.dart';

class RestaurantDetailsCubit extends Cubit<RestaurantDetailsState> {
  final RestaurantRepository _repository;

  // Maps for category normalization
  final Map<String, Set<String>> _categoryIdMap = {};
  final Map<String, String> _displayIdToKey = {};

  RestaurantDetailsCubit({
    RestaurantRepository? repository,
  })  : _repository = repository ?? RestaurantRepository(),
        super(RestaurantDetailsInitial());

  Map<String, Set<String>> get categoryIdMap => _categoryIdMap;
  Map<String, String> get displayIdToKey => _displayIdToKey;

  Future<void> loadRestaurantDetails(String restaurantId) async {
    if (isClosed) return;
    emit(RestaurantDetailsLoading());
    try {
      final result =
          await _repository.getRestaurantDetailsWithCategories(restaurantId);
      if (isClosed) return;
      result.fold(
        (error) {
          if (!isClosed) {
            emit(RestaurantDetailsError(message: error));
          }
        },
        (data) {
          final categories = data.categories;
          final items = data.menuItems;
          final favoriteFoods = items
              .where((item) => item.isFavorite)
              .map((item) => item.id)
              .toSet();
          if (categories.isEmpty && items.isNotEmpty) {
            final categoryData = _buildCategoryMaps(items);
            final builtCategories = categoryData.values.toList();
            final selectedCategoryId =
                builtCategories.isNotEmpty ? builtCategories.first.id : null;
            if (!isClosed) {
              emit(RestaurantDetailsLoaded(
                menuItems: items,
                categories: builtCategories,
                selectedCategoryId: selectedCategoryId,
                favoriteFoods: favoriteFoods,
              ));
            }
          } else {
            _buildCategoryMapsFromCategories(categories);
            _buildCategoryMaps(items);
            final selectedCategoryId =
                categories.isNotEmpty ? categories.first.id : null;
            if (!isClosed) {
              emit(RestaurantDetailsLoaded(
                menuItems: items,
                categories: categories,
                selectedCategoryId: selectedCategoryId,
                favoriteFoods: favoriteFoods,
              ));
            }
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(RestaurantDetailsError(
          message: 'Failed to load restaurant details. Please try again.',
        ));
      }
    }
  }

  Map<String, MenuItemCategory> _buildCategoryMaps(List<MenuModel> items) {
    _categoryIdMap.clear();
    _displayIdToKey.clear();
    final Map<String, MenuItemCategory> displayMap = {};
    for (var item in items) {
      final cat = item.category;
      final cid =
          (item.categoryId.isNotEmpty ? item.categoryId : (cat?.id ?? ''))
              .toString();
      final name = (cat?.nom ?? '').toString();
      final nameKey = name.isNotEmpty
          ? name.toLowerCase().trim()
          : cid.toLowerCase().trim();
      _categoryIdMap.putIfAbsent(nameKey, () => <String>{});
      if (cid.isNotEmpty) _categoryIdMap[nameKey]!.add(cid);
      if (!displayMap.containsKey(nameKey)) {
        final displayId = cid.isNotEmpty ? cid : nameKey;
        final displayName = name.isNotEmpty ? name : nameKey;
        displayMap[nameKey] = MenuItemCategory(
          id: displayId,
          nom: displayName,
        );
        _displayIdToKey[displayId] = nameKey;
      } else {
        final existing = displayMap[nameKey]!;
        final existingId = existing.id;
        if (cid.isNotEmpty) _displayIdToKey[cid] = nameKey;
        _displayIdToKey[existingId] = nameKey;
      }
    }
    return displayMap;
  }

  void _buildCategoryMapsFromCategories(List<MenuItemCategory> categories) {
    _categoryIdMap.clear();
    _displayIdToKey.clear();
    for (var category in categories) {
      final nameKey = category.nom.toLowerCase().trim();
      _categoryIdMap.putIfAbsent(nameKey, () => <String>{});
      _categoryIdMap[nameKey]!.add(category.id);
      _displayIdToKey[category.id] = nameKey;
    }
  }

  void selectCategory(String categoryId) {
    if (state is RestaurantDetailsLoaded) {
      final currentState = state as RestaurantDetailsLoaded;
      emit(currentState.copyWith(selectedCategoryId: categoryId));
    }
  }

  void toggleFavorite(String foodId) {
    if (state is RestaurantDetailsLoaded) {
      final currentState = state as RestaurantDetailsLoaded;
      final newFavorites = Set<String>.from(currentState.favoriteFoods);
      if (newFavorites.contains(foodId)) {
        newFavorites.remove(foodId);
      } else {
        newFavorites.add(foodId);
      }
      emit(currentState.copyWith(favoriteFoods: newFavorites));
    }
  }

  void setSelectedItemId(String? itemId) {
    if (state is RestaurantDetailsLoaded) {
      final currentState = state as RestaurantDetailsLoaded;
      emit(currentState.copyWith(
        selectedItemId: itemId,
        clearSelectedItemId: itemId == null,
      ));
    }
  }

  void clearError() {
    if (!isClosed && state is RestaurantDetailsError) {
      emit(RestaurantDetailsInitial());
    }
  }

  List<MenuModel> getFilteredItems() {
    if (state is! RestaurantDetailsLoaded) {
      return [];
    }
    final currentState = state as RestaurantDetailsLoaded;
    if (currentState.selectedCategoryId == null) {
      return currentState.menuItems;
    }
    return currentState.menuItems.where((item) {
      final selectedId = currentState.selectedCategoryId!;
      final nameKey =
          _displayIdToKey[selectedId] ?? selectedId.toLowerCase().trim();
      final allowedIds = _categoryIdMap[nameKey] ?? <String>{};
      if (allowedIds.contains(item.categoryId)) return true;
      final itemCatName = item.category?.nom.toLowerCase().trim() ?? '';
      if (itemCatName.isNotEmpty && itemCatName == nameKey) return true;
      if (item.categoryId.isEmpty && selectedId.toLowerCase().trim() == nameKey)
        return true;
      return false;
    }).toList();
  }
}
