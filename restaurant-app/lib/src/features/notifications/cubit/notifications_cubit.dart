import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/notifications/cubit/notifications_state.dart';
import 'package:restaurant_app/src/features/notifications/services/notification_service.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationService _notificationService;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  NotificationsCubit({
    NotificationService? notificationService,
  })  : _notificationService = notificationService ?? locator<NotificationService>(),
        super(const NotificationsInitial()) {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = _notificationService.notificationStream.listen(
      _handleNotification,
      onError: (error) {
        emit(NotificationsError(message: error.toString()));
      },
    );
  }

  Future<void> connect() async {
    emit(const NotificationsConnecting());
    try {
      await _notificationService.connect();
      if (_notificationService.isConnected) {
        emit(const NotificationsConnected());
      } else {
        emit(const NotificationsDisconnected());
      }
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  Future<void> disconnect() async {
    try {
      await _notificationService.disconnect();
      emit(const NotificationsDisconnected());
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  Future<void> reconnect() async {
    emit(const NotificationsConnecting());
    try {
      await _notificationService.reconnect();
      if (_notificationService.isConnected) {
        emit(const NotificationsConnected());
      } else {
        emit(const NotificationsDisconnected());
      }
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  void _handleNotification(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    if (type == null) return;
    switch (type) {
      case 'connection':
        final status = notification['status'] as String?;
        if (status == 'connected') {
          emit(const NotificationsConnected());
        } else if (status == 'disconnected') {
          emit(const NotificationsDisconnected());
        }
        break;
      case 'error':
        final message = notification['message'] as String? ?? 'Unknown error';
        emit(NotificationsError(message: message));
        break;
      case 'new_order':
      case 'order_updated':
      case 'order_cancelled':
      case 'order_status_changed':
        emit(NotificationReceived(
          eventType: type,
          data: notification['data'] as Map<String, dynamic>? ?? {},
        ));
        break;
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _notificationService.dispose();
    return super.close();
  }
}
