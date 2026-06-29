import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_ventas/models/compra.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class CompraViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Compra> _compras = [];
  List<Compra> _comprasFiltradas = [];
  List<Proveedor> _proveedores = [];
  String _filtroEstado = 'todas';
  bool _isLoading = true;
  bool _disposed = false;
  String? _error;
  StreamSubscription? _subscription;
  StreamSubscription? _provSubscription;
  StreamSubscription? _authSub;

  List<Compra> get compras => _comprasFiltradas;
  List<Proveedor> get proveedores => _proveedores;
  String get filtroEstado => _filtroEstado;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalCompras => _compras.fold(0, (s, c) => s + c.total);

  double get totalPendiente =>
      _compras.where((c) => c.estado == 'pendiente').fold(0, (s, c) => s + c.total);

  CompraViewModel() {
    _subscribe();
    _subscribeProveedores();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _subscribe();
      _subscribeProveedores();
    });
  }

  void _safeNotify() {
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    }
  }

  void _subscribeProveedores() {
    _provSubscription?.cancel();
    _provSubscription = _firestore.getProveedores().listen((proveedores) {
      _proveedores = proveedores;
      _safeNotify();
    });
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
    _safeNotify();
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
      _safeNotify();
      return null;
    }
  }

  Future<String?> crearProductoDesdeCompra({
    required String nombre,
    required String categoria,
    required String unidad,
    required double costo,
    required double stock,
    double precioVenta = 0,
    String proveedorId = '',
    String proveedorNombre = '',
  }) async {
    try {
      final producto = Producto(
        id: '',
        nombre: nombre,
        categoria: categoria,
        stock: stock,
        costo: costo,
        presentaciones: [
          Presentacion(
            nombre: unidad,
            unidad: unidad,
            precio: precioVenta,
          ),
        ],
        proveedorId: proveedorId,
        proveedorNombre: proveedorNombre,
      );
      final id = await _firestore.addProducto(producto);
      return id;
    } catch (e) {
      _error = 'Error al crear producto desde compra';
      _safeNotify();
      return null;
    }
  }

  Future<String> crearProveedorSiNoExiste(String nombre) async {
    final existente = _proveedores.where(
      (p) => p.nombre.toLowerCase() == nombre.toLowerCase(),
    ).firstOrNull;
    if (existente != null) return existente.id;

    final nuevoId = await _firestore.addProveedor(Proveedor(
      id: '',
      nombre: nombre,
    ));
    return nuevoId;
  }

  Future<void> updateEstado(String id, String estado) async {
    try {
      await _firestore.updateCompraEstado(id, estado);
    } catch (e) {
      _error = 'Error al actualizar estado';
      _safeNotify();
    }
  }

  Future<void> deleteCompra(String id) async {
    try {
      await _firestore.deleteCompra(id);
    } catch (e) {
      _error = 'Error al eliminar compra';
      _safeNotify();
    }
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _provSubscription?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
