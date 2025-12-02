import 'package:restaurant_app/src/core/services/base_api_service.dart';

class RestaurantService extends BaseApiService {
  Future<Map<String, dynamic>> getRestaurantProfile() async {
    return await getRequest('/restaurant/profile/me');
  }

  Future<Map<String, dynamic>> getRestaurantDetails() async {
    return await getRequest('/restaurant/details');
  }
}
