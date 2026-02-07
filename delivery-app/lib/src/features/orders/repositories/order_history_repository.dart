import '../../../core/utils/either.dart';
import '../models/order_model.dart';
import '../services/order_history_service.dart';

class OrderHistoryRepository {
  final OrderHistoryService _orderHistoryService;
  final DriverOrderHistoryService _driverOrderHistoryService;
  final DriverActiveOrderService _driverActiveOrderService;

  OrderHistoryRepository(
      {OrderHistoryService? orderHistoryService,
      DriverOrderHistoryService? driverOrderHistoryService,
      DriverActiveOrderService? driverActiveOrderService})
      : _orderHistoryService = orderHistoryService ?? OrderHistoryService(),
        _driverOrderHistoryService =
            driverOrderHistoryService ?? DriverOrderHistoryService(),
        _driverActiveOrderService =
            driverActiveOrderService ?? DriverActiveOrderService();

  Future<Either<String, List<OrderModel>>> fetchOrderHistory({
    List<String>? status,
    String? orderType,
    String? dateFrom,
    String? dateTo,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _orderHistoryService.fetchOrderHistory(
        status: status,
        orderType: orderType,
        dateFrom: dateFrom,
        dateTo: dateTo,
        minPrice: minPrice,
        maxPrice: maxPrice,
        search: search,
        page: page,
        limit: limit,
      );

      if (response['success'] == true) {
        final ordersData = response['data'] ?? response['orders'] ?? [];
        if (ordersData is List) {
          final orders = ordersData
              .map((json) => OrderModel.fromJson(
                    json as Map<String, dynamic>,
                  ))
              .toList();
          return Right(orders);
        }
        return const Right([]);
      } else {
        return Left(response['message'] ?? 'Failed to fetch order history');
      }
    } catch (e) {
      return Left('Error fetching order history: ${e.toString()}');
    }
  }

  Future<Either<String, List<OrderModel>>> fetchDriverOrderHistory({
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _driverOrderHistoryService.fetchDriverOrderHistory(
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        limit: limit,
      );
      if (response['success'] == true) {
        final ordersData = response['data'] ?? response['orders'] ?? [];
        if (ordersData is List) {
          final orders = ordersData
              .map((json) => OrderModel.fromJson(
                    json as Map<String, dynamic>,
                  ))
              .toList();
          return Right(orders);
        }
        return const Right([]);
      } else {
        return Left(
            response['message'] ?? 'Failed to fetch driver order history');
      }
    } catch (e) {
      return Left('Error fetching driver order history: ${e.toString()}');
    }
  }

  Future<Either<String, List<OrderModel>>> fetchActiveOrders() async {
    try {
      final response = await _driverActiveOrderService.fetchActiveOrders();
      if (response['success'] == true) {
        final ordersData = response['data'] ?? response['orders'] ?? [];
        if (ordersData is List) {
          final orders = ordersData
              .map((json) => OrderModel.fromJson(
                    json as Map<String, dynamic>,
                  ))
              .toList();
          return Right(orders);
        }
        return const Right([]);
      } else {
        return Left(response['message'] ?? 'Failed to fetch active orders');
      }
    } catch (e) {
      return Left('Error fetching active orders: ${e.toString()}');
    }
  }
}
