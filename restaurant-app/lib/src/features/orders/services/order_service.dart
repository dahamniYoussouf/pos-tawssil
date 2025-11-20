import 'package:restaurant_app/src/core/services/base_api_service.dart';

class OrderService extends BaseApiService {
  Future<Map<String, dynamic>> fetchOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    return await getRequest(
      '/order',
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    return await postRequest(
      '/order/$orderId/accept',
    );
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    return await postRequest(
      '/order/$orderId/decline',
      data: {"reason": "Restaurant is too busy, cannot prepare order in time"},
    );
  }
}
