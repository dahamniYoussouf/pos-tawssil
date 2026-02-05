import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:client_app/src/core/services/notification_service.dart';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'order_history_state.dart';
import '../repositories/order_history_repository.dart';
import '../models/order_model.dart';
import '../widgets/history/order_history_filter_bar.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderHistoryRepository _orderHistoryRepository;
  final NotificationService _notificationService;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  OrderHistoryCubit({
    OrderHistoryRepository? orderHistoryRepository,
    NotificationService? notificationService,
  })  : _orderHistoryRepository =
            orderHistoryRepository ?? OrderHistoryRepository(),
        _notificationService =
            notificationService ?? locator<NotificationService>(),
        super(OrderHistoryInitial()) {
    _initializeNotificationListener();
  }

  Future<void> fetchOrderHistory({
    OrderHistoryFilter filter = OrderHistoryFilter.all,
    List<String>? status,
    String? orderType,
    String? dateFrom,
    String? dateTo,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    // Keep reference to previous state if it was loaded to preserve expansion
    final previousState =
        state is OrderHistoryLoaded ? state as OrderHistoryLoaded : null;

    emit(OrderHistoryLoading(activeFilter: filter));

    final result = await _orderHistoryRepository.fetchOrderHistory(
      status: status ?? _mapFilterToStatuses(filter),
      orderType: orderType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      minPrice: minPrice,
      maxPrice: maxPrice,
      search: search,
      page: page,
      limit: limit,
    );

    result.fold(
      (error) => emit(OrderHistoryError(message: error, activeFilter: filter)),
      (orders) {
        final grouped = _groupOrdersByDate(orders);
        emit(
          OrderHistoryLoaded(
            orders: orders,
            groupedOrders: grouped,
            activeFilter: filter,
            expandedOrderIds: previousState?.expandedOrderIds ?? {},
            totalCount: orders.length,
          ),
        );
      },
    );
  }

  void _initializeNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = _notificationService.notificationStream.listen(
      _handleNotification,
    );
  }

  Future<void> _handleNotification(Map<String, dynamic> notification) async {
    if (isClosed) return;
    final String type = notification['type'] ?? '';
    final Map<String, dynamic> data =
        notification['data'] as Map<String, dynamic>? ?? {};
    final String resolvedType =
        _resolveNotificationType(type: type, data: data);
    final String? notificationOrderId =
        data['orderId'] ?? data['order_id'] ?? data['_id'] ?? data['id'];
    if (notificationOrderId == null) {
      return;
    }
    if (!_shouldRefreshOrderHistory(resolvedType)) {
      return;
    }
    await refreshOrderHistory();
  }

  String _resolveNotificationType({
    required String type,
    required Map<String, dynamic> data,
  }) {
    if (type != 'notification') {
      return type;
    }
    final Object? nestedType = data['type'];
    if (nestedType is String && nestedType.isNotEmpty) {
      return nestedType;
    }
    return type;
  }

  bool _shouldRefreshOrderHistory(String type) {
    switch (type) {
      case 'order_created':
      case 'order_status_changed':
      case 'order_updated':
      case 'order_accepted':
      case 'order_refused':
      case 'order_cancelled':
      case 'order_preparing':
      case 'driver_assigned':
      case 'driver_location_updated':
        return true;
      default:
        return false;
    }
  }

  Future<void> filterBy(OrderHistoryFilter filter) async {
    await fetchOrderHistory(filter: filter);
  }

  void toggleOrderExpansion(String orderId) {
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;
      final newExpandedIds = Set<String>.from(currentState.expandedOrderIds);
      if (newExpandedIds.contains(orderId)) {
        newExpandedIds.remove(orderId);
      } else {
        newExpandedIds.add(orderId);
      }
      emit(currentState.copyWith(expandedOrderIds: newExpandedIds));
    }
  }

  Map<String, List<OrderModel>> _groupOrdersByDate(List<OrderModel> orders) {
    final Map<String, List<OrderModel>> groupedOrders = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var order in orders) {
      if (order.createdAt == null) continue;
      final orderDate = DateTime(
          order.createdAt!.year, order.createdAt!.month, order.createdAt!.day);
      String dateLabel;

      if (orderDate == today) {
        dateLabel =
            "TODAY|${DateFormat('dd MMMM yyyy').format(order.createdAt!)}";
      } else if (orderDate == yesterday) {
        dateLabel =
            "YESTERDAY|${DateFormat('dd MMMM yyyy').format(order.createdAt!)}";
      } else {
        dateLabel = DateFormat('dd MMMM yyyy').format(order.createdAt!);
      }

      if (!groupedOrders.containsKey(dateLabel)) {
        groupedOrders[dateLabel] = [];
      }
      groupedOrders[dateLabel]!.add(order);
    }
    return groupedOrders;
  }

  List<String>? _mapFilterToStatuses(OrderHistoryFilter filter) {
    switch (filter) {
      case OrderHistoryFilter.ongoing:
        return [
          OrderStatus.pending,
          OrderStatus.accepted,
          OrderStatus.preparing,
          OrderStatus.delivering,
          OrderStatus.assigned,
        ];
      case OrderHistoryFilter.delivered:
        return [OrderStatus.delivered];
      case OrderHistoryFilter.cancelled:
        return [OrderStatus.declined];
      case OrderHistoryFilter.all:
      default:
        return null;
    }
  }

  Future<void> refreshOrderHistory() async {
    await fetchOrderHistory(filter: state.activeFilter);
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
