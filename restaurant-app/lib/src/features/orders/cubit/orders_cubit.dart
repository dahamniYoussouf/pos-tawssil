import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_state.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/features/orders/repositories/order_repository.dart';
import 'package:restaurant_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:restaurant_app/src/features/notifications/cubit/notifications_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrderRepository _orderRepository;
  final NotificationsCubit? _notificationsCubit;
  StreamSubscription? _notificationSubscription;

  OrdersCubit({
    OrderRepository? orderRepository,
    NotificationsCubit? notificationsCubit,
  })  : _orderRepository = orderRepository ?? locator<OrderRepository>(),
        _notificationsCubit = notificationsCubit,
        super(const OrdersInitial(selectedStatus: OrderStatus.pending)) {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    if (_notificationsCubit != null) {
      _notificationSubscription = _notificationsCubit!.stream.listen((notificationState) {
        if (notificationState is NotificationReceived) {
          _handleNotification(notificationState);
        }
      });
    }
  }

  void _handleNotification(NotificationReceived notification) {
    final eventType = notification.eventType;
    if (eventType == 'new_order' || eventType == 'order_updated' || eventType == 'order_status_changed' || eventType == 'order_cancelled') {
      refreshOrders();
    }
  }

  Future<void> fetchOrders({
    int page = 1,
    int limit = 20,
    String? status,
    bool loadMore = false,
  }) async {
    final selectedStatus = status ?? state.selectedStatus;
    if (!loadMore) {
      emit(OrdersLoading(selectedStatus: selectedStatus));
    }
    final result = await _orderRepository.fetchOrders(
      page: page,
      limit: limit,
      status: selectedStatus,
    );
    result.fold(
      (error) => emit(OrdersError(message: error, selectedStatus: selectedStatus)),
      (orders) {
        if (loadMore && state is OrdersLoaded) {
          final currentState = state as OrdersLoaded;
          final updatedOrders = [...currentState.orders, ...orders];
          emit(OrdersLoaded(
            orders: updatedOrders,
            hasMore: orders.length >= limit,
            currentPage: page,
            selectedStatus: selectedStatus,
          ));
        } else {
          emit(OrdersLoaded(
            orders: orders,
            hasMore: orders.length >= limit,
            currentPage: page,
            selectedStatus: selectedStatus,
          ));
        }
      },
    );
  }

  Future<void> loadMoreOrders({String? status, int limit = 20}) async {
    if (state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    if (!currentState.hasMore) return;
    await fetchOrders(
      page: currentState.currentPage + 1,
      limit: limit,
      status: status,
      loadMore: true,
    );
  }

  Future<void> acceptOrder(String orderId) async {
    if (state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    emit(OrderActionLoading(
      orders: currentState.orders,
      orderId: orderId,
      actionType: OrderActionType.accept,
      selectedStatus: currentState.selectedStatus,
    ));
    final result = await _orderRepository.acceptOrder(orderId);
    result.fold(
      (error) => emit(OrderActionError(
        orders: currentState.orders,
        message: error,
        selectedStatus: currentState.selectedStatus,
      )),
      (_) {
        emit(OrderActionSuccess(
          orders: currentState.orders,
          message: 'Order accepted successfully',
          selectedStatus: currentState.selectedStatus,
        ));
        // Refresh orders with the same status after successful action
        refreshOrders(status: currentState.selectedStatus);
      },
    );
  }

  Future<void> cancelOrder(String orderId) async {
    if (state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    emit(OrderActionLoading(
      orders: currentState.orders,
      orderId: orderId,
      actionType: OrderActionType.cancel,
      selectedStatus: currentState.selectedStatus,
    ));
    final result = await _orderRepository.cancelOrder(orderId);
    result.fold(
      (error) => emit(OrderActionError(
        orders: currentState.orders,
        message: error,
        selectedStatus: currentState.selectedStatus,
      )),
      (_) {
        emit(OrderActionSuccess(
          orders: currentState.orders,
          message: 'Order canceled successfully',
          selectedStatus: currentState.selectedStatus,
        ));
        // Refresh orders with the same status after successful action
        refreshOrders(status: currentState.selectedStatus);
      },
    );
  }

  void refreshOrders({String? status, int limit = 20}) {
    fetchOrders(page: 1, limit: limit, status: status);
  }

  void changeStatus(String status) {
    if (state.selectedStatus != status) {
      fetchOrders(status: status);
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
