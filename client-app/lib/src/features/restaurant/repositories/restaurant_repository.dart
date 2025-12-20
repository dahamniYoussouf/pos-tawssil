import '../../../core/utils/either.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/menu_model.dart';
import '../services/restaurant_service.dart';

class RestaurantDetailsResult {
  final List<MenuModel> menuItems;
  final List<MenuItemCategory> categories;

  RestaurantDetailsResult({
    required this.menuItems,
    required this.categories,
  });
}

class RestaurantRepository {
  final RestaurantService _restaurantService;

  RestaurantRepository({RestaurantService? restaurantService})
      : _restaurantService = restaurantService ?? RestaurantService();

  /// Fetch nearby restaurants with optional filters
  Future<Either<String, List<RestaurantModel>>> getNearbyRestaurants({
    String? address,
    double? lat,
    double? lng,
    int radius = 5000,
    String? q,
    List<String>? categories,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _restaurantService.getNearbyRestaurants(
        address: address,
        lat: lat,
        lng: lng,
        radius: radius,
        q: q,
        categories: categories,
        page: page,
        pageSize: pageSize,
      );

      if (response['success'] == true || response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          if (data.isEmpty) {
            return const Right([]);
          }

          final restaurants = data
              .map((e) {
                try {
                  if (e is Map<String, dynamic>) {
                    return RestaurantModel.fromJson(e);
                  }
                  return null;
                } catch (e) {
                  return null;
                }
              })
              .whereType<RestaurantModel>()
              .toList();

          return Right(restaurants);
        }
        return const Left('Invalid response format: data is not a list');
      }

      return Left(
          response['message']?.toString() ?? 'Failed to fetch restaurants');
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get restaurant by ID
  Future<Either<String, RestaurantModel>> getRestaurantById(String id) async {
    try {
      final response = await _restaurantService.getRestaurantById(id);

      if (response['success'] == true && response.containsKey('data')) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          try {
            final restaurant = RestaurantModel.fromJson(data);
            return Right(restaurant);
          } catch (e) {
            return Left('Failed to parse restaurant data: ${e.toString()}');
          }
        }
        return const Left('Invalid response format: data is not a map');
      }

      return Left(
          response['message']?.toString() ?? 'Failed to fetch restaurant');
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get menu items for a restaurant
  Future<Either<String, List<MenuModel>>> getMenuItems({
    required String restaurantId,
    String? categoryId,
  }) async {
    try {
      final response = await _restaurantService.getMenuItems(
        restaurantId: restaurantId,
        categoryId: categoryId,
      );

      if (response['success'] == true) {
        final data = response['data'] ?? response['items'];
        if (data is List) {
          final List<MenuModel> parsedItems = [];

          for (final item in data) {
            try {
              if (item is Map<String, dynamic>) {
                final menuItem = MenuModel.fromJson(item);
                // If backend didn't populate restaurant_id, assume items belong to requested restaurant
                if (menuItem.restaurantId.isEmpty ||
                    menuItem.restaurantId == restaurantId) {
                  parsedItems.add(menuItem);
                }
              }
            } catch (e) {
              // Skip items that fail to parse
              continue;
            }
          }

          return Right(parsedItems);
        }
        return const Right([]);
      }

      return Left(
          response['message']?.toString() ?? 'Failed to fetch menu items');
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get menu items for a restaurant (legacy method name)
  Future<Either<String, List<MenuModel>>> getRestaurantMenuItems(
      String restaurantId) async {
    try {
      final response =
          await _restaurantService.getRestaurantMenuItems(restaurantId);

      if (response['success'] == true && response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          final items = data
              .map((json) {
                try {
                  if (json is Map<String, dynamic>) {
                    return MenuModel.fromJson(json);
                  }
                  return null;
                } catch (e) {
                  return null;
                }
              })
              .whereType<MenuModel>()
              .toList();

          return Right(items);
        }
        return const Right([]);
      }

      return Left(
          response['message']?.toString() ?? 'Failed to fetch menu items');
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get menu categories for a restaurant by extracting from menu items
  Future<Either<String, List<MenuItemCategory>>> getMenuCategories({
    required String restaurantId,
  }) async {
    try {
      final menuItemsResult = await getMenuItems(restaurantId: restaurantId);

      return menuItemsResult.fold(
        (error) => Left(error),
        (menuItems) {
          // Extract unique categories from menu items
          final Map<String, MenuItemCategory> categoriesMap = {};
          for (var item in menuItems) {
            if (item.category != null) {
              categoriesMap[item.category!.id] = item.category!;
            }
          }
          return Right(categoriesMap.values.toList());
        },
      );
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get restaurant details with menu items using restaurant/details endpoint
  Future<Either<String, List<MenuModel>>> getRestaurantDetailsWithMenu(
      String restaurantId) async {
    try {
      final result = await getRestaurantDetailsWithCategories(restaurantId);
      return result.fold(
        (error) => Left(error),
        (data) => Right(data.menuItems),
      );
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get restaurant details with menu items and categories using restaurant/details endpoint
  Future<Either<String, RestaurantDetailsResult>>
      getRestaurantDetailsWithCategories(String restaurantId) async {
    try {
      final response =
          await _restaurantService.getMenuItemsByRestaurantId(restaurantId);
      if (response['success'] == true || response.containsKey('data')) {
        final data = response['data'] ?? response;
        final List<MenuModel> parsedItems = [];
        final List<MenuItemCategory> parsedCategories = [];
        if (data is Map<String, dynamic>) {
          final categories = data['categories'] as List<dynamic>?;
          if (categories != null && categories.isNotEmpty) {
            for (final categoryJson in categories) {
              if (categoryJson is Map<String, dynamic>) {
                try {
                  final category = MenuItemCategory.fromJson(categoryJson);
                  parsedCategories.add(category);
                  final categoryId = category.id;
                  final items = categoryJson['items'] as List<dynamic>? ?? [];
                  for (final itemJson in items) {
                    try {
                      if (itemJson is Map<String, dynamic>) {
                        final itemWithCategory =
                            Map<String, dynamic>.from(itemJson);
                        itemWithCategory['category_id'] = categoryId;
                        itemWithCategory['restaurant_id'] = restaurantId;
                        itemWithCategory['category'] = {
                          'id': category.id,
                          'nom': category.nom,
                        };
                        final menuItem = MenuModel.fromJson(itemWithCategory);
                        parsedItems.add(menuItem);
                      }
                    } catch (e) {
                      continue;
                    }
                  }
                } catch (e) {
                  continue;
                }
              }
            }
            parsedCategories
                .sort((a, b) => a.ordreAffichage.compareTo(b.ordreAffichage));
          } else {
            final menuItemsData = data['menu_items'] ??
                data['menuItems'] ??
                data['items'] ??
                (data['menu'] is List ? data['menu'] : null);
            if (menuItemsData != null && menuItemsData.isNotEmpty) {
              for (final item in menuItemsData) {
                try {
                  if (item is Map<String, dynamic>) {
                    final itemWithRestaurant = Map<String, dynamic>.from(item);
                    itemWithRestaurant['restaurant_id'] = restaurantId;
                    final menuItem = MenuModel.fromJson(itemWithRestaurant);
                    parsedItems.add(menuItem);
                  }
                } catch (e) {
                  continue;
                }
              }
            }
          }
        } else if (data is List) {
          for (final item in data) {
            try {
              if (item is Map<String, dynamic>) {
                final itemWithRestaurant = Map<String, dynamic>.from(item);
                itemWithRestaurant['restaurant_id'] = restaurantId;
                final menuItem = MenuModel.fromJson(itemWithRestaurant);
                parsedItems.add(menuItem);
              }
            } catch (e) {
              continue;
            }
          }
        }
        return Right(RestaurantDetailsResult(
          menuItems: parsedItems,
          categories: parsedCategories,
        ));
      }
      return Left(response['message']?.toString() ??
          'Failed to fetch restaurant details');
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get static categories (UI-only, not from API)
  List<CategoryModel> getStaticCategories() {
    return _restaurantService.getStaticCategories();
  }
}
