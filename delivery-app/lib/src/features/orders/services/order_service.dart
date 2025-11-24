import 'package:delivery_app/src/core/services/base_api_service.dart';

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

  Future<Map<String, dynamic>> fetchOrdersNearby() async {
    return await getRequest(
      '/order/nearby',
    );
  }

  Future<Map<String, dynamic>> assignOrderToDriver(String orderId) async {
    // this is use to assigned an order to a driver
    return await postRequest(
      '/order/$orderId/assign-driver',
    );
  }

  Future<Map<String, dynamic>> declineOrder(String orderId) async {
    return await postRequest(
      '/orders/$orderId/decline',
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

  Future<Map<String, dynamic>> fetchOrderById(String orderId) async {
    return await getRequest(
      '/order/$orderId',
    );
  }

  Future<Map<String, dynamic>> markOrderArrived(String orderId) async {
    return await postRequest(
      '/order/$orderId/arrived',
    );
  }

  Future<Map<String, dynamic>> startDelivery(String orderId) async {
    return await postRequest(
      '/order/$orderId/start-delivery',
    );
  }

  Future<Map<String, dynamic>> completeDelivery(String orderId) async {
    return await postRequest(
      '/order/$orderId/complete-delivery',
    );
  }

  Future<Map<String, dynamic>> driverCancelOrder(String orderId, {String? reason}) async {
    final data = <String, dynamic>{};
    if (reason != null && reason.isNotEmpty) {
      data['reason'] = reason;
    }
    return await postRequest(
      '/order/$orderId/driver-cancel',
      data: data,
    );
  }
}
