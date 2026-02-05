import 'package:delivery_app/src/core/utils/either.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/services/order_service.dart';
import 'package:delivery_app/src/features/orders/data/fake_orders_data.dart';

class OrderRepository {
  final OrderService _orderService;

  OrderRepository({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  Future<Either<String, List<OrderModel>>> fetchOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _orderService
          .fetchOrders(
            page: page,
            limit: limit,
            status: status,
          )
          .timeout(const Duration(seconds: 5));

      if (response['success'] == true) {
        final data = response['data'] ?? response['orders'] ?? [];
        if (data is List) {
          final orders = data
              .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return Right(orders);
        }
        return const Left('Invalid response format');
      } else {
        return Left(response['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      return Left('Error fetching orders: ${e.toString()}');
    }
  }

  Future<Either<String, List<OrderModel>>> fetchOrdersNearby() async {
    try {
      final response = await _orderService
          .fetchOrdersNearby()
          .timeout(const Duration(seconds: 5));

      List<OrderModel> orders = [];
      if (response['success'] == true) {
        final data = response['data'] ?? response['orders'] ?? [];
        if (data is List) {
          orders = data
              .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      // Add fake orders from the centralized data source
      orders.addAll(FakeOrdersData.getFakeOrders());

      return Right(orders);
    } catch (e) {
      // On error, return fake orders for simulation purposes
      return Right(FakeOrdersData.getFakeOrders());
    }
  }

  Future<Either<String, void>> assignOrderToDriver(String orderId) async {
    // Check if this is a fake order
    if (FakeOrdersData.getFakeOrderById(orderId) != null) {
      FakeOrdersData.updateOrderStatus(orderId, OrderStatus.assigned);
      return const Right(null);
    }
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

  Future<Either<String, void>> refuseOrder(String orderId,
      {String? reason}) async {
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

  Future<Either<String, OrderModel>> fetchOrderById(String orderId) async {
    // Check if this is a fake order
    final fakeOrder = FakeOrdersData.getFakeOrderById(orderId);
    if (fakeOrder != null) {
      return Right(fakeOrder);
    }
    try {
      final response = await _orderService.fetchOrderById(orderId);
      if (response['success'] == true) {
        final data = response['data'] ?? response['order'] ?? {};
        if (data is Map<String, dynamic>) {
          final order = OrderModel.fromJson(data);
          return Right(order);
        }
        return const Left('Invalid response format');
      } else {
        return Left(response['message'] ?? 'Failed to fetch order');
      }
    } catch (e) {
      return Left('Error fetching order: ${e.toString()}');
    }
  }

  Future<Either<String, void>> markOrderArrived(String orderId) async {
    // Check if this is a fake order
    if (FakeOrdersData.getFakeOrderById(orderId) != null) {
      FakeOrdersData.updateOrderStatus(orderId, OrderStatus.arrived);
      return const Right(null);
    }
    try {
      final response = await _orderService.markOrderArrived(orderId);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to mark order as arrived');
      }
    } catch (e) {
      return Left('Error marking order as arrived: ${e.toString()}');
    }
  }

  Future<Either<String, void>> startDelivery(String orderId) async {
    // Check if this is a fake order
    if (FakeOrdersData.getFakeOrderById(orderId) != null) {
      FakeOrdersData.updateOrderStatus(orderId, OrderStatus.delivering);
      return const Right(null);
    }
    try {
      final response = await _orderService.startDelivery(orderId);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to start delivery');
      }
    } catch (e) {
      return Left('Error starting delivery: ${e.toString()}');
    }
  }

  Future<Either<String, void>> completeDelivery(String orderId) async {
    // Check if this is a fake order
    if (FakeOrdersData.getFakeOrderById(orderId) != null) {
      FakeOrdersData.updateOrderStatus(orderId, OrderStatus.delivered);
      return const Right(null);
    }
    try {
      final response = await _orderService.completeDelivery(orderId);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to complete delivery');
      }
    } catch (e) {
      return Left('Error completing delivery: ${e.toString()}');
    }
  }

  Future<Either<String, void>> driverCancelOrder(String orderId,
      {String? reason}) async {
    try {
      final response =
          await _orderService.driverCancelOrder(orderId, reason: reason);
      if (response['success'] == true) {
        return const Right(null);
      } else {
        return Left(response['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      return Left('Error canceling order: ${e.toString()}');
    }
  }
}
