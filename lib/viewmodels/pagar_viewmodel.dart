import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class PagarViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Proveedor> _proveedores = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _subscription;

  List<Proveedor> get proveedoresConDeuda =>
      _proveedores.where((p) => p.saldoPendiente > 0).toList();
  double get totalPendiente =>
      _proveedores.fold(0, (s, p) => s + p.saldoPendiente);
  int get proveedoresPendientes =>
      _proveedores.where((p) => p.saldoPendiente > 0).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PagarViewModel() {
    _subscribe();
    FirebaseAuth.instance.authStateChanges().listen((_) => _subscribe());
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _firestore.getProveedores().listen((proveedores) {
      _proveedores = proveedores;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> registrarPago(String proveedorId, double monto) async {
    try {
      await _firestore.registrarPagoPagar(proveedorId, monto, 'Pago registrado');
    } catch (e) {
      _error = 'Error al registrar el pago';
      notifyListeners();
    }
  }

  Future<void> addProveedor(Proveedor p) async {
    try {
      await _firestore.addProveedor(p);
    } catch (e) {
      _error = 'Error al guardar proveedor';
      notifyListeners();
    }
  }

  Future<void> actualizarEstado(String id, String estado) async {
    try {
      await _firestore.actualizarEstadoProveedor(id, estado);
    } catch (e) {
      _error = 'Error al actualizar estado';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
