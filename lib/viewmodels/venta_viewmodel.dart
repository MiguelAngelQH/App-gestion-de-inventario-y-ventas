import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class VentaViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Venta> _ventas = [];
  List<Venta> _ventasFiltradas = [];
  String _filtroEstado = 'todas';
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _subscription;

  List<Venta> get ventas => _ventasFiltradas;
  String get filtroEstado => _filtroEstado;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalVentas =>
      _ventas.where((v) => v.estado == 'completada').fold(0, (s, v) => s + v.total);

  int get totalTransacciones => _ventas.length;

  VentaViewModel() {
    _subscribe();
    FirebaseAuth.instance.authStateChanges().listen((_) => _subscribe());
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _firestore.getVentas().listen((ventas) {
      _ventas = ventas
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      _isLoading = false;
      _filtrar();
    });
  }

  void _filtrar() {
    _ventasFiltradas = _ventas.where((v) {
      return _filtroEstado == 'todas' || v.estado == _filtroEstado;
    }).toList();
    notifyListeners();
  }

  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    _filtrar();
  }

  Future<String?> addVenta(Venta v) async {
    try {
      final id = await _firestore.addVenta(v);
      return id;
    } catch (e) {
      _error = 'Error al registrar la venta';
      notifyListeners();
      return null;
    }
  }

  Future<void> updateEstado(String id, String estado) async {
    try {
      await _firestore.updateVentaEstado(id, estado);
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
