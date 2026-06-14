import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_ventas/utils/constants.dart';

class DashboardMetrics {
  final double ventasHoy;
  final double ventasSemana;
  final double gananciaTotal;
  final int stockBajo;
  final double cuentasCobrar;
  final double cuentasPagar;
  final int ventasCountHoy;

  DashboardMetrics({
    required this.ventasHoy,
    required this.ventasSemana,
    required this.gananciaTotal,
    required this.stockBajo,
    required this.cuentasCobrar,
    required this.cuentasPagar,
    required this.ventasCountHoy,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      ventasHoy: (json['ventasHoy'] ?? 0).toDouble(),
      ventasSemana: (json['ventasSemana'] ?? 0).toDouble(),
      gananciaTotal: (json['gananciaTotal'] ?? 0).toDouble(),
      stockBajo: (json['stockBajo'] ?? 0) as int,
      cuentasCobrar: (json['cuentasCobrar'] ?? 0).toDouble(),
      cuentasPagar: (json['cuentasPagar'] ?? 0).toDouble(),
      ventasCountHoy: (json['ventasCountHoy'] ?? 0) as int,
    );
  }
}

class ReportesData {
  final List<VentaDia> ventasPorDia;
  final List<VentaCategoria> ventasPorCategoria;
  final List<TopProducto> topProductos;

  ReportesData({
    required this.ventasPorDia,
    required this.ventasPorCategoria,
    required this.topProductos,
  });

  factory ReportesData.fromJson(Map<String, dynamic> json) {
    return ReportesData(
      ventasPorDia: (json['ventasPorDia'] as List<dynamic>?)
              ?.map((e) => VentaDia.fromJson(e))
              .toList() ??
          [],
      ventasPorCategoria: (json['ventasPorCategoria'] as List<dynamic>?)
              ?.map((e) => VentaCategoria.fromJson(e))
              .toList() ??
          [],
      topProductos: (json['topProductos'] as List<dynamic>?)
              ?.map((e) => TopProducto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class VentaDia {
  final String fecha;
  final double total;
  VentaDia({required this.fecha, required this.total});
  factory VentaDia.fromJson(Map<String, dynamic> json) =>
      VentaDia(fecha: json['fecha'], total: (json['total'] ?? 0).toDouble());
}

class VentaCategoria {
  final String categoria;
  final double total;
  VentaCategoria({required this.categoria, required this.total});
  factory VentaCategoria.fromJson(Map<String, dynamic> json) => VentaCategoria(
      categoria: json['categoria'], total: (json['total'] ?? 0).toDouble());
}

class TopProducto {
  final String id;
  final String nombre;
  final int cantidad;
  TopProducto({required this.id, required this.nombre, required this.cantidad});
  factory TopProducto.fromJson(Map<String, dynamic> json) => TopProducto(
      id: json['id'], nombre: json['nombre'], cantidad: (json['cantidad'] ?? 0) as int);
}

class ApiService {
  String? _token;
  final http.Client _client = http.Client();

  String get _baseUrl => AppConstants.apiBaseUrl;

  Future<bool> authenticate() async {
    final firebaseToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (firebaseToken == null) return false;

    try {
      final res = await _client.post(
        Uri.parse('$_baseUrl/api/auth/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': firebaseToken}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _token = data['token'] as String?;
      return _token != null;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<DashboardMetrics?> getDashboardMetrics() async {
    try {
      final res = await _client.get(
        Uri.parse('$_baseUrl/api/dashboard'),
        headers: _headers,
      );
      if (res.statusCode != 200) return null;
      return DashboardMetrics.fromJson(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  Future<ReportesData?> getReportes() async {
    try {
      final res = await _client.get(
        Uri.parse('$_baseUrl/api/reportes'),
        headers: _headers,
      );
      if (res.statusCode != 200) return null;
      return ReportesData.fromJson(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
