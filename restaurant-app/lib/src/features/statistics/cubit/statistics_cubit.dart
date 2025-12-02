import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/core/utils/either.dart';
import 'package:restaurant_app/src/features/statistics/cubit/statistics_state.dart';
import 'package:restaurant_app/src/features/statistics/models/statistics_model.dart';
import 'package:restaurant_app/src/features/statistics/repositories/statistics_repository.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  final StatisticsRepository _statisticsRepository;

  StatisticsCubit({
    StatisticsRepository? statisticsRepository,
  })  : _statisticsRepository =
            statisticsRepository ?? locator<StatisticsRepository>(),
        super(const StatisticsInitial()) {
    _initializeDefaultDates();
  }

  void _initializeDefaultDates() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    emit(state.copyWith(
      dateFrom: startOfMonth,
      dateTo: now,
    ));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchStatistics() async {
    if (state.dateFrom == null || state.dateTo == null) {
      emit(StatisticsError(
        message: 'errorDateRangeRequired',
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        selectedStatus: state.selectedStatus,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      ));
      return;
    }

    emit(StatisticsLoading(
      statistics: state.statistics,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      selectedStatus: state.selectedStatus,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
    ));

    final Either<String, StatisticsModel> result =
        await _statisticsRepository.fetchStatistics(
      dateFrom: _formatDate(state.dateFrom!),
      dateTo: _formatDate(state.dateTo!),
      status: state.selectedStatus,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
    );

    result.fold(
      (error) => emit(StatisticsError(
        message: error,
        statistics: state.statistics,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        selectedStatus: state.selectedStatus,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      )),
      (statistics) => emit(StatisticsLoaded(
        statistics: statistics,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        selectedStatus: state.selectedStatus,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      )),
    );
  }

  void setDateRange(DateTime? from, DateTime? to) {
    emit(state.copyWith(dateFrom: from, dateTo: to));
  }

  void setStatus(String? status) {
    emit(state.copyWith(selectedStatus: status));
  }

  void setPriceRange(double? min, double? max) {
    emit(state.copyWith(minPrice: min, maxPrice: max));
  }

  void clearFilters() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    emit(state.copyWith(
      dateFrom: startOfMonth,
      dateTo: now,
      selectedStatus: null,
      minPrice: null,
      maxPrice: null,
    ));
  }
}
