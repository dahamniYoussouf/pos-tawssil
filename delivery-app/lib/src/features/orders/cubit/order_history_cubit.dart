import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'order_history_state.dart';
import '../repositories/order_history_repository.dart';
import '../models/order_model.dart';
import '../widgets/history/order_history_filter_bar.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderHistoryRepository _orderHistoryRepository;

  OrderHistoryCubit({
    OrderHistoryRepository? orderHistoryRepository,
  })  : _orderHistoryRepository =
            orderHistoryRepository ?? OrderHistoryRepository(),
        super(const OrderHistoryInitial());

  // Future<void> fetchOrderHistory({
  //   OrderHistoryFilter filter = OrderHistoryFilter.all,
  //   List<String>? status,
  //   String? orderType,
  //   String? dateFrom,
  //   String? dateTo,
  //   double? minPrice,
  //   double? maxPrice,
  //   String? search,
  //   int page = 1,
  //   int limit = 50,
  // }) async {
  //   final previousState =
  //       state is OrderHistoryLoaded ? state as OrderHistoryLoaded : null;

  //   emit(OrderHistoryLoading(activeFilter: filter));

  //   final result = await _orderHistoryRepository.fetchOrderHistory(
  //     status: status ?? _mapFilterToStatuses(filter),
  //     orderType: orderType,
  //     dateFrom: dateFrom,
  //     dateTo: dateTo,
  //     minPrice: minPrice,
  //     maxPrice: maxPrice,
  //     search: search,
  //     page: page,
  //     limit: limit,
  //   );

  //   result.fold(
  //     (error) => emit(OrderHistoryError(message: error, activeFilter: filter)),
  //     (orders) {
  //       final grouped = _groupOrdersByDate(orders);
  //       emit(
  //         OrderHistoryLoaded(
  //           orders: orders,
  //           groupedOrders: grouped,
  //           activeFilter: filter,
  //           expandedOrderIds: previousState?.expandedOrderIds ?? {},
  //           totalCount: orders.length,
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> fetchDriverOrderHistory({
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) async {
    final previousState =
        state is OrderHistoryLoaded ? state as OrderHistoryLoaded : null;

    final result = await _orderHistoryRepository.fetchDriverOrderHistory(
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      limit: limit,
    );

    result.fold(
      (error) => emit(OrderHistoryError(
          message: error, activeFilter: OrderHistoryFilter.all)),
      (orders) {
        final grouped = _groupOrdersByDate(orders);
        emit(
          OrderHistoryLoaded(
            orders: orders,
            groupedOrders: grouped,
            activeFilter: OrderHistoryFilter.all,
            expandedOrderIds: previousState?.expandedOrderIds ?? {},
            totalCount: orders.length,
          ),
        );
      },
    );
  }

  Future<void> fetchActiveOrders() async {
    final previousState =
        state is OrderHistoryLoaded ? state as OrderHistoryLoaded : null;
    final result = await _orderHistoryRepository.fetchActiveOrders();
    result.fold(
      (error) => emit(OrderHistoryError(
          message: error, activeFilter: OrderHistoryFilter.all)),
      (orders) {
        emit(OrderHistoryLoaded(
            orders: orders,
            groupedOrders: {},
            activeFilter: OrderHistoryFilter.all,
            expandedOrderIds: previousState?.expandedOrderIds ?? {},
            totalCount: orders.length));
      },
    );
  }

  Future<void> filterBy(OrderHistoryFilter filter) async {
    await fetchDriverOrderHistory();
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
    await fetchDriverOrderHistory();
  }
}
