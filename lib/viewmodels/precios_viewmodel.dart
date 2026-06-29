import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class FlatPres {
  final Producto producto;
  final Presentacion presentacion;
  FlatPres(this.producto, this.presentacion);
}

class PreciosViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<FlatPres> _flat = [];
  bool _isLoading = true;
  bool _disposed = false;
  StreamSubscription? _subscription;
  StreamSubscription? _authSub;

  List<FlatPres> get flat => _flat;
  bool get isLoading => _isLoading;

  PreciosViewModel() {
    _subscribe();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _subscribe();
    });
  }

  void _safeNotify() {
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _firestore.getProductos().listen((productos) {
      final nueva = <FlatPres>[];
      for (final p in productos) {
        for (final pr in p.presentaciones) {
          nueva.add(FlatPres(p, pr));
        }
      }
      _flat = nueva;
      _isLoading = false;
      _safeNotify();
    }, onError: (_) {
      _isLoading = false;
      _safeNotify();
    });
  }

  Future<void> actualizarPrecio(
      String productoId, String presentacionId, double nuevoPrecio) async {
    await _firestore.actualizarPrecioPresentacion(
        productoId, presentacionId, nuevoPrecio);
  }

  Future<void> actualizarCosto(
      String productoId, double nuevoCosto) async {
    await _firestore.actualizarCostoProducto(productoId, nuevoCosto);
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
