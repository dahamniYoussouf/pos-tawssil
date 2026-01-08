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
          print('items: ${items.length}');
          final favoriteFoods = items
              .where((item) => item.isFavorite)
              .map((item) => item.id)
              .toSet();
          if (categories.isEmpty && items.isNotEmpty) {
            final categoryData = _buildCategoryMaps(items);
            final builtCategories = categoryData.values.toList();
            if (!isClosed) {
              emit(RestaurantDetailsLoaded(
                menuItems: items,
                categories: builtCategories,
                selectedCategoryId: "all",
                favoriteFoods: favoriteFoods,
              ));
            }
          } else {
            _buildCategoryMapsFromCategories(categories);
            _buildCategoryMaps(items, clearMaps: false);
            if (!isClosed) {
              emit(RestaurantDetailsLoaded(
                menuItems: items,
                categories: categories,
                selectedCategoryId: "all",
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

  Map<String, MenuItemCategory> _buildCategoryMaps(List<MenuModel> items,
      {bool clearMaps = true}) {
    if (clearMaps) {
      _categoryIdMap.clear();
      _displayIdToKey.clear();
    }
    final Map<String, MenuItemCategory> displayMap = {};
    for (var item in items) {
      final cat = item.category;
      final cid =
          (item.categoryId.isNotEmpty ? item.categoryId : (cat?.id ?? ''))
              .toString();
      final name = item.categoryName.isNotEmpty
          ? item.categoryName
          : (cat?.nom ?? '').toString();
      final nameKey = name.isNotEmpty
          ? name.toLowerCase().trim()
          : (cid.isNotEmpty ? cid.toLowerCase().trim() : 'other');
      if (nameKey.isEmpty) continue;
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

  void selectCategory(String? categoryId) {
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
    if (currentState.selectedCategoryId == null ||
        currentState.selectedCategoryId == "all") {
      return currentState.menuItems
          .where((item) => !_isPromoItem(item))
          .toList();
    }
    final selectedId = currentState.selectedCategoryId!;
    final nameKey =
        _displayIdToKey[selectedId] ?? selectedId.toLowerCase().trim();
    final allowedIds = _categoryIdMap[nameKey] ?? <String>{};
    final selectedIdLower = selectedId.toLowerCase().trim();
    return currentState.menuItems.where((item) {
      if (_isPromoItem(item)) {
        return false;
      }
      final itemCategoryId = item.categoryId.toLowerCase().trim();
      final itemCatName = item.categoryName.isNotEmpty
          ? item.categoryName.toLowerCase().trim()
          : (item.category?.nom.toLowerCase().trim() ?? '');
      if (allowedIds.isNotEmpty) {
        if (allowedIds.contains(item.categoryId) ||
            allowedIds.contains(itemCategoryId)) {
          return true;
        }
      }
      if (itemCatName.isNotEmpty && itemCatName == nameKey) {
        return true;
      }
      if (item.categoryId.isNotEmpty) {
        if (itemCategoryId == selectedIdLower ||
            item.categoryId == selectedId) {
          return true;
        }
      }
      if (item.category != null) {
        final categoryId = item.category!.id.toLowerCase().trim();
        final categoryNom = item.category!.nom.toLowerCase().trim();
        if (categoryId == selectedIdLower ||
            categoryNom == nameKey ||
            (allowedIds.isNotEmpty &&
                (allowedIds.contains(item.category!.id) ||
                    allowedIds.contains(categoryId)))) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  Map<String, List<MenuModel>> getItemsGroupedByCategory() {
    if (state is! RestaurantDetailsLoaded) {
      return {};
    }
    final currentState = state as RestaurantDetailsLoaded;
    final Map<String, List<MenuModel>> grouped = {};
    for (final item in currentState.menuItems) {
      if (_isPromoItem(item)) {
        continue;
      }
      final categoryName = item.categoryName.isNotEmpty
          ? item.categoryName
          : (item.category?.nom ?? 'Other');
      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(item);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final catA = currentState.categories.firstWhere(
          (c) => c.nom == a,
          orElse: () => MenuItemCategory(id: '', nom: a, ordreAffichage: 999),
        );
        final catB = currentState.categories.firstWhere(
          (c) => c.nom == b,
          orElse: () => MenuItemCategory(id: '', nom: b, ordreAffichage: 999),
        );
        return catA.ordreAffichage.compareTo(catB.ordreAffichage);
      });
    final sortedGrouped = <String, List<MenuModel>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    return sortedGrouped;
  }

  List<MenuModel> getPromoItems() {
    if (state is! RestaurantDetailsLoaded) {
      return [];
    }
    final currentState = state as RestaurantDetailsLoaded;
    return currentState.menuItems.where((item) => _isPromoItem(item)).toList();
  }

  bool _isPromoItem(MenuModel item) {
    if (item.isOnPromotion) {
      return true;
    }
    final categoryName = item.categoryName.toLowerCase().trim();
    return categoryName == 'promo' ||
        categoryName == 'promotion' ||
        categoryName == 'promotions';
  }

  List<MenuItemCategory> getCategoriesWithoutPromo() {
    if (state is! RestaurantDetailsLoaded) {
      return [];
    }
    final currentState = state as RestaurantDetailsLoaded;
    return currentState.categories.where((category) {
      final categoryName = category.nom.toLowerCase().trim();
      return categoryName != 'promo' &&
          categoryName != 'promotion' &&
          categoryName != 'promotions';
    }).toList();
  }
}
