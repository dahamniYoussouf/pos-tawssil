import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

abstract class OrdersState extends Equatable {
  final String selectedStatus;

  const OrdersState({required this.selectedStatus});

  @override
  List<Object?> get props => [selectedStatus];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial({required super.selectedStatus});
}

class OrdersLoading extends OrdersState {
  const OrdersLoading({required super.selectedStatus});
}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> orders;
  final bool hasMore;
  final int currentPage;

  const OrdersLoaded({
    required this.orders,
    required super.selectedStatus,
    this.hasMore = true,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [orders, hasMore, currentPage, selectedStatus];

  OrdersLoaded copyWith({
    List<OrderModel>? orders,
    bool? hasMore,
    int? currentPage,
    String? selectedStatus,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError({
    required this.message,
    required super.selectedStatus,
  });

  @override
  List<Object?> get props => [message, selectedStatus];
}

class OrderActionLoading extends OrdersState {
  final List<OrderModel> orders;
  final String orderId;

  const OrderActionLoading({
    required this.orders,
    required this.orderId,
    required super.selectedStatus,
  });

  @override
  List<Object?> get props => [orders, orderId, selectedStatus];
}

class OrderActionSuccess extends OrdersState {
  final List<OrderModel> orders;
  final String message;

  const OrderActionSuccess({
    required this.orders,
    required this.message,
    required super.selectedStatus,
  });

  @override
  List<Object?> get props => [orders, message, selectedStatus];
}

class OrderActionError extends OrdersState {
  final List<OrderModel> orders;
  final String message;

  const OrderActionError({
    required this.orders,
    required this.message,
    required super.selectedStatus,
  });

  @override
  List<Object?> get props => [orders, message, selectedStatus];
}
