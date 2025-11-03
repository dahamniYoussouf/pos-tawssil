/// Fetch categories for a specific restaurant
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/menu_model.dart';
import '../../../core/config/api_config.dart';
import '../../auth/services/user_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}

Future<List<CategoryModel>> getRestaurantCategories(String restaurantId) async {
  final accessToken = await getAccessToken();
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/restaurantcategory/byrestaurant/$restaurantId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    ).timeout(Duration(seconds: 15));

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);
      if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData.containsKey('data')) {
        final List<dynamic> categoriesList = responseData['data'];
        return categoriesList.map((json) => CategoryModel.fromJson(json)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
}

/// Fetch menu items for a specific restaurant
Future<List<MenuModel>> getRestaurantMenuItems(String restaurantId) async {
  final accessToken = await getAccessToken();
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/menuitem/byrestaurant/$restaurantId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    ).timeout(Duration(seconds: 15));

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);
      if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData.containsKey('data')) {
        final List<dynamic> itemsList = responseData['data'];
        return itemsList.map((json) => MenuModel.fromJson(json)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
}

class RestaurantService {
  /// Fetch categories for a specific restaurant
  Future<List<CategoryModel>> getRestaurantCategories(String restaurantId) async {
    final accessToken = await getAccessToken();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/restaurantcategory/byrestaurant/$restaurantId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData.containsKey('data')) {
          final List<dynamic> categoriesList = responseData['data'];
          return categoriesList.map((json) => CategoryModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch menu items for a specific restaurant
  Future<List<MenuModel>> getRestaurantMenuItems(String restaurantId) async {
    final accessToken = await getAccessToken();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/menuitem/byrestaurant/$restaurantId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData.containsKey('data')) {
          final List<dynamic> itemsList = responseData['data'];
          return itemsList.map((json) => MenuModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  final UserService _userService = UserService();

  /// Tries to read stored coordinates from SharedPreferences (via UserService)
  /// and fetch nearby restaurants. If no stored coordinates are available,
  /// falls back to fetching all restaurants.
  Future<List<RestaurantModel>> getNearbyRestaurantsFromStoredLocation({int radius = 2000}) async {
    final accessToken = await getAccessToken();
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
    } catch (e, st) {
      return [];
    }
  }

  Future<List<RestaurantModel>> getRestaurants() async {
    final accessToken = await getAccessToken();
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.restaurantsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true && responseData.containsKey('data')) {
            final List<dynamic> restaurantsList = responseData['data'];

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
          } else {
            return [];
          }
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e, stackTrace) {
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
    final accessToken = await getAccessToken();
    try {
      final uri = Uri.parse('https://tawssilbackyou.onrender.com/restaurant/nearbyfilter');

      final Map<String, dynamic> body = {
        "lat": lat.toString(),
        "lng": lng.toString(),
        "radius": radius,
        "categories": categories ?? ["pizza", "burger", "tacos", "sandwish"],
        "page": page,
        "pageSize": pageSize
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final List<dynamic> restaurantsList = responseData['data'];
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
        } else {
          return [];
        }
      } else {
        return [];
      }
    } on TimeoutException {
      return [];
    } catch (e, stackTrace) {
      return [];
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    final accessToken = await getAccessToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/restaurant/getall'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true && responseData.containsKey('data')) {
            final List<dynamic> categoriesList = responseData['data'];

            if (categoriesList.isEmpty) {
              return _getStaticCategories();
            }

            List<CategoryModel> parsedCategories = [];

            for (int i = 0; i < categoriesList.length; i++) {
              try {
                final categoryData = categoriesList[i] as Map<String, dynamic>;
                final category = CategoryModel(
                  id: categoryData['id'] ?? '',
                  name: categoryData['nom'] ?? categoryData['name'] ?? '',
                  iconPath: categoryData['icone_url'] ?? 'assets/icons/restaurant.png',
                  description: categoryData['description'] ?? '',
                );
                parsedCategories.add(category);
              } catch (e) {
                // Error parsing category
              }
            }
            return parsedCategories;
          } else {
            return _getStaticCategories();
          }
        } else {
          return _getStaticCategories();
        }
      } else {
        return _getStaticCategories();
      }
    } catch (e, stackTrace) {
      return _getStaticCategories();
    }
  }

  List<CategoryModel> _getStaticCategories() {
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
    final accessToken = await getAccessToken();
    try {
      final response = await http
          .post(
            Uri.parse('https://tawssilbackyou.onrender.com/restaurant/nearbyfilter'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: json.encode({
              'lat': lat.toString(),
              'lng': lng.toString(),
              'radius': radius,
              'categories': categories,
              'page': page,
              'pageSize': pageSize,
            }),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true && responseData.containsKey('data')) {
            final List<dynamic> restaurantsList = responseData['data'];

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
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<RestaurantModel> getRestaurantById(String id) async {
    final accessToken = await getAccessToken();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/restaurant/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData.containsKey('data')) {
          final restaurantData = responseData['data'] as Map<String, dynamic>;
          return RestaurantModel.fromJson(restaurantData);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load restaurant');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MenuModel>> getMenuItems({required String restaurantId, String? categoryId}) async {
    final accessToken = await getAccessToken();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/menuitem/filter');
      final body = <String, dynamic>{
        'is_available': true,
      };
      body['restaurant_id'] = restaurantId;
      if (categoryId != null) {
        body['category_id'] = categoryId;
      }
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: json.encode(body),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> && responseData['success'] == true) {
          final List<dynamic>? itemsList = (responseData['data'] as List?) ?? (responseData['items'] as List?);
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
      }

      return [];
    } catch (e, st) {
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
