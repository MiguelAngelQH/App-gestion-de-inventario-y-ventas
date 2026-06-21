import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/compra.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class CompraViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Compra> _compras = [];
  List<Compra> _comprasFiltradas = [];
  String _filtroEstado = 'todas';
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _subscription;

  List<Compra> get compras => _comprasFiltradas;
  String get filtroEstado => _filtroEstado;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalCompras => _compras.fold(0, (s, c) => s + c.total);

  double get totalPendiente =>
      _compras.where((c) => c.estado == 'pendiente').fold(0, (s, c) => s + c.total);

  CompraViewModel() {
    _subscribe();
    FirebaseAuth.instance.authStateChanges().listen((_) => _subscribe());
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _firestore.getCompras().listen((compras) {
      _compras = compras
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      _isLoading = false;
      _filtrar();
    });
  }

  void _filtrar() {
    _comprasFiltradas = _compras.where((c) {
      return _filtroEstado == 'todas' || c.estado == _filtroEstado;
    }).toList();
    notifyListeners();
  }

  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    _filtrar();
  }

  Future<String?> addCompra(Compra c) async {
    try {
      final id = await _firestore.addCompra(c);
      return id;
    } catch (e) {
      _error = 'Error al registrar la compra';
      notifyListeners();
      return null;
    }
  }

  Future<void> updateEstado(String id, String estado) async {
    try {
      await _firestore.updateCompraEstado(id, estado);
    } catch (e) {
      _error = 'Error al actualizar estado';
      notifyListeners();
    }
  }

  Future<void> deleteCompra(String id) async {
    try {
      await _firestore.deleteCompra(id);
    } catch (e) {
      _error = 'Error al eliminar compra';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
