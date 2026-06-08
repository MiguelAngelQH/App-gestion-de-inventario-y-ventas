import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _token;
  String? get token => _token;
  void Function(String)? onTokenChanged;

  Future<void> init() async {
    await _initLocalNotifications();
    await _requestLocalNotificationPermission();
    await _requestFcmPermission();
    await _getToken();
    _listenForeground();
    _listenBackground();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {},
    );
  }

  Future<void> _requestLocalNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _requestFcmPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _getToken() async {
    _token = await _fcm.getToken();
    if (kDebugMode) {
      debugPrint('FCM Token: $_token');
    }
    _fcm.onTokenRefresh.listen((newToken) {
      _token = newToken;
      onTokenChanged?.call(newToken);
      if (kDebugMode) {
        debugPrint('FCM Token refreshed: $newToken');
      }
    });
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  void _listenBackground() {
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_ventas_channel',
          'SmartVentas',
          channelDescription: 'Notificaciones de SmartVentas',
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_ventas_channel',
          'SmartVentas',
          channelDescription: 'Notificaciones de SmartVentas',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    debugPrint('Background notification: ${message.notification?.title}');
  }
}
