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
        final restaurant =
            RestaurantModel.fromJson(data as Map<String, dynamic>);
        return Right(restaurant);
      } else {
        return Left(
            response['message'] ?? 'Failed to fetch restaurant details');
      }
    } catch (e) {
      return Left('Error fetching restaurant details: ${e.toString()}');
    }
  }

  Future<Either<String, RestaurantModel>> getRestaurantProfile() async {
    try {
      final results = await Future.wait([
        _restaurantService.getRestaurantProfile(),
        _restaurantService.getRestaurantDetails(),
      ]);

      final profileResponse = results[0];
      final detailsResponse = results[1];

      if (profileResponse['success'] == true) {
        final profileData = profileResponse['data'] ??
            profileResponse['restaurant'] ??
            profileResponse;

        if (detailsResponse['success'] == true) {
          final detailsData = detailsResponse['data'] ??
              detailsResponse['restaurant'] ??
              detailsResponse;

          if (detailsData is Map<String, dynamic>) {
            // Merge categories and any other missing fields from details
            if (detailsData.containsKey('categories')) {
              (profileData as Map<String, dynamic>)['categories'] =
                  detailsData['categories'];
            }
          }
        }

        final restaurant =
            RestaurantModel.fromJson(profileData as Map<String, dynamic>);
        return Right(restaurant);
      } else {
        return Left(
            profileResponse['message'] ?? 'Failed to fetch restaurant profile');
      }
    } catch (e) {
      return Left('Error fetching restaurant profile: ${e.toString()}');
    }
  }

  Future<Either<String, void>> updateRestaurantProfile(
      RestaurantModel restaurant) async {
    try {
      final response = await _restaurantService.updateRestaurantProfile(
          restaurant.id, restaurant.toJson());
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(
            response['message'] ?? 'Failed to update restaurant profile');
      }
    } catch (e) {
      return Left('Error updating restaurant profile: ${e.toString()}');
    }
  }

  Future<Either<String, String>> updateRestaurantImage(String path) async {
    try {
      final response = await _restaurantService.updateRestaurantImage(path);
      if (response['success'] == true) {
        final imageUrl = response['data']?['image_url'] ??
            response['image_url'] ??
            response['url'] ??
            '';
        return Right(imageUrl.toString());
      } else {
        return Left(response['message'] ?? 'Failed to upload restaurant image');
      }
    } catch (e) {
      return Left('Error uploading restaurant image: ${e.toString()}');
    }
  }

  Future<Either<String, void>> updateRestaurantStatus(String status,
      {String? note}) async {
    try {
      final response =
          await _restaurantService.patchRestaurantStatus(status, note: note);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(
            response['message'] ?? 'Failed to update restaurant status');
      }
    } catch (e) {
      return Left('Error updating restaurant status: ${e.toString()}');
    }
  }
}
