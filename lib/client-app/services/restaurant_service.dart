/// Fetch categories for a specific restaurant
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../../config/api_config.dart';
import 'user_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}

Future<List<Category>> getRestaurantCategories(String restaurantId) async {
  final accessToken = await getAccessToken();
  try {
    final response = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/restaurantcategory/byrestaurant/$restaurantId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    ).timeout(Duration(seconds: 15));

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);
      if (responseData is Map<String, dynamic> &&
          responseData['success'] == true &&
          responseData.containsKey('data')) {
        final List<dynamic> categoriesList = responseData['data'];
        return categoriesList.map((json) => Category.fromJson(json)).toList();
      }
    }
    return [];
  } catch (e) {
    print('❌ Exception fetching restaurant categories: $e');
    return [];
  }
}

/// Fetch menu items for a specific restaurant
Future<List<MenuItem>> getRestaurantMenuItems(String restaurantId) async {
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
      if (responseData is Map<String, dynamic> &&
          responseData['success'] == true &&
          responseData.containsKey('data')) {
        final List<dynamic> itemsList = responseData['data'];
        return itemsList.map((json) => MenuItem.fromJson(json)).toList();
      }
    }
    return [];
  } catch (e) {
    print('❌ Exception fetching restaurant menu items: $e');
    return [];
  }
}

class RestaurantService {
  /// Fetch categories for a specific restaurant
  Future<List<Category>> getRestaurantCategories(String restaurantId) async {
    final accessToken = await getAccessToken();
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/restaurantcategory/byrestaurant/$restaurantId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData.containsKey('data')) {
          final List<dynamic> categoriesList = responseData['data'];
          return categoriesList.map((json) => Category.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Exception fetching restaurant categories: $e');
      return [];
    }
  }

  /// Fetch menu items for a specific restaurant
  Future<List<MenuItem>> getRestaurantMenuItems(String restaurantId) async {
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
        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData.containsKey('data')) {
          final List<dynamic> itemsList = responseData['data'];
          return itemsList.map((json) => MenuItem.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Exception fetching restaurant menu items: $e');
      return [];
    }
  }

  final UserService _userService = UserService();

