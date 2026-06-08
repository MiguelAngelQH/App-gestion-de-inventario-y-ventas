import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/services/firestore_service.dart';

class ReporteViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  double _ventasMes = 0;
  double _ventasSemana = 0;
  double _ventasHoy = 0;
  double _gananciaTotal = 0;
  double _cuentasCobrar = 0;
  double _cuentasPagar = 0;
  double _egresosMes = 0;
  Map<String, double> _ventasPorCategoria = {};
  Map<DateTime, double> _ventasUltimos7Dias = {};
  List<Producto> _topProductos = [];
  bool _isLoading = true;

  double get ventasMes => _ventasMes;
  double get ventasSemana => _ventasSemana;
  double get ventasHoy => _ventasHoy;
  double get gananciaTotal => _gananciaTotal;
  double get cuentasCobrar => _cuentasCobrar;
  double get cuentasPagar => _cuentasPagar;
  double get egresosMes => _egresosMes;
  double get ingresoNeto => ventasMes - egresosMes;
  Map<String, double> get ventasPorCategoria => _ventasPorCategoria;
  Map<DateTime, double> get ventasUltimos7Dias => _ventasUltimos7Dias;
  List<Producto> get topProductos => _topProductos;
  bool get isLoading => _isLoading;

  StreamSubscription? _ventasSub;
  StreamSubscription? _comprasSub;
  StreamSubscription? _clientesSub;
  StreamSubscription? _proveedoresSub;
  StreamSubscription? _authSub;

  ReporteViewModel() {
    _init();
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen((_) => _init());
  }

  @override
  void dispose() {
    _ventasSub?.cancel();
    _comprasSub?.cancel();
    _clientesSub?.cancel();
    _proveedoresSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _init() {
    _isLoading = true;
    _notifyIfNeeded();

    _ventasSub?.cancel();
    _comprasSub?.cancel();
    _clientesSub?.cancel();
    _proveedoresSub?.cancel();

    _ventasSub = _firestore.getVentas().listen((ventas) {
      _calcularMetricasVentas(ventas);
      _isLoading = false;
      _notifyIfNeeded();
    }, onError: (_) {
      _isLoading = false;
      _notifyIfNeeded();
    });

    _comprasSub = _firestore.getCompras().listen((compras) {
      final now = DateTime.now();
      final inicioMes = DateTime(now.year, now.month, 1);
      _egresosMes = compras
          .where((c) => c.fecha.isAfter(inicioMes))
          .fold(0.0, (s, c) => s + c.total);
      _isLoading = false;
      _notifyIfNeeded();
    }, onError: (_) {
      _isLoading = false;
      _notifyIfNeeded();
    });

    _clientesSub = _firestore.getClientes().listen((clientes) {
      _cuentasCobrar =
          clientes.fold(0.0, (s, c) => s + c.deuda);
      _notifyIfNeeded();
    });

    _proveedoresSub = _firestore.getProveedores().listen((proveedores) {
      _cuentasPagar =
          proveedores.fold(0.0, (s, p) => s + p.saldoPendiente);
      _notifyIfNeeded();
    });
  }

  void _calcularMetricasVentas(List ventas) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final inicioSemana = hoy.subtract(Duration(days: now.weekday - 1));
    final inicioMes = DateTime(now.year, now.month, 1);

    final completadas = ventas.where((v) => v.estado == 'completada').toList();

    _ventasHoy = completadas
        .where((v) => v.fecha.isAfter(hoy))
        .fold(0.0, (s, v) => s + v.total);
    _ventasSemana = completadas
        .where((v) => v.fecha.isAfter(inicioSemana))
        .fold(0.0, (s, v) => s + v.total);
    _ventasMes = completadas
        .where((v) => v.fecha.isAfter(inicioMes))
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

    final categorias = <String, double>{};
    for (final v in ventas) {
      for (final item in v.items) {
        final cat = item.producto.categoria;
        categorias.update(
          cat.isNotEmpty ? cat : 'General',
          (s) => s + item.subtotal,
          ifAbsent: () => item.subtotal,
        );
      }
    }
    _ventasPorCategoria = Map.fromEntries(categorias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));

    final map7 = <DateTime, double>{};
    final start7 =
        DateTime(hoy.year, hoy.month, hoy.day).subtract(const Duration(days: 6));
    for (int i = 0; i < 7; i++) {
      map7[start7.add(Duration(days: i))] = 0;
    }
    for (final v in completadas) {
      final day = DateTime(v.fecha.year, v.fecha.month, v.fecha.day);
      if (map7.containsKey(day)) {
        map7[day] = map7[day]! + v.total;
      }
    }
    _ventasUltimos7Dias = map7;

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

  void refresh() {
    _init();
  }
}
