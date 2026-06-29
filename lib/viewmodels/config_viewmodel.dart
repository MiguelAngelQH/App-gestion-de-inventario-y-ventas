import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class ConfigViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  String _businessName = 'Mi Tienda';
  String _address = '';
  String _phone = '';
  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;
  bool _disposed = false;
  StreamSubscription? _authSub;

  VoidCallback? onThemeChanged;

  String get businessName => _businessName;
  String get address => _address;
  String get phone => _phone;
  bool get notificationsEnabled => _notificationsEnabled;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  ConfigViewModel() {
    _load();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _load();
    });
  }

  void _safeNotify() {
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    }
  }

  Future<void> _load() async {
    try {
      final data = await _firestore.getConfig();
      _businessName = data['businessName'] as String? ?? 'Mi Tienda';
      _address = data['address'] as String? ?? '';
      _phone = data['phone'] as String? ?? '';
      _notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
      final themeStr = data['themeMode'] as String?;
      _themeMode = switch (themeStr) {
        'dark' => ThemeMode.dark,
        _ => ThemeMode.light,
      };
    } catch (_) {}
    _isLoading = false;
    _safeNotify();
  }

  Future<void> setBusinessName(String v) async {
    _businessName = v;
    _safeNotify();
    await _firestore.updateConfig({'businessName': v});
  }

  Future<void> setAddress(String v) async {
    _address = v;
    _safeNotify();
    await _firestore.updateConfig({'address': v});
  }

  Future<void> setPhone(String v) async {
    _phone = v;
    _safeNotify();
    await _firestore.updateConfig({'phone': v});
  }

  Future<void> setNotificationsEnabled(bool v) async {
    _notificationsEnabled = v;
    _safeNotify();
    await _firestore.updateConfig({'notificationsEnabled': v});
  }

  Future<void> setThemeMode(ThemeMode v) async {
    _themeMode = v;
    _safeNotify();
    onThemeChanged?.call();
    final str = v == ThemeMode.dark ? 'dark' : 'light';
    await _firestore.updateConfig({'themeMode': str});
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    super.dispose();
  }
}
