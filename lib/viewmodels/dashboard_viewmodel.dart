import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:smart_ventas/services/fcm_service.dart';
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

  DashboardViewModel() {
    _cargar();
  }

  Future<void> _cargar() async {
    final now = DateTime.now();
    final inicioHoy = DateTime(now.year, now.month, now.day);
    final manana = inicioHoy.add(const Duration(days: 1));
    final inicioSemana = now.subtract(Duration(days: now.weekday - 1));

    try {
      final results = await Future.wait([
        _firestore.totalVentasHoy(),
        _firestore.ventasCountHoy(),
        _firestore.productosStockBajoCount(),
        _firestore.totalCuentasCobrar(),
        _firestore.totalCuentasPagar(),
        _firestore.totalGanancia(),
        _firestore.totalVentasPeriodo(inicioSemana, manana),
        _firestore.ultimasVentas(),
        _firestore.topProductos(),
      ]);

      _totalVentasHoy = results[0] as double;
      _ventasHoy = results[1] as int;
      _productosStockBajo = results[2] as int;
      _totalCuentasCobrar = results[3] as double;
      _totalCuentasPagar = results[4] as double;
      _gananciaTotal = results[5] as double;
      _totalVentasSemana = results[6] as double;
      _ultimasVentas = results[7] as List<Venta>;
      _topProductos = results[8] as List<Producto>;
      _isLoading = false;
      notifyListeners();
      unawaited(FcmService().checkAndNotify());
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _cargar();
  }
}
