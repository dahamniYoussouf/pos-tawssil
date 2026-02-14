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
  final List<OrderModel> ordersPos;
  final List<OrderModel> ordersMobile;
  final bool hasMore;
  final int currentPage;

  const OrderHistoryLoaded({
    required this.ordersPos,
    required this.ordersMobile,
    required super.filters,
    this.hasMore = true,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props =>
      [ordersPos, ordersMobile, hasMore, currentPage, filters];

  OrderHistoryLoaded copyWith({
    List<OrderModel>? ordersPos,
    List<OrderModel>? ordersMobile,
    bool? hasMore,
    int? currentPage,
    OrderHistoryFilters? filters,
  }) {
    return OrderHistoryLoaded(
      ordersMobile: ordersMobile ?? this.ordersMobile,
      ordersPos: ordersPos ?? this.ordersPos,
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
