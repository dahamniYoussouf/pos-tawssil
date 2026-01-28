import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_history_state.dart';
import '../repositories/order_history_repository.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderHistoryRepository _orderHistoryRepository;

  OrderHistoryCubit({
    OrderHistoryRepository? orderHistoryRepository,
  })  : _orderHistoryRepository =
            orderHistoryRepository ?? OrderHistoryRepository(),
        super(OrderHistoryInitial());

  Future<void> fetchOrderHistory({
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
    emit(OrderHistoryLoading());

    final result = await _orderHistoryRepository.fetchOrderHistory(
      status: status,
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
      (error) => emit(OrderHistoryError(message: error)),
      (orders) => emit(
        OrderHistoryLoaded(
          orders: orders,
          totalCount: orders.length,
        ),
      ),
    );
  }

  Future<void> refreshOrderHistory() async {
    await fetchOrderHistory();
  }
}
