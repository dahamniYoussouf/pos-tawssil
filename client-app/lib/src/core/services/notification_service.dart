import 'dart:async';
import 'dart:developer' as dev;
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/services/base_api_service.dart';
import 'package:client_app/src/core/services/token_storage_service.dart';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log(
    '[NotificationService] Background notification received: ${message.messageId}',
    name: 'NotificationService',
  );
}

class NotificationService {
  final TokenStorageService _tokenStorageService;
  final BaseApiService _baseApiService;
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isLocalNotificationsInitialized = false;
  String? _lastKnownUserId;
  static const List<String> _knownEventTypes = <String>[
    'order_status_changed',
    'order_updated',
    'order_accepted',
    'order_refused',
    'order_cancelled',
    'order_created',
    'order_preparing',
    'driver_assigned',
    'driver_location_updated',
    'notification',
  ];
  static const String _defaultEventType = 'notification';
  static const String _channelId = 'tawsil_client_notifications';
  static const String _channelName = 'Order Notifications';
  static const String _channelDescription =
      'Real-time order status and delivery notifications';

  NotificationService({
    TokenStorageService? tokenStorageService,
    BaseApiService? baseApiService,
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  })  : _tokenStorageService =
            tokenStorageService ?? locator<TokenStorageService>(),
        _baseApiService = baseApiService ?? BaseApiService(),
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotificationsPlugin =
            localNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect({String? userId}) async {
    dev.log('[NotificationService] connect() called',
        name: 'NotificationService');
    dev.log(
        '[NotificationService] Current state: isConnecting=$_isConnecting, isConnected=$_isConnected',
        name: 'NotificationService');
    if (_isConnecting || _isConnected) {
      dev.log('[NotificationService] Already connecting or connected, skipping',
          name: 'NotificationService');
      return;
    }
    _isConnecting = true;
    dev.log('[NotificationService] Set _isConnecting=true',
        name: 'NotificationService');
    try {
      _lastKnownUserId = userId ?? _lastKnownUserId;
      final token = await _tokenStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        dev.log('[NotificationService] No token available, aborting connection',
            name: 'NotificationService');
        _isConnecting = false;
        return;
      }
      dev.log('[NotificationService] Auth token retrieved successfully',
          name: 'NotificationService');
      await _initializeForegroundNotifications();
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      dev.log(
        '[NotificationService] Notification permission status: ${settings.authorizationStatus.name}',
        name: 'NotificationService',
      );
      await _cancelFirebaseSubscriptions();
      _onMessageSubscription = FirebaseMessaging.onMessage.listen(
        (message) => _handleRemoteMessage(message, showLocalNotification: true),
      );
      _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleRemoteMessage(message, showLocalNotification: false),
      );
      _onTokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(
        (fcmToken) => _registerDeviceToken(fcmToken),
      );
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage, showLocalNotification: false);
      }
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _registerDeviceToken(fcmToken);
      } else {
        dev.log('[NotificationService] FCM token is null/empty',
            name: 'NotificationService');
      }
      _handleConnectionChange(isConnected: true);
    } catch (e, stackTrace) {
      dev.log('[NotificationService] Connection error: $e',
          name: 'NotificationService', error: e, stackTrace: stackTrace);
      _isConnecting = false;
      _isConnected = false;
      _notificationController.add({
        'type': 'error',
        'message': 'Connection error: ${e.toString()}',
      });
    }
  }

  void _handleRemoteMessage(
    RemoteMessage message, {
    required bool showLocalNotification,
  }) {
    final data = _normalizeMessageData(message);
    final eventType = _resolveEventType(data);
    dev.log(
        '[NotificationService] Handling FCM event: type=$eventType, data=$data',
        name: 'NotificationService');
    if (showLocalNotification) {
      unawaited(_showLocalNotification(message, data));
    }
    _notificationController.add({
      'type': eventType,
      'data': data,
    });
  }

  Future<void> disconnect() async {
    dev.log('[NotificationService] disconnect() called',
        name: 'NotificationService');
    dev.log(
        '[NotificationService] Current state: isConnecting=$_isConnecting, isConnected=$_isConnected',
        name: 'NotificationService');
    await _cancelFirebaseSubscriptions();
    _isConnected = false;
    _isConnecting = false;
    _notificationController.add({
      'type': 'connection',
      'status': 'disconnected',
    });
    dev.log('[NotificationService] Firebase listeners disconnected',
        name: 'NotificationService');
  }

  Future<void> reconnect() async {
    dev.log('[NotificationService] reconnect() called',
        name: 'NotificationService');
    await disconnect();
    await connect(userId: _lastKnownUserId);
  }

  void dispose() {
    dev.log('[NotificationService] dispose() called',
        name: 'NotificationService');
    unawaited(disconnect());
    _notificationController.close();
    dev.log('[NotificationService] Service disposed',
        name: 'NotificationService');
  }

  Future<void> _cancelFirebaseSubscriptions() async {
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
    _onMessageSubscription = null;
    _onMessageOpenedSubscription = null;
    _onTokenRefreshSubscription = null;
  }

  Future<void> _initializeForegroundNotifications() async {
    if (_isLocalNotificationsInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotificationsPlugin.initialize(settings);
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _isLocalNotificationsInitialized = true;
  }

  Future<void> _showLocalNotification(
    RemoteMessage message,
    Map<String, dynamic> payload,
  ) async {
    final title =
        message.notification?.title ?? payload['title']?.toString() ?? 'Tawsil';
    final body = message.notification?.body ??
        payload['body']?.toString() ??
        'You have a new update.';
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: ColorApp.primary,
      colorized: true,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload.toString(),
    );
  }

  Future<void> _registerDeviceToken(String fcmToken) async {
    final userId = _lastKnownUserId ?? 'unknown';
    final platform = _resolvePlatform();
    final response = await _baseApiService.postRequest(
      '/notifications/token',
      data: <String, dynamic>{
        'token': fcmToken,
        'platform': platform,
        'device_id': '$platform-client-$userId',
      },
    );
    final success = response['success'] == true || response['status'] == 200;
    if (!success) {
      dev.log(
        '[NotificationService] Failed to register notification token: ${response['message']}',
        name: 'NotificationService',
      );
    }
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'mobile';
    }
  }

  Map<String, dynamic> _normalizeMessageData(RemoteMessage message) {
    final data = <String, dynamic>{};
    for (final entry in message.data.entries) {
      data[entry.key] = entry.value;
    }
    if (message.notification?.title != null && data['title'] == null) {
      data['title'] = message.notification!.title;
    }
    if (message.notification?.body != null && data['body'] == null) {
      data['body'] = message.notification!.body;
    }
    return data;
  }

  String _resolveEventType(Map<String, dynamic> data) {
    final rawType = data['event_type']?.toString() ??
        data['event']?.toString() ??
        data['type']?.toString();
    if (rawType == null || rawType.isEmpty) {
      return _defaultEventType;
    }
    if (_knownEventTypes.contains(rawType)) {
      return rawType;
    }
    if (rawType == 'order_status_changed' || rawType == 'order_status_update') {
      data['type'] = rawType;
      return 'order_status_changed';
    }
    return _defaultEventType;
  }

  void _handleConnectionChange({required bool isConnected, String? reason}) {
    _isConnected = isConnected;
    _isConnecting = false;
    dev.log(
        '[NotificationService] State updated: isConnected=$isConnected, isConnecting=false, reason=${reason ?? "none"}',
        name: 'NotificationService');
    final payload = <String, dynamic>{
      'type': 'connection',
      'status': isConnected ? 'connected' : 'disconnected',
    };
    if (reason != null && reason.isNotEmpty) {
      payload['reason'] = reason;
    }
    _notificationController.add(payload);
  }
}
