import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_ventas/services/fcm_service.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/auth_viewmodel.dart';
import 'package:smart_ventas/viewmodels/cobrar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/compra_viewmodel.dart';
import 'package:smart_ventas/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_ventas/viewmodels/pagar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/viewmodels/reporte_viewmodel.dart';
import 'package:smart_ventas/viewmodels/venta_viewmodel.dart';
import 'package:smart_ventas/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FcmService().init();
  runApp(SmartVentasApp());
}

class SmartVentasApp extends StatelessWidget {
  SmartVentasApp({super.key});

  final _authViewModel = AuthViewModel();
  final _productoViewModel = ProductoViewModel();
  final _ventaViewModel = VentaViewModel();
  final _compraViewModel = CompraViewModel();
  final _dashboardViewModel = DashboardViewModel();
  final _cobrarViewModel = CobrarViewModel();
  final _pagarViewModel = PagarViewModel();
  final _reporteViewModel = ReporteViewModel();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: SplashScreen(
        authViewModel: _authViewModel,
        productoViewModel: _productoViewModel,
        ventaViewModel: _ventaViewModel,
        compraViewModel: _compraViewModel,
        dashboardViewModel: _dashboardViewModel,
        cobrarViewModel: _cobrarViewModel,
        pagarViewModel: _pagarViewModel,
        reporteViewModel: _reporteViewModel,
      ),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(elevation: 0),
    );
  }
}
