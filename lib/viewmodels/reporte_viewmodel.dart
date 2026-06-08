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
  Map<DateTime, double> _ventasUltimos7Dias = _default7Dias();
  List<Producto> _topProductos = [];
  bool _isLoading = true;

  static Map<DateTime, double> _default7Dias() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    final map = <DateTime, double>{};
    for (int i = 0; i < 7; i++) {
      map[start.add(Duration(days: i))] = 0;
    }
    return map;
  }

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

  ReporteViewModel() {
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final now = DateTime.now();
      final inicioMes = DateTime(now.year, now.month, 1);
      final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
      final inicioHoy = DateTime(now.year, now.month, now.day);
      final manana = inicioHoy.add(const Duration(days: 1));
      final finMes = DateTime(now.year, now.month + 1, 1);

      final results = await Future.wait([
        _firestore.totalVentasPeriodo(inicioHoy, manana),
        _firestore.totalVentasPeriodo(inicioSemana, manana),
        _firestore.totalVentasPeriodo(inicioMes, finMes),
        _firestore.totalGanancia(),
        _firestore.totalCuentasCobrar(),
        _firestore.totalCuentasPagar(),
        _firestore.ventasPorCategoria(),
        _firestore.ventasUltimos7Dias(),
        _firestore.topProductos(),
        _firestore.totalComprasPeriodo(inicioMes, finMes),
      ]);

      _ventasHoy = results[0] as double;
      _ventasSemana = results[1] as double;
      _ventasMes = results[2] as double;
      _gananciaTotal = results[3] as double;
      _cuentasCobrar = results[4] as double;
      _cuentasPagar = results[5] as double;
      _ventasPorCategoria = results[6] as Map<String, double>;
      _ventasUltimos7Dias = results[7] as Map<DateTime, double>;
      _topProductos = results[8] as List<Producto>;
      _egresosMes = results[9] as double;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
