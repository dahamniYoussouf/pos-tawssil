import 'dart:async';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:client_app/src/core/services/notification_service.dart';
import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import 'order_state.dart';

class OrderCubit extends HydratedCubit<OrderState> {
  final OrderService _orderService;
  final NotificationService _notificationService;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  String? _currentOrderId;

  OrderCubit({
    OrderService? orderService,
    NotificationService? notificationService,
  })  : _orderService = orderService ?? OrderService(),
        _notificationService = notificationService ?? locator<NotificationService>(),
        super(OrderInitial()) {
    _initializeNotificationListener();
  }

  /// Get current order ID
  String? get currentOrderId => _currentOrderId;

  /// Initialize notification listener
  void _initializeNotificationListener() {
    _notificationSubscription = _notificationService.notificationStream.listen(
      _handleNotification,
      onError: (error) {
        // Handle notification stream errors silently
      },
    );
  }

  /// Handle incoming notifications
  Future<void> _handleNotification(Map<String, dynamic> notification) async {
    if (isClosed) return;

    final String type = notification['type'] ?? '';
    final Map<String, dynamic> data = notification['data'] as Map<String, dynamic>? ?? {};

    // Only process order-related notifications if we have a current order
    if (_currentOrderId == null) return;

    // Extract order ID from notification data
    final String? notificationOrderId = data['orderId'] ?? data['order_id'] ?? data['_id'] ?? data['id'];

    // Only process if notification is for current order
    if (notificationOrderId != null && notificationOrderId == _currentOrderId) {
      switch (type) {
        case 'order_status_changed':
        case 'order_updated':
        case 'order_accepted':
        case 'order_refused':
        case 'driver_assigned':
        case 'driver_location_updated':
          // Refetch order data when status changes
          await _silentLoadOrder(_currentOrderId!);
          break;
      }
    }
  }

  /// Reset cubit state (useful when starting a new order tracking session)
  void reset() {
    if (isClosed) return;
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

  /// Load order silently without showing loading state (for real-time updates)
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
          return; // Don't emit error during silent updates
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
      // Silently fail during real-time updates - don't show errors for network issues
      // Only log if needed for debugging
    }
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
    _notificationSubscription?.cancel();
    return super.close();
  }

  /// Clear persisted order (called when order is collected)
  void clearPersistedOrder() {
    if (isClosed) return;
    _currentOrderId = null;
    emit(OrderInitial());
  }

  @override
  OrderState? fromJson(Map<String, dynamic> json) {
    try {
      final String? stateType = json['type'];
      
      // Don't persist temporary states
      if (stateType == null || 
          stateType == 'OrderLoading' || 
          stateType == 'OrderCreating' ||
          stateType == 'OrderError') {
        return null;
      }

      // Check if order is completed (delivered or collected)
      if (json['order'] != null) {
        final orderJson = json['order'] as Map<String, dynamic>;
        final String status = orderJson['status'] ?? '';
        
        // Clear persisted state if order is completed
        if (status == OrderStatus.delivered || status == OrderStatus.collected) {
          return null;
        }
      }

      // Restore persisted order state
      if (stateType == 'OrderLoaded' && json['order'] != null) {
        final order = OrderModel.fromJson(json['order'] as Map<String, dynamic>);
        _currentOrderId = order.id;
        return OrderLoaded(order: order);
      }
      
      if (stateType == 'OrderCreated' && json['order'] != null) {
        final order = OrderModel.fromJson(json['order'] as Map<String, dynamic>);
        _currentOrderId = order.id;
        return OrderCreated(order: order);
      }
      
      if (stateType == 'OrderRefused' && json['order'] != null) {
        final order = OrderModel.fromJson(json['order'] as Map<String, dynamic>);
        final reason = json['reason'] as String? ?? 'orderRefused';
        _currentOrderId = order.id;
        return OrderRefused(order: order, reason: reason);
      }
      
      if (stateType == 'OrderDelayed' && json['order'] != null) {
        final order = OrderModel.fromJson(json['order'] as Map<String, dynamic>);
        final reason = json['reason'] as String? ?? 'orderDelayed';
        _currentOrderId = order.id;
        return OrderDelayed(order: order, reason: reason);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(OrderState state) {
    try {
      // Don't persist temporary states
      if (state is OrderLoading || 
          state is OrderCreating || 
          state is OrderError ||
          state is OrderInitial) {
        return null;
      }

      // Persist active order states
      if (state is OrderLoaded) {
        // Don't persist if order is completed
        if (state.order.status == OrderStatus.delivered || 
            state.order.status == OrderStatus.collected) {
          return null;
        }
        return {
          'type': 'OrderLoaded',
          'order': _orderToJson(state.order),
        };
      }
      
      if (state is OrderCreated) {
        return {
          'type': 'OrderCreated',
          'order': _orderToJson(state.order),
        };
      }
      
      if (state is OrderRefused) {
        return {
          'type': 'OrderRefused',
          'order': _orderToJson(state.order),
          'reason': state.reason,
        };
      }
      
      if (state is OrderDelayed) {
        return {
          'type': 'OrderDelayed',
          'order': _orderToJson(state.order),
          'reason': state.reason,
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert OrderModel to JSON
  Map<String, dynamic> _orderToJson(OrderModel order) {
    return {
      'id': order.id,
      'orderNumber': order.orderNumber,
      'status': order.status,
      'totalPrice': order.totalPrice,
      'deliveryAddress': order.deliveryAddress,
      'restaurantName': order.restaurantName,
      'restaurantAddress': order.restaurantAddress,
      'restaurantImageUrl': order.restaurantImageUrl,
      'restaurantLatitude': order.restaurantLatitude,
      'restaurantLongitude': order.restaurantLongitude,
      'deliveryLatitude': order.deliveryLatitude,
      'deliveryLongitude': order.deliveryLongitude,
      'estimatedDeliveryTime': order.estimatedDeliveryTime?.toIso8601String(),
      'createdAt': order.createdAt?.toIso8601String(),
      'updatedAt': order.updatedAt?.toIso8601String(),
      'paymentMethod': order.paymentMethod,
      'refusalReason': order.refusalReason,
      'delayReason': order.delayReason,
      'orderType': order.orderType,
      'items': order.items.map((item) => {
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
      }).toList(),
      'deliveryPerson': order.deliveryPerson != null ? {
        'id': order.deliveryPerson!.id,
        'firstName': order.deliveryPerson!.firstName,
        'lastName': order.deliveryPerson!.lastName,
        'phoneNumber': order.deliveryPerson!.phoneNumber,
        'vehicleType': order.deliveryPerson!.vehicleType,
        'rating': order.deliveryPerson!.rating,
        'latitude': order.deliveryPerson!.latitude,
        'longitude': order.deliveryPerson!.longitude,
      } : null,
    };
  }
}
