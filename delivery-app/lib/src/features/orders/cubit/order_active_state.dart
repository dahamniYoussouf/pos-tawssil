import 'package:equatable/equatable.dart';
import '../models/order_model.dart';
import '../widgets/history/order_history_filter_bar.dart';

abstract class OrderActiveState extends Equatable {
  const OrderActiveState();
  @override
  List<Object?> get props => [];
}

class OrderActiveInitial extends OrderActiveState {
  const OrderActiveInitial();
}

class OrderActiveLoading extends OrderActiveState {
  const OrderActiveLoading();
}

class OrderActiveLoaded extends OrderActiveState {
  final List<OrderModel> orders;
  final Map<String, List<OrderModel>> groupedOrders;
  final Set<String> expandedOrderIds;
  final int totalCount;

  const OrderActiveLoaded({
    required this.orders,
    required this.groupedOrders,
    this.expandedOrderIds = const {},
    required this.totalCount,
  });

  OrderActiveLoaded copyWith({
    List<OrderModel>? orders,
    Map<String, List<OrderModel>>? groupedOrders,
    OrderHistoryFilter? activeFilter,
    Set<String>? expandedOrderIds,
    int? totalCount,
  }) {
    return OrderActiveLoaded(
      orders: orders ?? this.orders,
      groupedOrders: groupedOrders ?? this.groupedOrders,
      expandedOrderIds: expandedOrderIds ?? this.expandedOrderIds,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props =>
      [orders, groupedOrders, expandedOrderIds, totalCount];
}

class OrderActiveError extends OrderActiveState {
  final String message;

  const OrderActiveError({required this.message});

  @override
  List<Object?> get props => [message];
}
