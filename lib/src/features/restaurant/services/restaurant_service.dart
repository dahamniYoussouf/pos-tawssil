import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/menu_model.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/base_api_service.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/utils/dependency_injection.dart';
import '../../auth/services/user_service.dart';

class RestaurantService extends BaseApiService {
  final UserService _userService = UserService();
  final TokenStorageService _tokenStorageService = locator<TokenStorageService>();

  /// Fetch menu items for a specific restaurant
  Future<List<MenuModel>> getRestaurantMenuItems(String restaurantId) async {
    try {
      final accessToken = await _tokenStorageService.getAccessToken();
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final response = await dio.get(
        '${ApiConfig.baseUrl}/menuitem/byrestaurant/$restaurantId',
      );
      final result = response.data is Map ? response.data : jsonDecode(response.data);
      if (response.statusCode == 200 && result['success'] == true && result.containsKey('data')) {
        final List<dynamic> itemsList = result['data'];
        return itemsList.map((json) => MenuModel.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Tries to read stored coordinates from SharedPreferences (via UserService)
  /// and fetch nearby restaurants. If no stored coordinates are available,
  /// falls back to fetching all restaurants.
  Future<List<RestaurantModel>> getNearbyRestaurantsFromStoredLocation({int radius = 2000}) async {
    try {
      final coords = await _userService.getCurrentCoordinates();
      if (coords != null) {
        return await getNearbyRestaurants(
          lat: coords['lat']!,
          lng: coords['lng']!,
          radius: radius,
        );
      }
      return await getRestaurants();
    } catch (_) {
      return [];
    }
  }

  Future<List<RestaurantModel>> getRestaurants() async {
    try {
      final accessToken = await _tokenStorageService.getAccessToken();
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final response = await dio.get(ApiConfig.restaurantsUrl);
      final result = response.data is Map ? response.data : jsonDecode(response.data);
      if (response.statusCode == 200 && result['success'] == true && result.containsKey('data')) {
        final List<dynamic> restaurantsList = result['data'];
        if (restaurantsList.isEmpty) {
          return [];
        }
        List<RestaurantModel> parsedRestaurants = [];
        for (int i = 0; i < restaurantsList.length; i++) {
          try {
            final restaurantData = restaurantsList[i] as Map<String, dynamic>;
            final restaurant = RestaurantModel.fromJson(restaurantData);
            parsedRestaurants.add(restaurant);
          } catch (e) {
            // Error parsing restaurant
          }
        }
        return parsedRestaurants;
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch nearby restaurants using coordinates.
  /// Calls POST ${ApiConfig.nearbyRestaurantsUrl} with coordinates in body ONLY
  Future<List<RestaurantModel>> getNearbyRestaurants({
    required double lat,
    required double lng,
    int radius = 5000,
    List<String>? categories,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final accessToken = await _tokenStorageService.getAccessToken();
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final Map<String, dynamic> body = {
        "lat": lat.toString(),
        "lng": lng.toString(),
        "radius": radius,
        "categories": categories ?? ["pizza", "burger", "tacos", "sandwish"],
        "page": page,
        "pageSize": pageSize
      };
      final response = await dio.post(
        'https://tawssilbackyou.onrender.com/restaurant/nearbyfilter',
        data: body,
      );
      final result = response.data is Map ? response.data : jsonDecode(response.data);
      if (response.statusCode == 200 && result.containsKey('data')) {
        final List<dynamic> restaurantsList = result['data'];
        if (restaurantsList.isEmpty) return [];
        return restaurantsList
            .map((e) {
              try {
                return RestaurantModel.fromJson(e as Map<String, dynamic>);
              } catch (e) {
                return null;
              }
            })
            .whereType<RestaurantModel>()
            .toList();
      }
      return [];
    } on DioException {
      return [];
    } on TimeoutException {
      return [];
    } catch (_) {
      return [];
    }
  }

  List<CategoryModel> getStaticCategories() {
    return [
      CategoryModel(id: 'pizza', name: 'Pizza', iconPath: 'assets/icons/pizza.png'),
      CategoryModel(id: 'burger', name: 'Burger', iconPath: 'assets/icons/burger.png'),
      CategoryModel(id: 'sushi', name: 'Sushi', iconPath: 'assets/icons/sushi.png'),
      CategoryModel(id: 'desserts', name: 'Desserts', iconPath: 'assets/icons/dessert.png'),
      CategoryModel(id: 'drinks', name: 'Drinks', iconPath: 'assets/icons/drink.png'),
    ];
  }

  Future<List<RestaurantModel>> searchRestaurants({required String query, int maxResults = 50}) async {
    try {
      final allRestaurants = await getRestaurants();
      if (query.isEmpty) {
        return allRestaurants.take(maxResults).toList();
      }
      final queryLower = query.toLowerCase();
      return allRestaurants
          .where((restaurant) {
            final nameLower = restaurant.name.toLowerCase();
            final descLower = restaurant.description.toLowerCase();
            return nameLower.contains(queryLower) || descLower.contains(queryLower);
          })
          .take(maxResults)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RestaurantModel>> getRestaurantsByCategory(List<String> categories, double lat, double lng, {int radius = 50000, int page = 1, int pageSize = 20}) async {
    try {
      final accessToken = await _tokenStorageService.getAccessToken();
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final response = await dio.post(
        'https://tawssilbackyou.onrender.com/restaurant/nearbyfilter',
        data: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius,
          'categories': categories,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final result = response.data is Map ? response.data : jsonDecode(response.data);
      if (response.statusCode == 200 && result['success'] == true && result.containsKey('data')) {
        final List<dynamic> restaurantsList = result['data'];
        if (restaurantsList.isEmpty) {
          return [];
        }
        List<RestaurantModel> parsedRestaurants = [];
        for (int i = 0; i < restaurantsList.length; i++) {
          try {
            final restaurantData = restaurantsList[i] as Map<String, dynamic>;
            final restaurant = RestaurantModel.fromJson(restaurantData);
            parsedRestaurants.add(restaurant);
          } catch (e) {
            // Error parsing restaurant
          }
        }
        parsedRestaurants.sort((a, b) {
          if (a.isPremium && !b.isPremium) return -1;
          if (!a.isPremium && b.isPremium) return 1;
          return b.rating.compareTo(a.rating);
        });
        return parsedRestaurants;
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<RestaurantModel> getRestaurantById(String id) async {
    try {
      final accessToken = await _tokenStorageService.getAccessToken();
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final response = await dio.get('${ApiConfig.baseUrl}/restaurant/$id');
      final result = response.data is Map ? response.data : jsonDecode(response.data);
      if (response.statusCode == 200 && result['success'] == true && result.containsKey('data')) {
        final restaurantData = result['data'] as Map<String, dynamic>;
        return RestaurantModel.fromJson(restaurantData);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException {
      throw Exception('Failed to load restaurant');
    } catch (_) {
      rethrow;
    }
  }

  Future<List<MenuModel>> getMenuItems({required String restaurantId, String? categoryId}) async {
    try {
      final accessToken = await _tokenStorageService.getAccessToken();
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final body = <String, dynamic>{
        'is_available': true,
        'restaurant_id': restaurantId,
      };
      if (categoryId != null) {
        body['category_id'] = categoryId;
      }
      final response = await dio.post(
        '${ApiConfig.baseUrl}/menuitem/filter',
        data: body,
      );
      final result = response.data is Map ? response.data : jsonDecode(response.data);
      if (response.statusCode == 200 && result['success'] == true) {
        final List<dynamic>? itemsList = (result['data'] as List?) ?? (result['items'] as List?);
        if (itemsList == null) {
          return [];
        }
        List<MenuModel> parsedItems = [];
        for (int i = 0; i < itemsList.length; i++) {
          try {
            final itemData = itemsList[i] as Map<String, dynamic>;
            final menuItem = MenuModel.fromJson(itemData);
            // If backend didn't populate restaurant_id, assume items belong to requested restaurant
            if (menuItem.restaurantId.isEmpty) {
              parsedItems.add(menuItem);
            } else if (menuItem.restaurantId == restaurantId) {
              parsedItems.add(menuItem);
            }
          } catch (e) {
            // Error parsing menu item
          }
        }
        return parsedItems;
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<MenuItemCategory>> getMenuCategories({required String restaurantId}) async {
    try {
      final menuItems = await getMenuItems(restaurantId: restaurantId);
      // Extract unique categories from menu items
      final Map<String, MenuItemCategory> categoriesMap = {};
      for (var item in menuItems) {
        if (item.category != null) {
          categoriesMap[item.category!.id] = item.category!;
        }
      }
      return categoriesMap.values.toList();
    } catch (e) {
      return [];
    }
  }
}
