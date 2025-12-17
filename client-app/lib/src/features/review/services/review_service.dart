import '../../../core/services/base_api_service.dart';
import '../models/review_request.dart';

class ReviewService extends BaseApiService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() {
    return _instance;
  }

  ReviewService._internal() : super();

  /// Submit restaurant review
  /// Endpoint: POST /review/restaurant
  Future<Map<String, dynamic>> submitRestaurantReview(RestaurantReviewRequest request) async {
    return await postRequest('/review/restaurant', data: request.toJson());
  }

  /// Submit order/driver review
  /// Endpoint: POST /review/order
  Future<Map<String, dynamic>> submitOrderReview(OrderReviewRequest request) async {
    return await postRequest('/review/order', data: request.toJson());
  }
}
