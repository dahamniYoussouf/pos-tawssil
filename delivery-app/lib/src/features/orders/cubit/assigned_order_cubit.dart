import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/repositories/order_repository.dart';

class AssignedOrderState {
  final OrderModel? order;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;

  const AssignedOrderState({
    this.order,
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
  });

  AssignedOrderState copyWith({
    OrderModel? order,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
  }) {
    return AssignedOrderState(
      order: order ?? this.order,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: errorMessage,
    );
  }
}

class AssignedOrderCubit extends Cubit<AssignedOrderState> {
  final OrderRepository _orderRepository;

  AssignedOrderCubit({
    OrderRepository? orderRepository,
  })  : _orderRepository = orderRepository ?? locator<OrderRepository>(),
        super(const AssignedOrderState());

  Future<void> fetchOrderById(String orderId) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _orderRepository.fetchOrderById(orderId);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(state.copyWith(
          isLoading: false,
          errorMessage: error,
        ));
      },
      (order) {
        if (isClosed) return;
        emit(state.copyWith(
          order: order,
          isLoading: false,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> markOrderArrived(String orderId) async {
    if (isClosed) return;
    emit(state.copyWith(isActionLoading: true, errorMessage: null));
    final result = await _orderRepository.markOrderArrived(orderId);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(state.copyWith(
          isActionLoading: false,
          errorMessage: error,
        ));
      },
      (_) {
        if (isClosed) return;
        emit(state.copyWith(isActionLoading: false, errorMessage: null));
        if (isClosed) return;
        fetchOrderById(orderId);
      },
    );
  }

  Future<void> startDelivery(String orderId) async {
    if (isClosed) return;
    emit(state.copyWith(isActionLoading: true, errorMessage: null));
    final result = await _orderRepository.startDelivery(orderId);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(state.copyWith(isActionLoading: false, errorMessage: error));
      },
      (_) {
        if (isClosed) return;
        emit(state.copyWith(isActionLoading: false, errorMessage: null));
        if (isClosed) return;
        fetchOrderById(orderId);
      },
    );
  }

  Future<void> completeDelivery(String orderId) async {
    if (isClosed) return;
    emit(state.copyWith(isActionLoading: true, errorMessage: null));
    final result = await _orderRepository.completeDelivery(orderId);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(state.copyWith(
          isActionLoading: false,
          errorMessage: error,
        ));
      },
      (_) {
        if (isClosed) return;
        fetchOrderById(orderId);
      },
    );
  }

  Future<void> driverCancelOrder(String orderId, {String? reason}) async {
    if (isClosed) return;
    emit(state.copyWith(isActionLoading: true, errorMessage: null));
    final result = await _orderRepository.driverCancelOrder(orderId, reason: reason);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(state.copyWith(
          isActionLoading: false,
          errorMessage: error,
        ));
      },
      (_) {
        if (isClosed) return;
        emit(state.copyWith(
          isActionLoading: false,
          errorMessage: null,
        ));
      },
    );
  }
}
