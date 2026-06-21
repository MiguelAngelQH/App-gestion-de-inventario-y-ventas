import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class ProductoViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  List<Proveedor> _proveedores = [];
  String _busqueda = '';
  String _categoriaSeleccionada = 'Todas';
  bool _soloStockBajo = false;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _subscription;
  StreamSubscription? _provSubscription;

  List<Producto> get productos => _soloStockBajo
      ? _productosFiltrados.where((p) => p.stockBajo).toList()
      : _productosFiltrados;
  List<Proveedor> get proveedores => _proveedores;
  String get busqueda => _busqueda;
  String get categoriaSeleccionada => _categoriaSeleccionada;
  bool get soloStockBajo => _soloStockBajo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categorias =>
      ['Todas', ..._productos.map((p) => p.categoria).toSet()];

  ProductoViewModel() {
    _subscribe();
    _subscribeProveedores();
    FirebaseAuth.instance.authStateChanges().listen((_) {
      _subscribe();
      _subscribeProveedores();
    });
  }

  void _subscribeProveedores() {
    _provSubscription?.cancel();
    _provSubscription = _firestore.getProveedores().listen((proveedores) {
      _proveedores = proveedores;
      notifyListeners();
    });
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _firestore.getProductos().listen((productos) {
      _productos = productos;
      _isLoading = false;
      _error = null;
      _filtrar();
    }, onError: (e) {
      _error = 'Error al cargar productos: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  void _filtrar() {
    _productosFiltrados = _productos.where((p) {
      final coincideBusqueda = _busqueda.isEmpty ||
          p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          p.codigoBarras.toLowerCase().contains(_busqueda.toLowerCase()) ||
          p.marca.toLowerCase().contains(_busqueda.toLowerCase());
      final coincideCategoria = _categoriaSeleccionada == 'Todas' ||
          p.categoria == _categoriaSeleccionada;
      return coincideBusqueda && coincideCategoria;
    }).toList();
    notifyListeners();
  }

  void setBusqueda(String busqueda) {
    _busqueda = busqueda;
    _filtrar();
  }

  void setCategoria(String categoria) {
    _categoriaSeleccionada = categoria;
    _filtrar();
  }

  void setSoloStockBajo(bool value) {
    _soloStockBajo = value;
    notifyListeners();
  }

  Future<void> addProducto(Producto p) async {
    try {
      await _firestore.addProducto(p);
    } catch (e) {
      _error = 'Error al guardar producto';
      notifyListeners();
    }
  }

  Future<void> updateProducto(Producto p) async {
    try {
      await _firestore.updateProducto(p);
    } catch (e) {
      _error = 'Error al actualizar producto';
      notifyListeners();
    }
  }

  Future<void> deleteProducto(String id) async {
    try {
      await _firestore.deleteProducto(id);
    } catch (e) {
      _error = 'Error al eliminar producto';
      notifyListeners();
    }
  }

  Future<Producto?> getProductoByBarcode(String codigo) async {
    try {
      return await _firestore.getProductoByBarcode(codigo);
    } catch (_) {
      return null;
    }
  }

  String proveedorNombre(String id) =>
      _proveedores.where((p) => p.id == id).firstOrNull?.nombre ?? '';

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _provSubscription?.cancel();
    super.dispose();
  }
}
