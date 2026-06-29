import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class PagarViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Proveedor> _proveedores = [];
  bool _isLoading = true;
  bool _disposed = false;
  String? _error;
  StreamSubscription? _subscription;
  StreamSubscription? _authSub;

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
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen((_) => _subscribe());
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
    _subscription = _firestore.getProveedores().listen((proveedores) {
      _proveedores = proveedores;
      _isLoading = false;
      _safeNotify();
    });
  }

  Future<void> registrarPago(String proveedorId, double monto) async {
    try {
      await _firestore.registrarPagoPagar(proveedorId, monto, 'Pago registrado');
    } catch (e) {
      _error = 'Error al registrar el pago';
      _safeNotify();
    }
  }

  Future<void> addProveedor(Proveedor p) async {
    try {
      await _firestore.addProveedor(p);
    } catch (e) {
      _error = 'Error al guardar proveedor';
      _safeNotify();
    }
  }

  Future<void> actualizarEstado(String id, String estado) async {
    try {
      await _firestore.actualizarEstadoProveedor(id, estado);
    } catch (e) {
      _error = 'Error al actualizar estado';
      _safeNotify();
    }
  }

  Future<void> updateProveedor(Proveedor p) async {
    try {
      await _firestore.updateProveedor(p);
    } catch (e) {
      _error = 'Error al actualizar proveedor';
      _safeNotify();
    }
  }

  Future<void> deleteProveedor(String id) async {
    try {
      await _firestore.deleteProveedor(id);
    } catch (e) {
      _error = 'Error al eliminar proveedor';
      _safeNotify();
    }
  }

  Future<List<Map<String, dynamic>>> getPagosHistorial(String proveedorId) async {
    return await _firestore.getPagosPagar(proveedorId);
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
