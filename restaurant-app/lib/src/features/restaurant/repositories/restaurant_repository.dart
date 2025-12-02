import 'package:restaurant_app/src/core/utils/either.dart';
import 'package:restaurant_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:restaurant_app/src/features/restaurant/services/restaurant_service.dart';

class RestaurantRepository {
  final RestaurantService _restaurantService;

  RestaurantRepository({RestaurantService? restaurantService})
      : _restaurantService = restaurantService ?? RestaurantService();

  Future<Either<String, RestaurantModel>> getRestaurantDetails() async {
    try {
      final response = await _restaurantService.getRestaurantDetails();
      if (response['success'] == true) {
        final data = response['data'] ?? response['restaurant'] ?? response;
        final restaurant = RestaurantModel.fromJson(data as Map<String, dynamic>);
        return Right(restaurant);
      } else {
        return Left(response['message'] ?? 'Failed to fetch restaurant details');
      }
    } catch (e) {
      return Left('Error fetching restaurant details: ${e.toString()}');
    }
  }
}

