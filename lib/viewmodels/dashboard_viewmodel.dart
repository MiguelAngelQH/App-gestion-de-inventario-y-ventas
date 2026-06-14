import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:smart_ventas/services/api_service.dart';
import 'package:smart_ventas/services/fcm_service.dart';
import 'package:smart_ventas/services/firestore_service.dart';
import 'package:smart_ventas/viewmodels/config_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final ConfigViewModel _configVM;
  final ApiService _api = ApiService();

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
  bool _isFirstLoad = true;
  bool _usingServerData = false;
  Set<String> _prevStockBajoIds = {};

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
  bool get usingServerData => _usingServerData;

  StreamSubscription? _productosSub;
  StreamSubscription? _ventasSub;
  StreamSubscription? _clientesSub;
  StreamSubscription? _proveedoresSub;
  StreamSubscription? _authSub;
  Timer? _debounceTimer;

  DashboardViewModel({required ConfigViewModel configVM})
      : _configVM = configVM {
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
    _debounceTimer?.cancel();
    _api.dispose();
    super.dispose();
  }

  void _debounceNotify() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      notifyListeners();
    });
  }

  void _init() {
    _isLoading = true;
    _isFirstLoad = true;
    _usingServerData = false;
    _debounceTimer?.cancel();
    notifyListeners();

    _productosSub?.cancel();
    _ventasSub?.cancel();
    _clientesSub?.cancel();
    _proveedoresSub?.cancel();

    _productosSub = _firestore.getProductos().listen((productos) {
      _processProductos(productos);
    }, onError: (_) {
      _isLoading = false;
      _isFirstLoad = false;
      notifyListeners();
    });

    _ventasSub = _firestore.getVentas().listen((ventas) {
      _calcularMetricasVentas(ventas);
      _isLoading = false;
      _debounceNotify();
    }, onError: (_) {
      _isLoading = false;
      _debounceNotify();
    });

    _clientesSub = _firestore.getClientes().listen((clientes) {
      if (!_usingServerData) {
        _totalCuentasCobrar = 0;
        for (final c in clientes) {
          _totalCuentasCobrar += c.deuda;
        }
      }
      _debounceNotify();
    });

    _proveedoresSub = _firestore.getProveedores().listen((proveedores) {
      if (!_usingServerData) {
        _totalCuentasPagar = 0;
        for (final p in proveedores) {
          _totalCuentasPagar += p.saldoPendiente;
        }
      }
      _debounceNotify();
    });

    _fetchFromServer();
  }

  void _processProductos(List<Producto> productos) {
    int stockBajoCount = 0;
    final stockBajoIds = <String>{};
    for (final p in productos) {
      if (p.stockBajo) {
        stockBajoCount++;
        stockBajoIds.add(p.id);
      }
    }

    if (!_usingServerData) {
      _productosStockBajo = stockBajoCount;
    }

    if (!_isFirstLoad && _configVM.notificationsEnabled) {
      for (final id in stockBajoIds) {
        if (!_prevStockBajoIds.contains(id)) {
          final p = productos.firstWhere((x) => x.id == id);
          unawaited(FcmService().showLocalNotification(
            id: id.hashCode,
            title: 'Stock Bajo',
            body: '${p.nombre} — stock actual: ${p.stock}',
          ));
        }
      }
    }

    _prevStockBajoIds = stockBajoIds;
    _isLoading = false;
    _isFirstLoad = false;
    _debounceNotify();
  }

  void _calcularMetricasVentas(List<Venta> ventas) {
    if (!_usingServerData) {
      final now = DateTime.now();
      final hoy = DateTime(now.year, now.month, now.day);
      final inicioSemana = hoy.subtract(Duration(days: now.weekday - 1));
      final hoyMs = hoy.millisecondsSinceEpoch;
      final semanaMs = inicioSemana.millisecondsSinceEpoch;

      int ventasCountHoy = 0;
      double totalHoy = 0;
      double totalSemana = 0;
      double ganancia = 0;

      for (final v in ventas) {
        if (v.estado != 'completada') continue;
        final fechaMs = v.fecha.millisecondsSinceEpoch;

        if (fechaMs >= hoyMs) {
          ventasCountHoy++;
          totalHoy += v.total;
        }
        if (fechaMs >= semanaMs) {
          totalSemana += v.total;
        }

        double costo = 0;
        for (final item in v.items) {
          costo += item.producto.costo * item.cantidad;
        }
        ganancia += v.total - costo;
      }

      _ventasHoy = ventasCountHoy;
      _totalVentasHoy = totalHoy;
      _totalVentasSemana = totalSemana;
      _gananciaTotal = ganancia;
    }

    Venta? latest;
    for (final v in ventas) {
      if (latest == null || v.fecha.isAfter(latest.fecha)) {
        latest = v;
      }
    }
    if (latest != null) {
      final sorted = List<Venta>.from(ventas)
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      _ultimasVentas = sorted.take(5).toList();
    } else {
      _ultimasVentas = [];
    }

    final conteo = <String, int>{};
    final productoMap = <String, Producto>{};
    for (final v in ventas) {
      for (final item in v.items) {
        conteo.update(item.producto.id, (c) => c + item.cantidad,
            ifAbsent: () => item.cantidad);
        productoMap[item.producto.id] = item.producto;
      }
    }
    final sortedEntries = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topProductos = [];
    final limit = sortedEntries.length > 5 ? 5 : sortedEntries.length;
    for (int i = 0; i < limit; i++) {
      final p = productoMap[sortedEntries[i].key];
      if (p != null) _topProductos.add(p);
    }
  }

  Future<void> _fetchFromServer() async {
    _usingServerData = false;
    try {
      final ok = await _api.authenticate();
      if (!ok) return;

      final metrics = await _api.getDashboardMetrics();
      if (metrics != null) {
        _totalVentasHoy = metrics.ventasHoy;
        _totalVentasSemana = metrics.ventasSemana;
        _gananciaTotal = metrics.gananciaTotal;
        _productosStockBajo = metrics.stockBajo;
        _totalCuentasCobrar = metrics.cuentasCobrar;
        _totalCuentasPagar = metrics.cuentasPagar;
        _ventasHoy = metrics.ventasCountHoy;
        _usingServerData = true;
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _init();
  }
}
