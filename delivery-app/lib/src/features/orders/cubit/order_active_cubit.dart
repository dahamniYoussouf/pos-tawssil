import 'package:delivery_app/src/features/orders/cubit/order_active_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../repositories/order_history_repository.dart';
import '../models/order_model.dart';

class OrderActiveCubit extends Cubit<OrderActiveState> {
  final OrderHistoryRepository _orderHistoryRepository;

  OrderActiveCubit({
    OrderHistoryRepository? orderHistoryRepository,
  })  : _orderHistoryRepository =
            orderHistoryRepository ?? OrderHistoryRepository(),
        super(const OrderActiveInitial());

  Future<void> fetchActiveOrders() async {
    final previousState =
        state is OrderActiveLoaded ? state as OrderActiveLoaded : null;
    final result = await _orderHistoryRepository.fetchActiveOrders();
    result.fold(
      (error) => emit(OrderActiveError(message: error)),
      (orders) {
        final grouped = _groupOrdersByDate(orders);
        emit(OrderActiveLoaded(
            orders: orders,
            groupedOrders: grouped,
            expandedOrderIds: previousState?.expandedOrderIds ?? {},
            totalCount: orders.length));
      },
    );
  }

  void toggleOrderExpansion(String orderId) {
    if (state is OrderActiveLoaded) {
      final currentState = state as OrderActiveLoaded;
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

  Future<void> refreshOrderActive() async {
    await fetchActiveOrders();
  }
}
