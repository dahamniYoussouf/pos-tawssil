import 'dart:async';
import 'dart:developer' as dev;
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
  static const int _reconnectionAttempts = 5;
  static const Duration _reconnectionDelay = Duration(milliseconds: 1000);
  static const Duration _reconnectionDelayMax = Duration(milliseconds: 5000);
  static const Duration _connectionTimeout = Duration(seconds: 20);
  static const List<String> _knownEvents = <String>[
    'connect',
    'disconnect',
    'connect_error',
    'error',
    'reconnect_attempt',
    'reconnect_error',
    'new_delivery',
    'notification',
    'config_update',
    'driver_alert',
  ];

  NotificationService({
    TokenStorageService? tokenStorageService,
  }) : _tokenStorageService = tokenStorageService ?? locator<TokenStorageService>();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    dev.log('[NotificationService] connect() called', name: 'NotificationService');
    dev.log('[NotificationService] Current state: isConnecting=$_isConnecting, isConnected=$_isConnected', name: 'NotificationService');
    if (_isConnecting || _isConnected) {
      dev.log('[NotificationService] Already connecting or connected, skipping', name: 'NotificationService');
      return;
    }
    _isConnecting = true;
    dev.log('[NotificationService] Set _isConnecting=true', name: 'NotificationService');
    try {
      final token = await _tokenStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        dev.log('[NotificationService] No token available, aborting connection', name: 'NotificationService');
        _isConnecting = false;
        return;
      }
      dev.log('[NotificationService] Token retrieved successfully', name: 'NotificationService');
      if (_socket != null) {
        dev.log('[NotificationService] Existing socket found, disconnecting first', name: 'NotificationService');
        await disconnect();
      }
      dev.log('[NotificationService] Creating socket connection to: ${ApiConfig.socketUrl}', name: 'NotificationService');
      _socket = _buildSocket(token);
      _setupSocketListeners();
      dev.log('[NotificationService] Calling socket.connect()', name: 'NotificationService');
      _socket!.connect();
      await Future.delayed(const Duration(milliseconds: 100));
      dev.log('[NotificationService] Connection initiated, waiting for socket events', name: 'NotificationService');
    } catch (e, stackTrace) {
      dev.log('[NotificationService] Connection error: $e', name: 'NotificationService', error: e, stackTrace: stackTrace);
      _isConnecting = false;
      _isConnected = false;
      _notificationController.add({
        'type': 'error',
        'message': 'Connection error: ${e.toString()}',
      });
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) {
      dev.log('[NotificationService] _setupSocketListeners() called but socket is null', name: 'NotificationService');
      return;
    }
    dev.log('[NotificationService] Setting up socket listeners', name: 'NotificationService');
    _socket!.onConnect((_) {
      dev.log('[NotificationService] Socket connected', name: 'NotificationService');
      _handleConnectionChange(isConnected: true);
    });
    _socket!.onDisconnect((reason) {
      dev.log('[NotificationService] Socket disconnected. Reason: $reason', name: 'NotificationService');
      _handleConnectionChange(isConnected: false, reason: reason?.toString());
    });
    _socket!.onConnectError((error) {
      _handleSocketError('connect_error', error);
    });
    _socket!.onError((error) {
      _handleSocketError('error', error);
    });
    _socket!.onReconnectAttempt((attempt) {
      dev.log('[NotificationService] Reconnect attempt: $attempt', name: 'NotificationService');
    });
    _socket!.onReconnectError((error) {
      dev.log('[NotificationService] Reconnect error: $error', name: 'NotificationService', error: error);
    });
    _socket!.on('new_delivery', (data) {
      dev.log('[NotificationService] Received new_delivery event: $data', name: 'NotificationService');
      _handleNotification('new_delivery', data);
    });
    _socket!.on('notification', (data) {
      dev.log('[NotificationService] Received notification event: $data', name: 'NotificationService');
      _handleNotification('notification', data);
    });
    _socket!.on('config_update', (data) {
      dev.log('[NotificationService] Received config_update event: $data', name: 'NotificationService');
      _handleNotification('config_update', data);
    });
    _socket!.on('driver_alert', (data) {
      dev.log('[NotificationService] Received driver_alert event: $data', name: 'NotificationService');
      _handleNotification('driver_alert', data);
    });
    _socket!.onAny((event, data) {
      if (!_knownEvents.contains(event)) {
        dev.log('[NotificationService] Received unhandled event: $event, data: $data', name: 'NotificationService');
        _notificationController.add({
          'type': event,
          'data': data is Map<String, dynamic> ? data : {'raw': data},
        });
      }
    });
  }

  void _handleNotification(String eventType, dynamic data) {
    dev.log('[NotificationService] Handling notification: type=$eventType', name: 'NotificationService');
    if (data is Map<String, dynamic>) {
      dev.log('[NotificationService] Notification data: $data', name: 'NotificationService');
      _notificationController.add({
        'type': eventType,
        'data': data,
      });
    } else {
      dev.log('[NotificationService] Notification data (raw): $data', name: 'NotificationService');
      _notificationController.add({
        'type': eventType,
        'data': {'raw': data},
      });
    }
  }

  Future<void> disconnect() async {
    dev.log('[NotificationService] disconnect() called', name: 'NotificationService');
    dev.log('[NotificationService] Current state: isConnecting=$_isConnecting, isConnected=$_isConnected, socket=${_socket != null ? "exists" : "null"}', name: 'NotificationService');
    if (_socket != null) {
      dev.log('[NotificationService] Disconnecting and disposing socket', name: 'NotificationService');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      dev.log('[NotificationService] State updated: isConnected=false, isConnecting=false, socket=null', name: 'NotificationService');
    } else {
      dev.log('[NotificationService] No socket to disconnect', name: 'NotificationService');
    }
  }

  Future<void> reconnect() async {
    dev.log('[NotificationService] reconnect() called', name: 'NotificationService');
    await disconnect();
    await connect();
  }

  void dispose() {
    dev.log('[NotificationService] dispose() called', name: 'NotificationService');
    disconnect();
    _notificationController.close();
    dev.log('[NotificationService] Service disposed', name: 'NotificationService');
  }

  IO.Socket _buildSocket(String token) {
    final options = IO.OptionBuilder()
        .setTransports(<String>['websocket', 'polling'])
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(_reconnectionAttempts)
        .setReconnectionDelay(_reconnectionDelay.inMilliseconds)
        .setReconnectionDelayMax(_reconnectionDelayMax.inMilliseconds)
        .setTimeout(_connectionTimeout.inMilliseconds)
        .setAuth(<String, dynamic>{'token': token})
        .setQuery(<String, dynamic>{'token': token})
        .setExtraHeaders(<String, dynamic>{'Authorization': 'Bearer $token'})
        .build();
    return IO.io(ApiConfig.socketUrl, options);
  }

  void _handleConnectionChange({required bool isConnected, String? reason}) {
    _isConnected = isConnected;
    _isConnecting = false;
    dev.log('[NotificationService] State updated: isConnected=$isConnected, isConnecting=false, reason=${reason ?? "none"}', name: 'NotificationService');
    final payload = <String, dynamic>{
      'type': 'connection',
      'status': isConnected ? 'connected' : 'disconnected',
    };
    if (reason != null && reason.isNotEmpty) {
      payload['reason'] = reason;
    }
    _notificationController.add(payload);
    if (!isConnected && reason == 'io server disconnect') {
      dev.log('[NotificationService] Server forced disconnect detected, rebuilding socket', name: 'NotificationService');
      _socket?.connect();
    }
  }

  void _handleSocketError(String event, dynamic error) {
    final message = error?.toString() ?? 'Unknown error';
    dev.log('[NotificationService] Socket $event: $message', name: 'NotificationService', error: error);
    _isConnected = false;
    _isConnecting = false;
    _notificationController.add({
      'type': 'error',
      'source': event,
      'message': message,
    });
  }
}
