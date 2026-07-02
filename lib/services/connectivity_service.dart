import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _isOnline = true;
  bool _hasNetwork = true;

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen((_) => _checkConnectivity());
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _hasNetwork = results.any((r) => r != ConnectivityResult.none);

    if (!_hasNetwork) {
      _setOffline();
      return;
    }

    try {
      final result = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    } catch (_) {
      _setOffline();
    }
  }

  void _setOffline() {
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
