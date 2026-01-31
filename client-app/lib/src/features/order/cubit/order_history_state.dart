import 'package:equatable/equatable.dart';
import '../models/order_model.dart';
import '../widgets/history/order_history_filter_bar.dart';

abstract class OrderHistoryState extends Equatable {
  final OrderHistoryFilter activeFilter;
  const OrderHistoryState({this.activeFilter = OrderHistoryFilter.all});

  @override
  List<Object?> get props => [activeFilter];
}

class OrderHistoryInitial extends OrderHistoryState {
  const OrderHistoryInitial() : super(activeFilter: OrderHistoryFilter.all);
}

class OrderHistoryLoading extends OrderHistoryState {
  const OrderHistoryLoading({super.activeFilter});
}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderModel> orders;
  final Map<String, List<OrderModel>> groupedOrders;
  final Set<String> expandedOrderIds;
  final int totalCount;

  const OrderHistoryLoaded({
    required this.orders,
    required this.groupedOrders,
    super.activeFilter,
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

  const OrderHistoryError({required this.message, super.activeFilter});

  @override
  List<Object?> get props => [message, activeFilter];
}
