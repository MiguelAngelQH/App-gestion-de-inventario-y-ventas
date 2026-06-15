import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/venta.dart';
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
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleRecalculation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      notifyListeners();
    });
  }

  void _init() {
    _isLoading = true;
    notifyListeners();

    _ventasSub?.cancel();
    _comprasSub?.cancel();
    _clientesSub?.cancel();
    _proveedoresSub?.cancel();

    _ventasSub = _firestore.getVentas().listen((ventas) {
      _calcularMetricasVentas(ventas);
      _isLoading = false;
      _scheduleRecalculation();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });

    _comprasSub = _firestore.getCompras().listen((compras) {
      final now = DateTime.now();
      final inicioMes = DateTime(now.year, now.month, 1);
      _egresosMes = 0;
      for (final c in compras) {
        if (c.fecha.isAfter(inicioMes)) {
          _egresosMes += c.total;
        }
      }
      _scheduleRecalculation();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });

    _clientesSub = _firestore.getClientes().listen((clientes) {
      _cuentasCobrar = 0;
      for (final c in clientes) {
        _cuentasCobrar += c.deuda;
      }
      _scheduleRecalculation();
    });

    _proveedoresSub = _firestore.getProveedores().listen((proveedores) {
      _cuentasPagar = 0;
      for (final p in proveedores) {
        _cuentasPagar += p.saldoPendiente;
      }
      _scheduleRecalculation();
    });
  }

  void _calcularMetricasVentas(List<Venta> ventas) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final inicioSemana = hoy.subtract(Duration(days: now.weekday - 1));
    final inicioMes = DateTime(now.year, now.month, 1);

    double ventasHoy = 0;
    double ventasSemana = 0;
    double ventasMes = 0;
    double ganancia = 0;
    final categorias = <String, double>{};
    final map7 = <int, double>{};
    final start7 = hoy.subtract(const Duration(days: 6)).millisecondsSinceEpoch;
    for (int i = 0; i < 7; i++) {
      map7[start7 + i * 86400000] = 0;
    }
    final conteo = <String, int>{};
    final nombreMap = <String, String>{};
    final categoriaMap = <String, String>{};

    for (final v in ventas) {
      final esCompletada = v.estado == 'completada';
      final fechaMs = v.fecha.millisecondsSinceEpoch;
      final dayMs = _dayStartMs(fechaMs);

      if (esCompletada) {
        if (fechaMs >= hoy.millisecondsSinceEpoch) {
          ventasHoy += v.total;
        }
        if (fechaMs >= inicioSemana.millisecondsSinceEpoch) {
          ventasSemana += v.total;
        }
        if (fechaMs >= inicioMes.millisecondsSinceEpoch) {
          ventasMes += v.total;
        }

        double costoItems = 0;
        for (final item in v.items) {
          costoItems += item.costoUnitario * item.cantidad;
        }
        ganancia += v.total - costoItems;

        if (map7.containsKey(dayMs)) {
          map7[dayMs] = map7[dayMs]! + v.total;
        }
      }

      for (final item in v.items) {
        final cat = item.categoria;
        final catKey = cat.isNotEmpty ? cat : 'General';
        categorias.update(catKey, (s) => s + item.subtotal,
            ifAbsent: () => item.subtotal);

        final cant = item.cantidad.toInt();
        conteo.update(item.productoId, (c) => c + cant,
            ifAbsent: () => cant);
        nombreMap[item.productoId] = item.productoNombre;
        categoriaMap[item.productoId] = item.categoria;
      }
    }

    _ventasHoy = ventasHoy;
    _ventasSemana = ventasSemana;
    _ventasMes = ventasMes;
    _gananciaTotal = ganancia;
    _ventasPorCategoria = Map.fromEntries(categorias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));

    final ventas7 = <DateTime, double>{};
    final startDay = DateTime.fromMillisecondsSinceEpoch(start7);
    for (int i = 0; i < 7; i++) {
      final day = startDay.add(Duration(days: i));
      ventas7[day] = map7[day.millisecondsSinceEpoch] ?? 0;
    }
    _ventasUltimos7Dias = ventas7;

    final sortedEntries = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topProductos = [];
    final limit = sortedEntries.length > 5 ? 5 : sortedEntries.length;
    for (int i = 0; i < limit; i++) {
      final id = sortedEntries[i].key;
      _topProductos.add(Producto(
        id: id,
        nombre: nombreMap[id] ?? '',
        unidadBase: 'unidad',
        categoria: categoriaMap[id] ?? 'General',
      ));
    }
  }

  int _dayStartMs(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
  }

  void refresh() {
    _init();
  }
}
