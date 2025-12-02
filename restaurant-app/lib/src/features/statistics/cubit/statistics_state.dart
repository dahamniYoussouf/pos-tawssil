import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/statistics/models/statistics_model.dart';

class StatisticsState extends Equatable {
  final StatisticsModel? statistics;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? selectedStatus;
  final double? minPrice;
  final double? maxPrice;

  const StatisticsState({
    this.statistics,
    this.dateFrom,
    this.dateTo,
    this.selectedStatus,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [
        statistics,
        dateFrom,
        dateTo,
        selectedStatus,
        minPrice,
        maxPrice,
      ];

  StatisticsState copyWith({
    StatisticsModel? statistics,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? selectedStatus,
    double? minPrice,
    double? maxPrice,
  }) {
    return StatisticsState(
      statistics: statistics ?? this.statistics,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

class StatisticsLoading extends StatisticsState {
  const StatisticsLoading({
    super.statistics,
    super.dateFrom,
    super.dateTo,
    super.selectedStatus,
    super.minPrice,
    super.maxPrice,
  });
}

class StatisticsLoaded extends StatisticsState {
  const StatisticsLoaded({
    required super.statistics,
    super.dateFrom,
    super.dateTo,
    super.selectedStatus,
    super.minPrice,
    super.maxPrice,
  });
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError({
    required this.message,
    super.statistics,
    super.dateFrom,
    super.dateTo,
    super.selectedStatus,
    super.minPrice,
    super.maxPrice,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}

