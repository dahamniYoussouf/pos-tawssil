import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_state.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/repositories/order_repository.dart';
import 'package:delivery_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:delivery_app/src/features/notifications/cubit/notifications_state.dart';

import 'package:delivery_app/src/core/services/sound_service.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrderRepository _orderRepository;
  final NotificationsCubit? _notificationsCubit;
  final SoundService _soundService;
  StreamSubscription? _notificationSubscription;

  OrdersCubit({
    OrderRepository? orderRepository,
    NotificationsCubit? notificationsCubit,
    SoundService? soundService,
  })  : _orderRepository = orderRepository ?? locator<OrderRepository>(),
        _notificationsCubit = notificationsCubit,
        _soundService = soundService ?? locator<SoundService>(),
        super(const OrdersInitial(selectedStatus: OrderStatus.pending)) {
    _listenToNotifications();
  }

  @override
  void emit(OrdersState state) {
    super.emit(state);
    _handleOrderSound(state);
  }

  void _handleOrderSound(OrdersState state) {
    if (state.orders.isNotEmpty &&
        state.selectedStatus == OrderStatus.pending) {
      _soundService.playOrderAlert();
    } else {
      _soundService.stopOrderAlert();
    }
  }

  void _listenToNotifications() {
    if (_notificationsCubit != null) {
      _notificationSubscription =
          _notificationsCubit!.stream.listen((notificationState) {
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
        if (notificationType == 'order_assigned' ||
            notificationType == 'delivery_complete' ||
            notificationType == 'order_location') {
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
    List<OrderModel> currentOrders = [];
    if (state is OrdersLoaded) {
      currentOrders = (state as OrdersLoaded).orders;
    } else if (state is OrderActionLoading) {
      currentOrders = (state as OrderActionLoading).orders;
    } else if (state is OrderActionSuccess) {
      currentOrders = (state as OrderActionSuccess).orders;
    } else if (state is OrderActionError) {
      currentOrders = (state as OrderActionError).orders;
    } else if (state is OrdersLoading) {
      currentOrders = (state as OrdersLoading).orders;
    }

    if (!loadMore) {
      emit(OrdersLoading(
        selectedStatus: selectedStatus,
        orders: currentOrders,
      ));
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
        emit(OrdersError(
          message: error,
          selectedStatus: selectedStatus,
          orders: currentOrders,
        ));
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

  void clearOrders() {
    if (isClosed) return;
    final currentStatus = state.selectedStatus;
    emit(OrdersLoaded(
        orders: const [],
        hasMore: false,
        currentPage: 1,
        selectedStatus: currentStatus));
  }

  Future<void> fetchOrdersNearby() async {
    if (isClosed) return;
    List<OrderModel> currentOrders = [];
    if (state is OrdersLoaded) {
      currentOrders = (state as OrdersLoaded).orders;
    } else if (state is OrderActionLoading) {
      currentOrders = (state as OrderActionLoading).orders;
    } else if (state is OrderActionSuccess) {
      currentOrders = (state as OrderActionSuccess).orders;
    } else if (state is OrderActionError) {
      currentOrders = (state as OrderActionError).orders;
    } else if (state is OrdersLoading) {
      currentOrders = (state as OrdersLoading).orders;
    }

    emit(OrdersLoading(
      selectedStatus: state.selectedStatus,
      orders: currentOrders,
    ));
    final result = await _orderRepository.fetchOrdersNearby();
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(OrdersError(
          message: error,
          selectedStatus: state.selectedStatus,
          orders: currentOrders,
        ));
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
    if (isClosed) return;

    // Get orders and selectedStatus from current state
    // Allow retry from OrderActionError or OrderActionLoading states
    List<OrderModel> orders;
    String selectedStatus;
    bool hasMore;
    int currentPage;

    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      orders = currentState.orders;
      selectedStatus = currentState.selectedStatus;
      hasMore = currentState.hasMore;
      currentPage = currentState.currentPage;
    } else if (state is OrderActionError) {
      final currentState = state as OrderActionError;
      orders = currentState.orders;
      selectedStatus = currentState.selectedStatus;
      hasMore =
          true; // Default value, will be preserved from previous OrdersLoaded if needed
      currentPage = 1; // Default value
    } else if (state is OrderActionLoading) {
      // Prevent duplicate calls while loading
      final currentState = state as OrderActionLoading;
      if (currentState.orderId == orderId) return;
      orders = currentState.orders;
      selectedStatus = currentState.selectedStatus;
      hasMore = true;
      currentPage = 1;
    } else if (state is OrderActionSuccess) {
      final currentState = state as OrderActionSuccess;
      orders = currentState.orders;
      selectedStatus = currentState.selectedStatus;
      hasMore = true;
      currentPage = 1;
    } else {
      // Not in a valid state to assign order
      return;
    }

    if (isClosed) return;
    emit(OrderActionLoading(
      orders: orders,
      orderId: orderId,
      selectedStatus: selectedStatus,
    ));
    final result = await _orderRepository.assignOrderToDriver(orderId);
    if (isClosed) return;
    result.fold(
      (error) {
        if (isClosed) return;
        emit(OrderActionError(
          orders: orders,
          message: error,
          selectedStatus: selectedStatus,
        ));
      },
      (_) {
        if (isClosed) return;
        final updatedOrders =
            orders.where((order) => order.id != orderId).toList();
        emit(OrderActionSuccess(
          orders: updatedOrders,
          message: 'Order assigned to driver successfully',
          selectedStatus: selectedStatus,
          orderId: orderId,
        ));
        if (isClosed) return;
        // Use the preserved hasMore and currentPage values
        emit(OrdersLoaded(
          orders: updatedOrders,
          hasMore: hasMore,
          currentPage: currentPage,
          selectedStatus: selectedStatus,
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
        final updatedOrders =
            currentState.orders.where((order) => order.id != orderId).toList();
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
        final updatedOrders =
            currentState.orders.where((order) => order.id != orderId).toList();
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

  void dismissOrder(String orderId) {
    if (isClosed) return;
    List<OrderModel> currentOrders = [];
    if (state is OrdersLoaded) {
      currentOrders = (state as OrdersLoaded).orders;
    } else if (state is OrderActionLoading) {
      currentOrders = (state as OrderActionLoading).orders;
    } else if (state is OrderActionSuccess) {
      currentOrders = (state as OrderActionSuccess).orders;
    } else if (state is OrderActionError) {
      currentOrders = (state as OrderActionError).orders;
    } else if (state is OrdersLoading) {
      currentOrders = (state as OrdersLoading).orders;
    }

    if (currentOrders.isNotEmpty) {
      final updatedOrders =
          currentOrders.where((order) => order.id != orderId).toList();
      emit(OrdersLoaded(
        orders: updatedOrders,
        selectedStatus: state.selectedStatus,
        hasMore: state is OrdersLoaded ? (state as OrdersLoaded).hasMore : true,
        currentPage:
            state is OrdersLoaded ? (state as OrdersLoaded).currentPage : 1,
      ));
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _soundService.stopOrderAlert();
    return super.close();
  }
}
