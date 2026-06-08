import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_ventas/services/firestore_service.dart';

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
    await _requestPermission();
    await _getToken();
    _listenForeground();
    _listenBackground();
    _listenTokenRefresh();
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

  Future<void> _requestPermission() async {
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
    if (_token != null) {
      await _guardarTokenEnFirestore();
    }
  }

  void _listenTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) {
      _token = newToken;
      onTokenChanged?.call(newToken);
      _guardarTokenEnFirestore();
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

  Future<void> _guardarTokenEnFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _token == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(user.uid)
          .set({'token': _token, 'email': user.email});
      if (kDebugMode) {
        debugPrint('FCM token guardado en Firestore para ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al guardar FCM token: $e');
      }
    }
  }

  /// Guarda (o actualiza) el token FCM del usuario actual en Firestore.
  /// Debe llamarse cada vez que el usuario inicia sesión.
  Future<void> guardarToken() async {
    _token = await _fcm.getToken();
    if (_token != null) {
      await _guardarTokenEnFirestore();
    }
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

  Future<void> checkAndNotify() async {
    final fs = FirestoreService();

    try {
      final stockBajo = await fs.productosStockBajoCount();
      if (stockBajo > 0) {
        await showLocalNotification(
          id: 1,
          title: 'Stock Bajo',
          body: '$stockBajo producto(s) necesitan reabastecerse',
        );
      }

      final cobrarVencer = await fs.clientesProximosVencer();
      if (cobrarVencer.isNotEmpty) {
        await showLocalNotification(
          id: 2,
          title: 'Cuentas por Cobrar Próximas a Vencer',
          body:
              '${cobrarVencer.length} cliente(s) tienen pagos próximos a vencer',
        );
      }

      final pagarVencer = await fs.proveedoresProximosVencer();
      if (pagarVencer.isNotEmpty) {
        await showLocalNotification(
          id: 3,
          title: 'Cuentas por Pagar Pendientes',
          body:
              '${pagarVencer.length} proveedor(es) tienen saldos pendientes',
        );
      }
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    debugPrint('Background notification: ${message.notification?.title}');
  }
}