  /// Tries to read stored coordinates from SharedPreferences (via UserService)
  /// and fetch nearby restaurants. If no stored coordinates are available,
  /// falls back to fetching all restaurants.
  Future<List<Restaurant>> getNearbyRestaurantsFromStoredLocation(
      {int radius = 2000}) async {
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
      print('⚠️ No stored coordinates found, falling back to getRestaurants()');
      return await getRestaurants();
    } catch (e, st) {
      print('❌ Exception in getNearbyRestaurantsFromStoredLocation: $e');
      print(st);
      return [];
    }
  }

  Future<List<Restaurant>> getRestaurants() async {
    final accessToken = await getAccessToken();
    try {
      print('📄 Fetching restaurants from: ${ApiConfig.restaurantsUrl}');
      final response = await http.get(
        Uri.parse(ApiConfig.restaurantsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData.containsKey('data')) {
            final List<dynamic> restaurantsList = responseData['data'];
            print('✅ Found ${restaurantsList.length} restaurants');

            if (restaurantsList.isEmpty) {
              print('⚠️ No restaurants in response');
              return [];
            }

            List<Restaurant> parsedRestaurants = [];

            for (int i = 0; i < restaurantsList.length; i++) {
              try {
                final restaurantData =
                    restaurantsList[i] as Map<String, dynamic>;
                final restaurant = Restaurant.fromJson(restaurantData);
                parsedRestaurants.add(restaurant);
                print('✓ Parsed: ${restaurant.name}');
              } catch (e) {
                print('❌ Error parsing restaurant $i: $e');
                print('   Data: ${restaurantsList[i]}');
              }
            }

            print(
                '✅ Successfully loaded ${parsedRestaurants.length} restaurants');
            return parsedRestaurants;
          } else {
            print('⚠️ Response format invalid or success=false');
            print('   Response: $responseData');
            return [];
          }
        } else {
          print('⚠️ Response is not a Map');
          return [];
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}');
        print('   Body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Exception fetching restaurants: $e');
      print('   Stack: $stackTrace');
      return [];
    }
  }

  /// Fetch nearby restaurants using coordinates.
  /// Calls POST ${ApiConfig.nearbyRestaurantsUrl} with coordinates in body ONLY
  Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lng,
    int radius = 5000,
    List<String>? categories,
    int page = 1,
    int pageSize = 20,
  }) async {
    final accessToken = await getAccessToken();
    try {
      final uri = Uri.parse(
          'https://tawssilbackyou.onrender.com/restaurant/nearbyfilter');
      print('📄 POSTing to nearby restaurants endpoint: $uri');

      final Map<String, dynamic> body = {
        "lat": lat.toString(),
        "lng": lng.toString(),
        "radius": radius,
        "categories": categories ?? ["pizza", "burger", "tacos", "sandwish"],
        "page": page,
        "pageSize": pageSize
      };

      print('📦 Request body of the nearby restaurants: $body');

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

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final List<dynamic> restaurantsList = responseData['data'];
          if (restaurantsList.isEmpty) return [];

          return restaurantsList
              .map((e) {
                try {
                  return Restaurant.fromJson(e as Map<String, dynamic>);
                } catch (e) {
                  print('❌ Error parsing restaurant: $e');
                  return null;
                }
              })
              .whereType<Restaurant>()
              .toList();
        } else {
          print('⚠️ Invalid response structure: $responseData');
          return [];
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}');
        print('   Body: ${response.body}');
        return [];
      }
    } on TimeoutException {
      print('⏰ Request timed out');
      return [];
    } catch (e, stackTrace) {
      print('❌ Exception fetching nearby restaurants: $e');
      print('   Stack: $stackTrace');
      return [];
    }
  }

  Future<List<Category>> getCategories() async {
    final accessToken = await getAccessToken();
    try {
      print(
          '📄 Fetching categories from: ${ApiConfig.baseUrl}/restaurant/getall');

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

      print('📡 Categories response status: ${response.statusCode}');
      print('📦 Categories response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData.containsKey('data')) {
            final List<dynamic> categoriesList = responseData['data'];
            print('✅ Found ${categoriesList.length} categories');

            if (categoriesList.isEmpty) {
              print(
                  '⚠️ No categories in response, falling back to static categories');
              return _getStaticCategories();
            }

            List<Category> parsedCategories = [];

            for (int i = 0; i < categoriesList.length; i++) {
              try {
                final categoryData = categoriesList[i] as Map<String, dynamic>;
                final category = Category(
                  id: categoryData['id'] ?? '',
                  name: categoryData['nom'] ?? categoryData['name'] ?? '',
                  iconPath: categoryData['icone_url'] ??
                      'assets/icons/restaurant.png',
                  description: categoryData['description'] ?? '',
                );
                parsedCategories.add(category);
                print('✓ Parsed: ${category.name}');
              } catch (e) {
                print('❌ Error parsing category $i: $e');
                print('   Data: ${categoriesList[i]}');
              }
            }
            print(
                '✅ Successfully loaded ${parsedCategories.length} categories');
            return parsedCategories;
          } else {
            print('⚠️ Response format invalid or success=false');
            print('   Response: $responseData');
            return _getStaticCategories();
          }
        } else {
          print('⚠️ Response is not a Map');
          return _getStaticCategories();
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}');
        print('   Body: ${response.body}');
        return _getStaticCategories();
      }
    } catch (e, stackTrace) {
      print('❌ Exception fetching categories: $e');
      print('   Stack: $stackTrace');
      return _getStaticCategories();
    }
  }

  List<Category> _getStaticCategories() {
    return [
      Category(id: 'pizza', name: 'Pizza', iconPath: 'assets/icons/pizza.png'),
      Category(
          id: 'burger', name: 'Burger', iconPath: 'assets/icons/burger.png'),
      Category(id: 'sushi', name: 'Sushi', iconPath: 'assets/icons/sushi.png'),
      Category(
          id: 'desserts',
          name: 'Desserts',
          iconPath: 'assets/icons/dessert.png'),
      Category(
          id: 'drinks', name: 'Drinks', iconPath: 'assets/icons/drink.png'),
    ];
  }

  Future<List<Restaurant>> searchRestaurants(
      {required String query, int maxResults = 50}) async {
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
            return nameLower.contains(queryLower) ||
                descLower.contains(queryLower);
          })
          .take(maxResults)
          .toList();
    } catch (e) {
      print('❌ Exception in searchRestaurants: $e');
      return [];
    }
  }

  Future<List<Restaurant>> getRestaurantsByCategory(
      List<String> categories, double lat, double lng,
      {int radius = 50000, int page = 1, int pageSize = 20}) async {
    final accessToken = await getAccessToken();
    try {
      print('Fetching restaurants by categories: $categories');
      print('Using lat: $lat, lng: $lng, radius: $radius');
      final response = await http
          .post(
            Uri.parse(
                'https://tawssilbackyou.onrender.com/restaurant/nearbyfilter'),
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

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData.containsKey('data')) {
            final List<dynamic> restaurantsList = responseData['data'];
            print('Found ${restaurantsList.length} restaurants');

            if (restaurantsList.isEmpty) {
              return [];
            }

            List<Restaurant> parsedRestaurants = [];

            for (int i = 0; i < restaurantsList.length; i++) {
              try {
                final restaurantData =
                    restaurantsList[i] as Map<String, dynamic>;
                final restaurant = Restaurant.fromJson(restaurantData);
                parsedRestaurants.add(restaurant);
              } catch (e) {
                print('Error parsing restaurant $i: $e');
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
        print('HTTP Error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }

  Future<Restaurant> getRestaurantById(String id) async {
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

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData.containsKey('data')) {
          final restaurantData = responseData['data'] as Map<String, dynamic>;
          return Restaurant.fromJson(restaurantData);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load restaurant');
      }
    } catch (e) {
      print('❌ Error fetching restaurant by ID: $e');
      rethrow;
    }
  }

  Future<List<MenuItem>> getMenuItems(
      {required String restaurantId, String? categoryId}) async {
    final accessToken = await getAccessToken();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/menuitem/filter');
      print('📄 Fetching menu items from: $uri');
      print(
          '📥 Body: { restaurant_id: $restaurantId, category_id: $categoryId }');
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

      print('📡 Menu items response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true) {
          final List<dynamic>? itemsList = (responseData['data'] as List?) ??
              (responseData['items'] as List?);
          if (itemsList == null) {
            print(
                '⚠️ Menu items response missing "data" or "items" keys. Response: ${response.body}');
            return [];
          }

          print('✅ Found ${itemsList.length} menu items (before filtering)');

          List<MenuItem> parsedItems = [];

          for (int i = 0; i < itemsList.length; i++) {
            try {
              final itemData = itemsList[i] as Map<String, dynamic>;
              final menuItem = MenuItem.fromJson(itemData);

              // If backend didn't populate restaurant_id, assume items belong to requested restaurant
              if (menuItem.restaurantId.isEmpty) {
                parsedItems.add(menuItem);
                print('✓ Parsed menu item (no restaurant_id): ${menuItem.nom}');
              } else if (menuItem.restaurantId == restaurantId) {
                parsedItems.add(menuItem);
                print('✓ Parsed menu item: ${menuItem.nom}');
              } else {
                print(
                    '• Skipping menu item ${menuItem.nom} (belongs to ${menuItem.restaurantId})');
              }
            } catch (e) {
              print('❌ Error parsing menu item $i: $e');
              print('   Data: ${itemsList[i]}');
            }
          }

          print(
              '✅ Successfully loaded ${parsedItems.length} menu items for restaurant $restaurantId');
          return parsedItems;
        }

        print('⚠️ Invalid response format for menu items: ${response.body}');
        return [];
      }

      print('❌ HTTP Error ${response.statusCode}');
      return [];
    } catch (e, st) {
      print('❌ Exception fetching menu items: $e');
      print(st);
      return [];
    }
  }

  Future<List<MenuItemCategory>> getMenuCategories(
      {required String restaurantId}) async {
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
      print('❌ Error fetching menu categories: $e');
      return [];
    }
  }
}
