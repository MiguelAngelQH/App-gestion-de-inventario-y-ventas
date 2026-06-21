import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/cliente.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class CobrarViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Cliente> _clientes = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _subscription;

  List<Cliente> get clientesConDeuda =>
      _clientes.where((c) => c.deuda > 0).toList();
  double get totalDeuda => _clientes.fold(0, (s, c) => s + c.deuda);
  int get clientesMorosos => _clientes.where((c) => c.deuda > 0).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CobrarViewModel() {
    _subscribe();
    FirebaseAuth.instance.authStateChanges().listen((_) => _subscribe());
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _firestore.getClientes().listen((clientes) {
      _clientes = clientes;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> registrarPago(String clienteId, double monto) async {
    try {
      await _firestore.registrarPagoCobrar(clienteId, monto, 'Pago registrado');
    } catch (e) {
      _error = 'Error al registrar el pago';
      notifyListeners();
    }
  }

  Future<void> addCliente(Cliente c) async {
    try {
      await _firestore.addCliente(c);
    } catch (e) {
      _error = 'Error al guardar cliente';
      notifyListeners();
    }
  }

  Future<void> actualizarEstado(String id, String estado) async {
    try {
      await _firestore.actualizarEstadoCliente(id, estado);
    } catch (e) {
      _error = 'Error al actualizar estado';
      notifyListeners();
    }
  }

  Future<void> updateCliente(Cliente c) async {
    try {
      await _firestore.updateCliente(c);
    } catch (e) {
      _error = 'Error al actualizar cliente';
      notifyListeners();
    }
  }

  Future<void> deleteCliente(String id) async {
    try {
      await _firestore.deleteCliente(id);
    } catch (e) {
      _error = 'Error al eliminar cliente';
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getPagosHistorial(String clienteId) async {
    return await _firestore.getPagosCobrar(clienteId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
