import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:delivery_app/src/core/config/api_config.dart';
import 'package:delivery_app/src/core/services/token_storage_service.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';

class NotificationService {
  final TokenStorageService _tokenStorageService;
  IO.Socket? _socket;
  final StreamController<Map<String, dynamic>> _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  bool _isConnecting = false;

  NotificationService({
    TokenStorageService? tokenStorageService,
  }) : _tokenStorageService = tokenStorageService ?? locator<TokenStorageService>();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnecting || _isConnected) return;
    _isConnecting = true;
    try {
      final token = await _tokenStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }
      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder().setTransports(['websocket']).enableAutoConnect().setExtraHeaders({'Authorization': 'Bearer $token'}).build(),
      );
      _setupSocketListeners();
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;
    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      _notificationController.add({
        'type': 'connection',
        'status': 'connected',
      });
    });
    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      _notificationController.add({
        'type': 'connection',
        'status': 'disconnected',
      });
    });
    _socket!.onConnectError((error) {
      _isConnected = false;
      _isConnecting = false;
      _notificationController.add({
        'type': 'error',
        'message': error.toString(),
      });
    });
    _socket!.on('new_order', (data) {
      _handleNotification('new_order', data);
    });
    _socket!.on('order_updated', (data) {
      _handleNotification('order_updated', data);
    });
    _socket!.on('order_cancelled', (data) {
      _handleNotification('order_cancelled', data);
    });
    _socket!.on('order_status_changed', (data) {
      _handleNotification('order_status_changed', data);
    });
  }

  void _handleNotification(String eventType, dynamic data) {
    if (data is Map<String, dynamic>) {
      _notificationController.add({
        'type': eventType,
        'data': data,
      });
    } else {
      _notificationController.add({
        'type': eventType,
        'data': {'raw': data},
      });
    }
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
    }
  }

  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  void dispose() {
    disconnect();
    _notificationController.close();
  }
}
