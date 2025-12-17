class RestaurantReviewRequest {
  final String orderId;
  final int rating;
  final String? comment;

  RestaurantReviewRequest({
    required this.orderId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}

class OrderReviewRequest {
  final String orderId;
  final int rating;
  final String? comment;

  OrderReviewRequest({
    required this.orderId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}
