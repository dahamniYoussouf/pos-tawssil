import 'package:equatable/equatable.dart';
import '../models/order_model.dart';
import '../widgets/history/order_history_filter_bar.dart';

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();

  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderModel> orders;
  final Map<String, List<OrderModel>> groupedOrders;
  final OrderHistoryFilter activeFilter;
  final Set<String> expandedOrderIds;
  final int totalCount;

  const OrderHistoryLoaded({
    required this.orders,
    required this.groupedOrders,
    this.activeFilter = OrderHistoryFilter.all,
    this.expandedOrderIds = const {},
    required this.totalCount,
  });

  OrderHistoryLoaded copyWith({
    List<OrderModel>? orders,
    Map<String, List<OrderModel>>? groupedOrders,
    OrderHistoryFilter? activeFilter,
    Set<String>? expandedOrderIds,
    int? totalCount,
  }) {
    return OrderHistoryLoaded(
      orders: orders ?? this.orders,
      groupedOrders: groupedOrders ?? this.groupedOrders,
      activeFilter: activeFilter ?? this.activeFilter,
      expandedOrderIds: expandedOrderIds ?? this.expandedOrderIds,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props =>
      [orders, groupedOrders, activeFilter, expandedOrderIds, totalCount];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
