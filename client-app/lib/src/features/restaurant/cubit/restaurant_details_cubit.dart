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

  Future<void> loadMenuItems(String restaurantId) async {
    if (isClosed) return;
    emit(RestaurantDetailsLoading());

    try {
      final result = await _repository.getMenuItems(restaurantId: restaurantId);

      if (isClosed) return;

      result.fold(
        (error) {
          if (!isClosed) {
            emit(RestaurantDetailsError(message: error));
          }
        },
        (items) {
          // Build normalized map of categories
          _categoryIdMap.clear();
          _displayIdToKey.clear();

          final Map<String, MenuItemCategory> displayMap = {};

          for (var item in items) {
            final cat = item.category;
            final cid = (item.categoryId.isNotEmpty ? item.categoryId : (cat?.id ?? '')).toString();
            final name = (cat?.nom ?? '').toString();

            final nameKey = name.isNotEmpty ? name.toLowerCase().trim() : cid.toLowerCase().trim();

            // Add underlying id to set
            _categoryIdMap.putIfAbsent(nameKey, () => <String>{});
            if (cid.isNotEmpty) _categoryIdMap[nameKey]!.add(cid);

            // Build display category entry (first encountered)
            if (!displayMap.containsKey(nameKey)) {
              final displayId = cid.isNotEmpty ? cid : nameKey;
              final displayName = name.isNotEmpty ? name : nameKey;
              displayMap[nameKey] = MenuItemCategory(id: displayId, nom: displayName);
              _displayIdToKey[displayId] = nameKey;
            } else {
              // ensure mapping exists for this cid as well (if different id)
              final existing = displayMap[nameKey]!;
              final existingId = existing.id;
              // Map the current cid to the same nameKey so filtering works
              if (cid.isNotEmpty) _displayIdToKey[cid] = nameKey;
              _displayIdToKey[existingId] = nameKey;
            }
          }

          final categories = displayMap.values.toList();
          final selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;

          if (!isClosed) {
            emit(RestaurantDetailsLoaded(
              menuItems: items,
              categories: categories,
              selectedCategoryId: selectedCategoryId,
            ));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(RestaurantDetailsError(
          message: 'Failed to load menu items. Please try again.',
        ));
      }
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
}

