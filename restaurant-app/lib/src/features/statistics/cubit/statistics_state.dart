import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/statistics/models/statistics_model.dart';

class StatisticsState extends Equatable {
  final StatisticsModel? statistics;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? selectedStatus;
  final double? minPrice;
  final double? maxPrice;
  final String selectedSource; // all, mobile, pos
  final String selectedPeriod; // all, today, yesterday, week, month
  final double reviews;
  final double reviewsValue;

  const StatisticsState({
    this.statistics,
    this.dateFrom,
    this.dateTo,
    this.selectedStatus,
    this.minPrice,
    this.maxPrice,
    this.selectedSource = 'all',
    this.selectedPeriod = 'all',
    this.reviews = 0,
    this.reviewsValue = 0,
  });

  @override
  List<Object?> get props => [
        statistics,
        dateFrom,
        dateTo,
        selectedStatus,
        minPrice,
        maxPrice,
        selectedSource,
        selectedPeriod,
        reviews,
        reviewsValue,
      ];

  StatisticsState copyWith({
    StatisticsModel? statistics,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? selectedStatus,
    double? minPrice,
    double? maxPrice,
    String? selectedSource,
    String? selectedPeriod,
    double? reviews,
    double? reviewsValue,
  }) {
    return StatisticsState(
      statistics: statistics ?? this.statistics,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedSource: selectedSource ?? this.selectedSource,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      reviews: reviews ?? this.reviews,
      reviewsValue: reviewsValue ?? this.reviewsValue,
    );
  }
}

class StatisticsInitial extends StatisticsState {
  const StatisticsInitial({
    super.selectedSource = 'all',
    super.selectedPeriod = 'all',
  });
}

class StatisticsLoading extends StatisticsState {
  const StatisticsLoading({
    super.statistics,
    super.dateFrom,
    super.dateTo,
    super.selectedStatus,
    super.minPrice,
    super.maxPrice,
    super.selectedSource = 'all',
    super.selectedPeriod = 'all',
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
    super.selectedSource = 'all',
    super.selectedPeriod = 'all',
    super.reviews = 0,
    super.reviewsValue = 0,
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
    super.selectedSource = 'all',
    super.selectedPeriod = 'all',
  });

  @override
  List<Object?> get props => [message, ...super.props];
}
