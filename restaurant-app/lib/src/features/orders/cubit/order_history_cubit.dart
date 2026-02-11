import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/formatters.dart';
import 'package:restaurant_app/src/features/orders/cubit/order_history_state.dart';
import 'package:restaurant_app/src/features/orders/models/order_history_filters.dart';
import 'package:restaurant_app/src/features/orders/repositories/order_history_repository.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderHistoryRepository _repository;
  Timer? _searchDebounceTimer;

  OrderHistoryCubit({OrderHistoryRepository? repository})
      : _repository = repository ?? OrderHistoryRepository(),
        super(OrderHistoryInitial(
          filters: OrderHistoryFilters(),
        ));

  Future<void> fetchOrderHistory({
    bool loadMore = false,
    int limit = 50,
    bool applyFilter = false,
  }) async {
    final currentFilters = state.filters;
    final currentPage = loadMore && state is OrderHistoryLoaded
        ? (state as OrderHistoryLoaded).currentPage + 1
        : 1;

    // Only emit loading if not already loading and not loading more
    if (!loadMore && state is! OrderHistoryLoading) {
      emit(OrderHistoryLoading(filters: currentFilters));
    }

    final result = await _repository.fetchOrderHistory(
      status: currentFilters.status,
      orderType: currentFilters.orderType,
      dateFrom: currentFilters.dateFrom != null
          ? formatIsoDate(currentFilters.dateFrom!)
          : null,
      dateTo: currentFilters.dateTo != null
          ? formatIsoDate(currentFilters.dateTo!)
          : null,
      minPrice: currentFilters.minPrice,
      maxPrice: currentFilters.maxPrice,
      search: currentFilters.search,
      page: currentPage,
      limit: limit,
    );
    result.fold(
      (error) => emit(
        OrderHistoryError(message: error, filters: currentFilters),
      ),
      (orders) {
        if (loadMore && state is OrderHistoryLoaded && !applyFilter) {
          final currentState = state as OrderHistoryLoaded;
          // Prevent duplicates by filtering out orders that already exist
          final existingOrderIds =
              currentState.orders.map((order) => order.id).toSet();
          final newOrders = orders
              .where((order) => !existingOrderIds.contains(order.id))
              .toList();
          final updatedOrders = [...currentState.orders, ...newOrders];
          emit(currentState.copyWith(
            orders: updatedOrders,
            hasMore: orders.length >= limit,
            currentPage: currentPage,
            filters: currentFilters,
          ));
        } else if (state is OrderHistoryLoaded && !applyFilter) {
          // Update existing loaded state with new orders
          final currentState = state as OrderHistoryLoaded;
          emit(currentState.copyWith(
            orders: orders,
            hasMore: orders.length >= limit,
            currentPage: currentPage,
            filters: currentFilters,
          ));
        } else {
          // Create new loaded state (for initial load or when applying filters)
          emit(OrderHistoryLoaded(
            orders: orders,
            hasMore: orders.length >= limit,
            currentPage: applyFilter ? 1 : currentPage,
            filters: currentFilters,
          ));
        }
      },
    );
  }

  Future<void> loadMoreOrders({int limit = 50}) async {
    if (state is! OrderHistoryLoaded) return;
    final currentState = state as OrderHistoryLoaded;
    if (!currentState.hasMore) return;
    await fetchOrderHistory(loadMore: true, limit: limit);
  }

  // Update filters in state without fetching - used while user is adjusting filters
  void updateFiltersOnly(OrderHistoryFilters filters) {
    // Update filters in current state without triggering fetch
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;
      emit(currentState.copyWith(filters: filters));
    } else if (state is OrderHistoryLoading) {
      emit(OrderHistoryLoading(filters: filters));
    } else if (state is OrderHistoryError) {
      final errorState = state as OrderHistoryError;
      emit(OrderHistoryError(message: errorState.message, filters: filters));
    } else {
      // Initial state or other states
      emit(OrderHistoryInitial(filters: filters));
    }
  }

  // Apply filters and fetch data - called when user clicks Apply or Reset
  Future<void> applyFilters(OrderHistoryFilters filters) async {
    // Emit loading state with new filters, then fetch
    emit(OrderHistoryLoading(filters: filters));
    await fetchOrderHistory(applyFilter: true);
  }

  Future<void> updateFilters(OrderHistoryFilters filters) async {
    // Emit loading state with new filters, then fetch
    // fetchOrderHistory will read state.filters which will be the new filters
    emit(OrderHistoryLoading(filters: filters));
    await refresh();
  }

  // Methods that only update filters without fetching (used in filters widget)
  void setSearchOnly(String? search) {
    final updatedFilters = state.filters.copyWith(search: search);
    updateFiltersOnly(updatedFilters);
  }

  void setStatusOnly(List<String>? status) {
    final updatedFilters = state.filters.copyWith(status: status);
    updateFiltersOnly(updatedFilters);
  }

  void setDateRangeOnly(DateTime? dateFrom, DateTime? dateTo) {
    final updatedFilters = state.filters.copyWith(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    updateFiltersOnly(updatedFilters);
  }

  void setPriceRangeOnly(double? minPrice, double? maxPrice) {
    final updatedFilters = state.filters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    updateFiltersOnly(updatedFilters);
  }

  void setOrderTypeOnly(String? orderType) {
    final updatedFilters = state.filters.copyWith(orderType: orderType);
    updateFiltersOnly(updatedFilters);
  }

  Future<void> setSearch(String? search) async {
    // Cancel any existing debounce timer
    _searchDebounceTimer?.cancel();

    // Update filters immediately (for UI feedback)
    final updatedFilters = state.filters.copyWith(search: search);
    updateFiltersOnly(updatedFilters);

    // Set up debounce timer to delay the actual fetch
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await updateFilters(updatedFilters);
    });
  }

  Future<void> setStatus(List<String>? status) async {
    final updatedFilters = state.filters.copyWith(status: status);
    await updateFilters(updatedFilters);
  }

  Future<void> setDateRange(DateTime? dateFrom, DateTime? dateTo) async {
    final updatedFilters = state.filters.copyWith(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    await updateFilters(updatedFilters);
  }

  Future<void> setPriceRange(double? minPrice, double? maxPrice) async {
    final updatedFilters = state.filters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    await updateFilters(updatedFilters);
  }

  Future<void> setOrderType(String? orderType) async {
    final updatedFilters = state.filters.copyWith(orderType: orderType);
    await updateFilters(updatedFilters);
  }

  Future<void> clearFilters() async {
    final clearedFilters = OrderHistoryFilters();
    await applyFilters(clearedFilters);
  }

  Future<void> refresh() async {
    await fetchOrderHistory();
  }

  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
  }
}
