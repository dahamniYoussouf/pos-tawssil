import '../../../core/services/base_api_service.dart';
import '../models/review_request.dart';

class ReviewService extends BaseApiService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() {
    return _instance;
  }

  ReviewService._internal() : super();

  /// Submit restaurant review
  /// Endpoint: POST /order/:id/restaurant-rating
  Future<Map<String, dynamic>> submitRestaurantReview(
      RestaurantReviewRequest request) async {
    return await postRequest('/order/${request.orderId}/restaurant-rating',
        data: request.toJson());
  }

  /// Submit driver review
  /// Endpoint: POST /order/:id/driver-rating
  Future<Map<String, dynamic>> submitOrderReview(
      OrderReviewRequest request) async {
    return await postRequest('/order/${request.orderId}/driver-rating',
        data: request.toJson());
  }
}
