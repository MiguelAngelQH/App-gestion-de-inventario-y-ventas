import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  int _productosStockBajo = 0;
  int _ventasHoy = 0;
  double _totalVentasHoy = 0;
  double _totalVentasSemana = 0;
  double _gananciaTotal = 0;
  double _totalCuentasCobrar = 0;
  double _totalCuentasPagar = 0;
  List<Venta> _ultimasVentas = [];
  List<Producto> _topProductos = [];
  bool _isLoading = true;

  int get productosStockBajo => _productosStockBajo;
  int get ventasHoy => _ventasHoy;
  double get totalVentasHoy => _totalVentasHoy;
  double get totalVentasSemana => _totalVentasSemana;
  double get gananciaTotal => _gananciaTotal;
  double get totalCuentasCobrar => _totalCuentasCobrar;
  double get totalCuentasPagar => _totalCuentasPagar;
  List<Venta> get ultimasVentas => _ultimasVentas;
  List<Producto> get topProductos => _topProductos;
  bool get isLoading => _isLoading;

  StreamSubscription? _productosSub;
  StreamSubscription? _ventasSub;
  StreamSubscription? _clientesSub;
  StreamSubscription? _proveedoresSub;
  StreamSubscription? _authSub;

  DashboardViewModel() {
    _init();
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen((_) => _init());
  }

  @override
  void dispose() {
    _productosSub?.cancel();
    _ventasSub?.cancel();
    _clientesSub?.cancel();
    _proveedoresSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _init() {
    _isLoading = true;
    _notifyIfNeeded();

    _productosSub?.cancel();
    _ventasSub?.cancel();
    _clientesSub?.cancel();
    _proveedoresSub?.cancel();

    _productosSub = _firestore.getProductos().listen((productos) {
      _productosStockBajo = productos.where((p) => p.stockBajo).length;
      _isLoading = false;
      _notifyIfNeeded();
    }, onError: (_) {
      _isLoading = false;
      _notifyIfNeeded();
    });

    _ventasSub = _firestore.getVentas().listen((ventas) {
      _calcularMetricasVentas(ventas);
      _isLoading = false;
      _notifyIfNeeded();
    }, onError: (_) {
      _isLoading = false;
      _notifyIfNeeded();
    });

    _clientesSub = _firestore.getClientes().listen((clientes) {
      _totalCuentasCobrar =
          clientes.fold(0.0, (s, c) => s + c.deuda);
      _notifyIfNeeded();
    });

    _proveedoresSub = _firestore.getProveedores().listen((proveedores) {
      _totalCuentasPagar =
          proveedores.fold(0.0, (s, p) => s + p.saldoPendiente);
      _notifyIfNeeded();
    });
  }

  void _calcularMetricasVentas(List<Venta> ventas) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final inicioSemana = hoy.subtract(Duration(days: now.weekday - 1));

    final completadas = ventas.where((v) => v.estado == 'completada').toList();

    _ventasHoy = completadas.where((v) => v.fecha.isAfter(hoy)).length;
    _totalVentasHoy = completadas
        .where((v) => v.fecha.isAfter(hoy))
        .fold(0.0, (s, v) => s + v.total);
    _totalVentasSemana = completadas
        .where((v) => v.fecha.isAfter(inicioSemana))
        .fold(0.0, (s, v) => s + v.total);

    double ganancia = 0;
    for (final v in completadas) {
      double costoItems = 0;
      for (final item in v.items) {
        costoItems += item.producto.costo * item.cantidad;
      }
      ganancia += v.total - costoItems;
    }
    _gananciaTotal = ganancia;

    final sorted = List<Venta>.from(ventas)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    _ultimasVentas = sorted.take(5).toList();

    final conteo = <String, int>{};
    final productoMap = <String, Producto>{};
    for (final v in ventas) {
      for (final item in v.items) {
        conteo.update(
          item.producto.id,
          (c) => c + item.cantidad,
          ifAbsent: () => item.cantidad,
        );
        productoMap[item.producto.id] = item.producto;
      }
    }
    final sortedEntries = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topProductos = sortedEntries
        .take(5)
        .map((e) => productoMap[e.key]!)
        .toList();
  }

  void _notifyIfNeeded() {
    if (hasListeners) notifyListeners();
  }

  Future<void> refresh() async {
    _init();
  }
}
