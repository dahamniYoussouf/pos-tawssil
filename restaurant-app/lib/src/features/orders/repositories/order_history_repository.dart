import 'package:restaurant_app/src/core/utils/either.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/features/orders/services/order_history_service.dart';

class OrderHistoryRepository {
  final OrderHistoryService _orderHistoryService;

  OrderHistoryRepository({OrderHistoryService? orderHistoryService})
      : _orderHistoryService = orderHistoryService ?? OrderHistoryService();

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
}
