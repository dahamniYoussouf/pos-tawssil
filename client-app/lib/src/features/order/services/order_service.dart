import '../../../core/services/base_api_service.dart';
import '../models/order_model.dart';

class OrderService extends BaseApiService {
  static final OrderService _instance = OrderService._internal();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal() : super();

  /// Fetch order by ID
  /// Endpoint: /order/{orderId}
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    return await getRequest('/order/$orderId');
  }

  /// Create a new order
  /// Endpoint: /order
  Future<Map<String, dynamic>> createOrder({
    required String restaurantId,
    required String orderType,
    required String deliveryAddress,
    required String lat,
    required String lng,
    required double deliveryFee,
    required String paymentMethod,
    String? deliveryInstructions,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      'restaurant_id': restaurantId,
      'order_type': orderType,
      'delivery_address': deliveryAddress,
      'lat': lat,
      'lng': lng,
      'delivery_fee': deliveryFee,
      'payment_method': paymentMethod,
      if (deliveryInstructions != null) 'delivery_instructions': deliveryInstructions,
      'items': items,
    };

    return await postRequest('/order', data: body);
  }

  /// Parse order from API response
  OrderModel? parseOrder(Map<String, dynamic> response) {
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } else if (response['order'] != null) {
      return OrderModel.fromJson(response['order'] as Map<String, dynamic>);
    } else if (response['id'] != null || response['_id'] != null) {
      return OrderModel.fromJson(response);
    }
    return null;
  }
}
