import 'dart:async';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/order_service.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderService _orderService;
  Timer? _pollingTimer;
  String? _currentOrderId;

  OrderCubit({
    OrderService? orderService,
  })  : _orderService = orderService ?? OrderService(),
        super(OrderInitial());

  /// Reset cubit state (useful when starting a new order tracking session)
  void reset() {
    if (isClosed) return;
    _stopPolling();
    _currentOrderId = null;
    emit(OrderInitial());
  }

  /// Fetch order by ID
  Future<void> fetchOrder(String orderId) async {
    if (isClosed) return;
    _currentOrderId = orderId;
    await _loadOrder(orderId);
  }

  /// Load order from API
  Future<void> _loadOrder(String orderId) async {
    if (isClosed) return;

    try {
      emit(OrderLoading());
      final response = await _orderService.getOrder(orderId);

      if (isClosed) return;

      if (response['success'] == true ||
          response['id'] != null ||
          response['_id'] != null) {
        final order = _orderService.parseOrder(response);

        if (order == null) {
          if (!isClosed) {
            emit(OrderError(message: 'errorOrderNotFound'));
          }
          return;
        }

        if (isClosed) return;

        // Check for special statuses
        if (order.isRefused) {
          emit(OrderRefused(
            order: order,
            reason: order.refusalReason ?? 'orderRefused',
          ));
        } else if (order.isDelayed) {
          emit(OrderDelayed(
            order: order,
            reason: order.delayReason ?? 'orderDelayed',
          ));
        } else {
          emit(OrderLoaded(order: order));
        }
      } else {
        if (!isClosed) {
          emit(OrderError(
            message: response['message'] ?? 'errorOrderLoadFailed',
          ));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(OrderError(message: 'errorOrderLoad|${e.toString()}'));
      }
    }
  }

  /// Start polling for order updates
  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    if (isClosed) return;

    _stopPolling(); // Stop any existing timer

    if (_currentOrderId == null) return;

    _pollingTimer = Timer.periodic(interval, (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      if (_currentOrderId != null) {
        _silentLoadOrder(_currentOrderId!);
      }
    });
  }

  /// Load order silently without showing loading state (for polling)
  Future<void> _silentLoadOrder(String orderId) async {
    if (isClosed) return;

    try {
      final response = await _orderService.getOrder(orderId);

      if (isClosed) return;

      if (response['success'] == true ||
          response['id'] != null ||
          response['_id'] != null) {
        final order = _orderService.parseOrder(response);

        if (order == null) {
          return; // Don't emit error during silent polling
        }

        if (isClosed) return;

        // Check for special statuses and emit appropriate state
        if (order.isRefused) {
          emit(OrderRefused(
            order: order,
            reason: order.refusalReason ?? 'orderRefused',
          ));
        } else if (order.isDelayed) {
          emit(OrderDelayed(
            order: order,
            reason: order.delayReason ?? 'orderDelayed',
          ));
        } else {
          emit(OrderLoaded(order: order));
        }
      }
    } catch (e) {
      // Silently fail during polling - don't show errors for network issues
      // Only log if needed for debugging
    }
  }

  /// Stop polling for order updates
  void stopPolling() {
    _stopPolling();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh order manually
  Future<void> refreshOrder() async {
    if (_currentOrderId != null) {
      await _loadOrder(_currentOrderId!);
    }
  }

  /// Create a new order
  Future<void> createOrder({
    required String restaurantId,
    required String orderType,
    required String deliveryAddress,
    required String lat,
    required String lng,
    required double deliveryFee,
    required String paymentMethod,
    String? deliveryInstructions,
    required List<Map<String, dynamic>> items,
  }) async {
    if (isClosed) return;

    try {
      emit(OrderCreating());
      final normalizedOrderType = _normalizeOrderType(orderType);
      final sanitizedItems = _sanitizeOrderItems(items);
      final response = await _orderService.createOrder(
        restaurantId: restaurantId,
        orderType: normalizedOrderType,
        deliveryAddress: deliveryAddress,
        lat: lat,
        lng: lng,
        deliveryFee: deliveryFee,
        paymentMethod: paymentMethod,
        deliveryInstructions: deliveryInstructions,
        items: sanitizedItems,
      );

      if (isClosed) return;

      if (response['success'] == true ||
          response['id'] != null ||
          response['_id'] != null) {
        // Clear cart after successful order creation
        locator<CartCubit>().clearCart();
        final order = _orderService.parseOrder(response);

        if (order == null) {
          if (!isClosed) {
            emit(OrderError(message: 'errorOrderCreationFailed'));
          }
          return;
        }

        if (isClosed) return;

        _currentOrderId = order.id;
        emit(OrderCreated(order: order));
      } else {
        if (!isClosed) {
          final errorMessage = _extractErrorMessage(response);
          emit(OrderError(message: errorMessage));
        }
      }
    } catch (e) {
      if (!isClosed) {
        final errorMessage = _extractErrorMessageFromException(e);
        emit(OrderError(message: errorMessage));
      }
    }
  }

  /// Normalize order type from short codes to API format
  String _normalizeOrderType(String orderType) {
    switch (orderType.toUpperCase()) {
      case 'DEL':
        return 'delivery';
      case 'PKP':
        return 'pickup';
      case 'DELIVERY':
        return 'delivery';
      case 'PICKUP':
        return 'pickup';
      default:
        return orderType.toLowerCase();
    }
  }

  /// Sanitize order items to ensure special_instructions is always a string
  List<Map<String, dynamic>> _sanitizeOrderItems(
      List<Map<String, dynamic>> items) {
    return items.map((item) {
      final sanitizedItem = Map<String, dynamic>.from(item);
      if (sanitizedItem['special_instructions'] == null) {
        sanitizedItem['special_instructions'] = '';
      } else {
        sanitizedItem['special_instructions'] =
            sanitizedItem['special_instructions'].toString();
      }
      return sanitizedItem;
    }).toList();
  }

  /// Extract error message from API response
  String _extractErrorMessage(Map<String, dynamic> response) {
    if (response['message'] != null) {
      return response['message'].toString();
    }
    if (response['errors'] != null && response['errors'] is List) {
      final errors = response['errors'] as List;
      if (errors.isNotEmpty) {
        final firstError = errors.first;
        if (firstError is Map && firstError['msg'] != null) {
          return firstError['msg'].toString();
        }
      }
    }
    return 'errorOrderCreationFailed';
  }

  /// Extract error message from exception
  String _extractErrorMessageFromException(dynamic exception) {
    if (exception is Map<String, dynamic>) {
      return _extractErrorMessage(exception);
    }
    return 'errorOrderCreation|${exception.toString()}';
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
