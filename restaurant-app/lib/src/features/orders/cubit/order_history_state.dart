import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/features/orders/models/order_history_filters.dart';

abstract class OrderHistoryState extends Equatable {
  final OrderHistoryFilters filters;

  const OrderHistoryState({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class OrderHistoryInitial extends OrderHistoryState {
  const OrderHistoryInitial({required super.filters});
}

class OrderHistoryLoading extends OrderHistoryState {
  const OrderHistoryLoading({required super.filters});
}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderModel> orders;
  final bool hasMore;
  final int currentPage;

  const OrderHistoryLoaded({
    required this.orders,
    required super.filters,
    this.hasMore = true,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [orders, hasMore, currentPage, filters];

  OrderHistoryLoaded copyWith({
    List<OrderModel>? orders,
    bool? hasMore,
    int? currentPage,
    OrderHistoryFilters? filters,
  }) {
    return OrderHistoryLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filters: filters ?? this.filters,
    );
  }
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError({
    required this.message,
    required super.filters,
  });

  @override
  List<Object?> get props => [message, filters];
}

