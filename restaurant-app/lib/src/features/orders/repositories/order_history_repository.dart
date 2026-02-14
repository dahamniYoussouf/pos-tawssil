import 'package:restaurant_app/src/core/utils/either.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/features/orders/services/order_history_service.dart';

class OrderHistoryLists {
  final List<OrderModel> ordersPos;
  final List<OrderModel> ordersMobile;

  const OrderHistoryLists({
    required this.ordersPos,
    required this.ordersMobile,
  });
}

class OrderHistoryRepository {
  final OrderHistoryService _orderHistoryService;

  OrderHistoryRepository({OrderHistoryService? orderHistoryService})
      : _orderHistoryService = orderHistoryService ?? OrderHistoryService();

  Future<Either<String, OrderHistoryLists>> fetchOrderHistory({
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
        status:
            status, // status?.isEmpty ?? true ? ['delivered', 'declined'] : status,
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
        final ordersPosData =
            response['pos_orders'] ?? response['response'] ?? [];
        final ordersMobileData =
            response['app_orders'] ?? response['response'] ?? [];

        final ordersPos = ordersPosData is List
            ? ordersPosData
                .map(
                    (json) => OrderModel.fromJson(json as Map<String, dynamic>))
                .toList()
            : <OrderModel>[];

        final ordersMobile = ordersMobileData is List
            ? ordersMobileData
                .map(
                    (json) => OrderModel.fromJson(json as Map<String, dynamic>))
                .toList()
            : <OrderModel>[];

        return Right(
          OrderHistoryLists(
            ordersPos: ordersPos,
            ordersMobile: ordersMobile,
          ),
        );
      } else {
        return Left(response['message'] ?? 'Failed to fetch order history');
      }
    } catch (e) {
      return Left('Error fetching order history: ${e.toString()}');
    }
  }
}
