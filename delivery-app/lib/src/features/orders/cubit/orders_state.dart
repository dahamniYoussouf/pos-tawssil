import 'package:equatable/equatable.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';

abstract class OrdersState extends Equatable {
  final String selectedStatus;
  final List<OrderModel> orders;

  const OrdersState({
    required this.selectedStatus,
    this.orders = const [],
  });

  @override
  List<Object?> get props => [selectedStatus, orders];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial({required super.selectedStatus})
      : super(orders: const []);
}

class OrdersLoading extends OrdersState {
  const OrdersLoading({
    required super.selectedStatus,
    super.orders = const [],
  });
}

class OrdersLoaded extends OrdersState {
  final bool hasMore;
  final int currentPage;

  const OrdersLoaded({
    required super.orders,
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
    super.orders = const [],
  });

  @override
  List<Object?> get props => [message, selectedStatus, orders];
}

class OrderActionLoading extends OrdersState {
  final String orderId;

  const OrderActionLoading({
    required super.orders,
    required this.orderId,
    required super.selectedStatus,
  });

  @override
  List<Object?> get props => [orders, orderId, selectedStatus];
}

class OrderActionSuccess extends OrdersState {
  final String message;
  final String? orderId;

  const OrderActionSuccess({
    required super.orders,
    required this.message,
    required super.selectedStatus,
    this.orderId,
  });

  @override
  List<Object?> get props => [orders, message, selectedStatus, orderId];
}

class OrderActionError extends OrdersState {
  final String message;

  const OrderActionError({
    required super.orders,
    required this.message,
    required super.selectedStatus,
  });

  @override
  List<Object?> get props => [orders, message, selectedStatus];
}
