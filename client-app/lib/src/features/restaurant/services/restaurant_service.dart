import '../models/category_model.dart';
import '../../../core/services/base_api_service.dart';

class RestaurantService extends BaseApiService {
  /// Fetch menu items for a specific restaurant by restaurant ID
  Future<Map<String, dynamic>> getRestaurantMenuItems(String restaurantId) async {
    return await getRequest('/menuitem/byrestaurant/$restaurantId');
  }

  /// Fetch nearby restaurants with optional filters.
  /// Uses POST /restaurant/nearbyfilter endpoint.
  Future<Map<String, dynamic>> getNearbyRestaurants({
    String? address,
    double? lat,
    double? lng,
    int radius = 5000,
    String? q,
    List<String>? categories,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'radius': radius,
      'page': page,
      'pageSize': pageSize,
    };

    if (address != null) body['address'] = address;
    if (lat != null) body['lat'] = lat.toString();
    if (lng != null) body['lng'] = lng.toString();
    if (q != null && q.isNotEmpty) body['q'] = q;
    if (categories != null && categories.isNotEmpty) {
      body['categories'] = categories;
    }

    return await postRequest('/restaurant/nearbyfilter', data: body);
  }

  /// Get restaurant by ID
  Future<Map<String, dynamic>> getRestaurantById(String id) async {
    return await getRequest('/restaurant/$id');
  }

  /// Get menu items with optional category filter
  Future<Map<String, dynamic>> getMenuItems({
    required String restaurantId,
    String? categoryId,
  }) async {
    final body = <String, dynamic>{
      'is_available': true,
      'restaurant_id': restaurantId,
    };
    if (categoryId != null) {
      body['category_id'] = categoryId;
    }
    return await postRequest('/menuitem/filter', data: body);
  }

  /// Get static categories (UI-only, not from API)
  List<CategoryModel> getStaticCategories() {
    return [
      CategoryModel(id: 'pizza', name: 'Pizza', iconPath: 'assets/icons/pizza.png'),
      CategoryModel(id: 'burger', name: 'Burger', iconPath: 'assets/icons/burger.png'),
      CategoryModel(id: 'tacos', name: 'Tacos', iconPath: 'assets/icons/tacos.png'),
      CategoryModel(id: 'sandwish', name: 'Sandwich', iconPath: 'assets/icons/sandwich.png'),
    ];
  }
}
