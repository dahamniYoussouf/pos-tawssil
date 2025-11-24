import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_state.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/repositories/order_repository.dart';
import 'package:delivery_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:delivery_app/src/features/notifications/cubit/notifications_state.dart';

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
    if (isClosed) return;
    final eventType = notification.eventType;
    final data = notification.data;

    switch (eventType) {
      case 'new_delivery':
        fetchOrdersNearby();
        break;
      case 'notification':
        final notificationType = data['type'] as String?;
        if (notificationType == 'order_assigned' || notificationType == 'delivery_complete' || notificationType == 'order_location') {
          refreshOrders();
        }
        break;
      case 'config_update':
        final configType = data['type'] as String?;
        if (configType == 'max_orders_updated') {
          refreshOrders();
        }
        break;
      case 'driver_alert':
        refreshOrders();
        break;
    }
  }

  Future<void> fetchOrders({
    int page = 1,
    int limit = 20,
    String? status,
    bool loadMore = false,
  }) async {
    if (isClosed) return;
    final selectedStatus = status ?? state.selectedStatus;
    if (!loadMore) {
      if (isClosed) return;
      emit(OrdersLoading(selectedStatus: selectedStatus));
    }
    final result = await _orderRepository.fetchOrders(
      page: page,
      limit: limit,
      status: selectedStatus,
    );
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(OrdersError(message: error, selectedStatus: selectedStatus));
      },
      (orders) {
        if (isClosed) return;
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

  Future<void> fetchOrdersNearby() async {
    if (isClosed) return;
    emit(OrdersLoading(selectedStatus: state.selectedStatus));
    final result = await _orderRepository.fetchOrdersNearby();
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(OrdersError(message: error, selectedStatus: state.selectedStatus));
      },
      (orders) {
        if (isClosed) return;
        emit(OrdersLoaded(
          orders: orders,
          hasMore: false,
          currentPage: 1,
          selectedStatus: state.selectedStatus,
        ));
      },
    );
  }

  Future<void> loadMoreOrders({String? status, int limit = 20}) async {
    if (isClosed || state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    if (!currentState.hasMore) return;
    await fetchOrders(
      page: currentState.currentPage + 1,
      limit: limit,
      status: status,
      loadMore: true,
    );
  }

  Future<void> assignOrderToDriver(String orderId) async {
    if (isClosed || state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    if (isClosed) return;
    emit(OrderActionLoading(
      orders: currentState.orders,
      orderId: orderId,
      selectedStatus: currentState.selectedStatus,
    ));
    final result = await _orderRepository.assignOrderToDriver(orderId);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(OrderActionError(
          orders: currentState.orders,
          message: error,
          selectedStatus: currentState.selectedStatus,
        ));
      },
      (_) {
        if (isClosed) return;
        final updatedOrders = currentState.orders.where((order) => order.id != orderId).toList();
        emit(OrderActionSuccess(
          orders: updatedOrders,
          message: 'Order assigned to driver successfully',
          selectedStatus: currentState.selectedStatus,
          orderId: orderId,
        ));
        if (isClosed) return;
        emit(OrdersLoaded(
          orders: updatedOrders,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
          selectedStatus: currentState.selectedStatus,
        ));
      },
    );
  }

  Future<void> declineOrder(String orderId) async {
    if (isClosed || state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    if (isClosed) return;
    emit(OrderActionLoading(
      orders: currentState.orders,
      orderId: orderId,
      selectedStatus: currentState.selectedStatus,
    ));
    final result = await _orderRepository.declineOrder(orderId);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(OrderActionError(
          orders: currentState.orders,
          message: error,
          selectedStatus: currentState.selectedStatus,
        ));
      },
      (_) {
        if (isClosed) return;
        final updatedOrders = currentState.orders.where((order) => order.id != orderId).toList();
        emit(OrderActionSuccess(
          orders: updatedOrders,
          message: 'Order declined successfully',
          selectedStatus: currentState.selectedStatus,
        ));
        if (isClosed) return;
        emit(OrdersLoaded(
          orders: updatedOrders,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
          selectedStatus: currentState.selectedStatus,
        ));
      },
    );
  }

  Future<void> refuseOrder(String orderId, {String? reason}) async {
    if (isClosed || state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    if (isClosed) return;
    emit(OrderActionLoading(
      orders: currentState.orders,
      orderId: orderId,
      selectedStatus: currentState.selectedStatus,
    ));
    final result = await _orderRepository.refuseOrder(orderId, reason: reason);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(OrderActionError(
          orders: currentState.orders,
          message: error,
          selectedStatus: currentState.selectedStatus,
        ));
      },
      (_) {
        if (isClosed) return;
        final updatedOrders = currentState.orders.where((order) => order.id != orderId).toList();
        emit(OrderActionSuccess(
          orders: updatedOrders,
          message: 'Order refused successfully',
          selectedStatus: currentState.selectedStatus,
        ));
        if (isClosed) return;
        emit(OrdersLoaded(
          orders: updatedOrders,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
          selectedStatus: currentState.selectedStatus,
        ));
      },
    );
  }

  void refreshOrders({String? status, int limit = 20}) {
    fetchOrdersNearby();
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
