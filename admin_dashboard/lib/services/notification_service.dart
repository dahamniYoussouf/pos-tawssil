import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  io.Socket? _socket;
  bool _isInitialized = false;
  bool _fcmInitialized = false;
  String? _fcmToken;
  Function(Map<String, dynamic>)? onNotificationReceived;

  // Getter pour vérifier si le socket est connecté
  bool get isSocketConnected => _socket?.connected ?? false;

  // Initialiser le service de notifications
  Future<void> init() async {
    if (_isInitialized) return;

    await _initFirebaseMessaging();

    // Initialiser les notifications locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander les permissions (Android 13+)
    await _requestPermissions();

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  Future<void> _initFirebaseMessaging() async {
    if (_fcmInitialized || kIsWeb) return;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );

      _fcmToken = await _messaging.getToken();
      await registerDeviceTokenIfPossible();

      FirebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        registerDeviceTokenIfPossible();
      });

      FirebaseMessaging.onMessage.listen((message) {
        _handleRemoteMessage(message, showLocal: true);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleRemoteMessage(message, showLocal: false);
      });

      _fcmInitialized = true;
      print('✅ Firebase messaging initialized');
    } catch (e) {
      print('❌ Firebase messaging init error: $e');
    }
  }

  // Demander les permissions
  Future<void> _requestPermissions() async {
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> registerDeviceTokenIfPossible() async {
    if (kIsWeb) return;
    if (_fcmToken == null || _fcmToken!.isEmpty) return;

    final authService = AuthService();
    await authService.init();
    if (!authService.isAuthenticated || authService.token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
        body: jsonEncode({
          'token': _fcmToken,
          'platform': _platformLabel(),
        }),
      ).timeout(AppConfig.networkTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Device token registered');
      } else {
        print('❌ Device token registration failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Device token registration error: $e');
    }
  }

  // Connecter au WebSocket pour les notifications
  Future<void> connectWebSocket() async {
    if (!kIsWeb) {
      print('⚠️ WebSocket disabled on mobile (FCM enabled)');
      return;
    }

    if (_socket != null && _socket!.connected) {
      print('⚠️ Socket already connected');
      return;
    }

    final authService = AuthService();
    if (!authService.isAuthenticated) {
      print('⚠️ Not authenticated, cannot connect WebSocket');
      return;
    }

    try {
      // Construire l'URL du socket
      final socketUrl = AppConfig.apiBaseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
      
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': authService.token})
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ Socket connected for notifications');
        _socket!.emit('join', 'admin');
        _socket!.emit('join', 'admins');
      });

      _socket!.onDisconnect((_) {
        print('⚠️ Socket disconnected');
      });

      _socket!.onConnectError((error) {
        print('❌ Socket connection error: $error');
      });

      // Écouter les nouvelles notifications
      _socket!.on('new_notification', (data) {
        print('🔔 New notification received: $data');
        _handleNotification(data, showLocal: true);
      });

      // Écouter les notifications admin spécifiques
      _socket!.on('admin_notification', (data) {
        print('🔔 Admin notification received: $data');
        _handleNotification(data, showLocal: true);
      });
    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
    }
  }

  // Déconnecter le WebSocket
  void disconnectWebSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      print('✅ WebSocket disconnected');
    }
  }

  // Gérer une notification reçue
  void _handleNotification(dynamic data, {bool showLocal = true}) {
    Map<String, dynamic> notification;
    if (data is Map) {
      notification = Map<String, dynamic>.from(data);
    } else if (data is String) {
      try {
        notification = jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Error parsing notification: $e');
        return;
      }
    } else {
      notification = {'message': data.toString()};
    }

    // Appeler le callback si fourni
    if (onNotificationReceived != null) {
      onNotificationReceived!(notification);
    }

    // Afficher une notification locale
    if (showLocal) {
      _showLocalNotification(notification);
    }
  }

  void _handleRemoteMessage(RemoteMessage message, {required bool showLocal}) {
    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;

    if (notification != null) {
      if (notification.title != null) {
        data['title'] = notification.title;
      }
      if (notification.body != null) {
        data['body'] = notification.body;
      }
    }

    _handleNotification(data, showLocal: showLocal);
  }

  // Afficher une notification locale
  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    final title = notification['title'] ?? 'Nouvelle Notification Admin 🚨';
    final body = notification['message'] ?? notification['body'] ?? 'Nouvelle notification';

    const androidDetails = AndroidNotificationDetails(
      'admin_notifications',
      'Notifications Admin',
      channelDescription: 'Notifications pour le tableau de bord admin',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    await _localNotifications.show(id, title, body, details);
  }

  // Gérer le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // Vous pouvez naviguer vers la page des notifications ici
  }

  // Créer le canal de notifications Android (à appeler avant d'afficher des notifications)
  Future<void> createNotificationChannel() async {
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      const channel = AndroidNotificationChannel(
        'admin_notifications',
        'Notifications Admin',
        description: 'Notifications pour le tableau de bord admin',
        importance: Importance.high,
      );
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
