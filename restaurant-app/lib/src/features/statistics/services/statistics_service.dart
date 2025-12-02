import 'package:restaurant_app/src/core/services/base_api_service.dart';

class StatisticsService extends BaseApiService {
  Future<Map<String, dynamic>> fetchStatistics({
    required String dateFrom,
    required String dateTo,
    String? status,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParameters = <String, dynamic>{
      'date_from': dateFrom,
      'date_to': dateTo,
    };
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (minPrice != null) {
      queryParameters['min_price'] = minPrice;
    }
    if (maxPrice != null) {
      queryParameters['max_price'] = maxPrice;
    }
    return await getRequest(
      '/restaurant/statistics/me',
      queryParameters: queryParameters,
    );
  }
}

