import 'package:equatable/equatable.dart';
import '../models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final OrderModel order;

  const OrderLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderRefused extends OrderState {
  final OrderModel order;
  final String reason;

  const OrderRefused({
    required this.order,
    required this.reason,
  });

  @override
  List<Object?> get props => [order, reason];
}

class OrderDelayed extends OrderState {
  final OrderModel order;
  final String reason;

  const OrderDelayed({
    required this.order,
    required this.reason,
  });

  @override
  List<Object?> get props => [order, reason];
}

class OrderError extends OrderState {
  final String message;

  const OrderError({required this.message});

  @override
  List<Object?> get props => [message];
}

class OrderCreating extends OrderState {}

class OrderCreated extends OrderState {
  final OrderModel order;

  const OrderCreated({required this.order});

  @override
  List<Object?> get props => [order];
}
