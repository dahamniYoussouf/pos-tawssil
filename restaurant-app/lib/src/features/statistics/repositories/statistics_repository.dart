import 'package:restaurant_app/src/core/utils/either.dart';
import 'package:restaurant_app/src/features/statistics/models/statistics_model.dart';
import 'package:restaurant_app/src/features/statistics/services/statistics_service.dart';

class StatisticsRepository {
  final StatisticsService _statisticsService;

  StatisticsRepository({StatisticsService? statisticsService})
      : _statisticsService = statisticsService ?? StatisticsService();

  Future<Either<String, StatisticsModel>> fetchStatistics({
    required String dateFrom,
    required String dateTo,
    String? status,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _statisticsService.fetchStatistics(
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      if (response['success'] == true) {
        final statistics = StatisticsModel.fromJson(response);
        return Right(statistics);
      } else {
        return Left(response['message'] ?? 'Failed to fetch statistics');
      }
    } catch (e) {
      return Left('Error fetching statistics: ${e.toString()}');
    }
  }
}

