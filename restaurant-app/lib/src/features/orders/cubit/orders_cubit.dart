import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_state.dart';
import 'package:restaurant_app/src/features/orders/repositories/order_repository.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrderRepository _orderRepository;

  OrdersCubit({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? locator<OrderRepository>(),
        super(const OrdersInitial());

  Future<void> fetchOrders({
    int page = 1,
    int limit = 20,
    String? status,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      emit(const OrdersLoading());
    }
    final result = await _orderRepository.fetchOrders(
      page: page,
      limit: limit,
      status: status,
    );
    result.fold(
      (error) => emit(OrdersError(message: error)),
      (orders) {
        if (loadMore && state is OrdersLoaded) {
          final currentState = state as OrdersLoaded;
          final updatedOrders = [...currentState.orders, ...orders];
          emit(OrdersLoaded(
            orders: updatedOrders,
            hasMore: orders.length >= limit,
            currentPage: page,
          ));
        } else {
          emit(OrdersLoaded(
            orders: orders,
            hasMore: orders.length >= limit,
            currentPage: page,
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
    emit(OrderActionLoading(orders: currentState.orders, orderId: orderId));
    final result = await _orderRepository.acceptOrder(orderId);
    result.fold(
      (error) => emit(OrderActionError(orders: currentState.orders, message: error)),
      (_) {
        final updatedOrders = currentState.orders.where((order) => order.id != orderId).toList();
        emit(OrderActionSuccess(orders: updatedOrders, message: 'Order accepted successfully'));
        emit(OrdersLoaded(
          orders: updatedOrders,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
        ));
      },
    );
  }

  Future<void> refuseOrder(String orderId, {String? reason}) async {
    if (state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    emit(OrderActionLoading(orders: currentState.orders, orderId: orderId));
    final result = await _orderRepository.refuseOrder(orderId, reason: reason);
    result.fold(
      (error) => emit(OrderActionError(orders: currentState.orders, message: error)),
      (_) {
        final updatedOrders = currentState.orders.where((order) => order.id != orderId).toList();
        emit(OrderActionSuccess(orders: updatedOrders, message: 'Order refused successfully'));
        emit(OrdersLoaded(
          orders: updatedOrders,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
        ));
      },
    );
  }

  void refreshOrders({String? status, int limit = 20}) {
    fetchOrders(page: 1, limit: limit, status: status);
  }
}

