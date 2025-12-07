import 'package:restaurant_app/src/core/services/base_api_service.dart';

class OrderHistoryService extends BaseApiService {
  Future<Map<String, dynamic>> fetchOrderHistory({
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
    final queryParameters = <String, dynamic>{};

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status.join(',');
    }

    if (orderType != null && orderType.isNotEmpty) {
      queryParameters['order_type'] = orderType;
    }

    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParameters['date_from'] = dateFrom;
    }

    if (dateTo != null && dateTo.isNotEmpty) {
      queryParameters['date_to'] = dateTo;
    }

    if (minPrice != null) {
      queryParameters['min_price'] = minPrice.toInt();
    }

    if (maxPrice != null) {
      queryParameters['max_price'] = maxPrice.toInt();
    }

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    queryParameters['page'] = page;
    queryParameters['limit'] = limit;

    return await getRequest(
      '/restaurant/orders/history',
      queryParameters: queryParameters,
    );
  }
}
