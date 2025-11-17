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

  Future<Map<String, dynamic>> refuseOrder(String orderId, {String? reason}) async {
    final data = <String, dynamic>{};
    if (reason != null && reason.isNotEmpty) {
      data['reason'] = reason;
    }
    return await postRequest(
      '/order/$orderId/refuse',
      data: data,
    );
  }
}

