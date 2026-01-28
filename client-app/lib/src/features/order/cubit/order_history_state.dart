import 'package:equatable/equatable.dart';
import '../models/order_model.dart';

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();

  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderModel> orders;
  final int totalCount;

  const OrderHistoryLoaded({
    required this.orders,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [orders, totalCount];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
