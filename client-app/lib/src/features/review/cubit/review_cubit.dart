import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/review_request.dart';
import '../services/review_service.dart';
import 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final ReviewService _reviewService;

  ReviewCubit({
    ReviewService? reviewService,
  })  : _reviewService = reviewService ?? ReviewService(),
        super(ReviewInitial());

  /// Submit restaurant review
  Future<void> submitRestaurantReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    if (isClosed) return;

    try {
      emit(ReviewLoading());
      final request = RestaurantReviewRequest(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
      final response = await _reviewService.submitRestaurantReview(request);

      if (isClosed) return;

      if (response['success'] == true ||
          response['status'] == 200 ||
          response['status'] == 201) {
        emit(ReviewSuccess(
            message: response['message'] ?? 'Review submitted successfully'));
      } else {
        emit(ReviewError(
            message: response['message'] ?? 'Failed to submit review'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ReviewError(message: 'An error occurred: ${e.toString()}'));
      }
    }
  }

  /// Submit order/driver review
  Future<void> submitOrderReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    if (isClosed) return;

    try {
      emit(ReviewLoading());
      final request = OrderReviewRequest(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
      final response = await _reviewService.submitOrderReview(request);

      if (isClosed) return;

      if (response['success'] == true ||
          response['status'] == 200 ||
          response['status'] == 201) {
        emit(ReviewSuccess(
            message: response['message'] ?? 'Review submitted successfully'));
      } else {
        emit(ReviewError(
            message: response['message'] ?? 'Failed to submit review'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ReviewError(message: 'An error occurred: ${e.toString()}'));
      }
    }
  }

  /// Reset cubit state
  void reset() {
    if (isClosed) return;
    emit(ReviewInitial());
  }
}
