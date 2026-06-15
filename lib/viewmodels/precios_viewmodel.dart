import 'dart:async';
import 'package:flutter/foundation.dart';
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
  StreamSubscription? _subscription;

  List<FlatPres> get flat => _flat;
  bool get isLoading => _isLoading;

  PreciosViewModel() {
    _subscribe();
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
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> actualizarPrecio(
      String productoId, String presentacionId, double nuevoPrecio) async {
    await _firestore.actualizarPrecioPresentacion(
        productoId, presentacionId, nuevoPrecio);
  }

  Future<void> actualizarCosto(
      String productoId, String presentacionId, double nuevoCosto) async {
    await _firestore.actualizarCostoPresentacion(
        productoId, presentacionId, nuevoCosto);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
