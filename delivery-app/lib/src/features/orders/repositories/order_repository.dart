import 'package:delivery_app/src/core/utils/either.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/services/order_service.dart';

class OrderRepository {
  final OrderService _orderService;

  OrderRepository({OrderService? orderService}) : _orderService = orderService ?? OrderService();

  Future<Either<String, List<OrderModel>>> fetchOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _orderService.fetchOrders(
        page: page,
        limit: limit,
        status: status,
      );
      if (response['success'] == true) {
        final data = response['data'] ?? response['orders'] ?? [];
        if (data is List && data.isNotEmpty) {
          final orders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
          return Right(orders);
        }
        if (data is List && data.isEmpty) {
          return const Right([]);
        }
        return const Left('Invalid response format');
      } else {
        final statusCode = response['status'];
        if (statusCode == -3 || statusCode == -2) {
          // final fakeOrders = FakeOrdersData.getFakeOrders();
          if (status != null && status.isNotEmpty) {
            // final filteredOrders = fakeOrders.where((order) => order.status == status).toList();
            return Right([]);
          }
          return Right([]);
        }
        return Left(response['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      // final fakeOrders = FakeOrdersData.getFakeOrders();
      if (status != null && status.isNotEmpty) {
        // final filteredOrders = fakeOrders.where((order) => order.status == status).toList();
        return Right([]);
      }
      return Right([]);
    }
  }

  Future<Either<String, List<OrderModel>>> fetchOrdersNearby() async {
    try {
      final response = await _orderService.fetchOrdersNearby();
      if (response['success'] == true) {
        final data = response['data'] ?? response['orders'] ?? [];
        if (data is List) {
          final orders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
          return Right(orders);
        }
        return const Left('Invalid response format');
      } else {
        return Left(response['message'] ?? 'Failed to fetch nearby orders');
      }
    } catch (e) {
      return Left('Error fetching nearby orders: ${e.toString()}');
    }
  }

  Future<Either<String, void>> assignOrderToDriver(String orderId) async {
    try {
      final response = await _orderService.assignOrderToDriver(orderId);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to assign order to driver');
      }
    } catch (e) {
      return Left('Error assigning order to driver: ${e.toString()}');
    }
  }

  Future<Either<String, void>> declineOrder(String orderId) async {
    try {
      final response = await _orderService.declineOrder(orderId);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to decline order');
      }
    } catch (e) {
      return Left('Error declining order: ${e.toString()}');
    }
  }

  Future<Either<String, void>> refuseOrder(String orderId, {String? reason}) async {
    try {
      final response = await _orderService.refuseOrder(orderId, reason: reason);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to refuse order');
      }
    } catch (e) {
      return Left('Error refusing order: ${e.toString()}');
    }
  }
}
