class RestaurantReviewRequest {
  final String orderId;
  final int restaurantRating;
  final String? restaurantReviewComment;

  RestaurantReviewRequest({
    required this.orderId,
    required this.restaurantRating,
    this.restaurantReviewComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurant_rating': restaurantRating,
      if (restaurantReviewComment != null &&
          restaurantReviewComment!.isNotEmpty)
        'restaurant_review_comment': restaurantReviewComment,
    };
  }
}

class OrderReviewRequest {
  final String orderId;
  final int driverRating;
  final String? driverReviewComment;

  OrderReviewRequest({
    required this.orderId,
    required this.driverRating,
    this.driverReviewComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'driver_rating': driverRating,
      if (driverReviewComment != null && driverReviewComment!.isNotEmpty)
        'driver_review_comment': driverReviewComment,
    };
  }
}
