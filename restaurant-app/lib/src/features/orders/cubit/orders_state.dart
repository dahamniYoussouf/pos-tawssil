import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> orders;
  final bool hasMore;
  final int currentPage;

  const OrdersLoaded({
    required this.orders,
    this.hasMore = true,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [orders, hasMore, currentPage];

  OrdersLoaded copyWith({
    List<OrderModel>? orders,
    bool? hasMore,
    int? currentPage,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError({required this.message});

  @override
  List<Object?> get props => [message];
}

class OrderActionLoading extends OrdersState {
  final List<OrderModel> orders;
  final String orderId;

  const OrderActionLoading({
    required this.orders,
    required this.orderId,
  });

  @override
  List<Object?> get props => [orders, orderId];
}

class OrderActionSuccess extends OrdersState {
  final List<OrderModel> orders;
  final String message;

  const OrderActionSuccess({
    required this.orders,
    required this.message,
  });

  @override
  List<Object?> get props => [orders, message];
}

class OrderActionError extends OrdersState {
  final List<OrderModel> orders;
  final String message;

  const OrderActionError({
    required this.orders,
    required this.message,
  });

  @override
  List<Object?> get props => [orders, message];
}

