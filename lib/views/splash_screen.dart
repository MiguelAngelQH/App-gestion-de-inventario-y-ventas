import 'package:flutter/material.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/auth_viewmodel.dart';
import 'package:smart_ventas/viewmodels/cobrar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/compra_viewmodel.dart';
import 'package:smart_ventas/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_ventas/viewmodels/pagar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/viewmodels/reporte_viewmodel.dart';
import 'package:smart_ventas/viewmodels/venta_viewmodel.dart';
import 'package:smart_ventas/views/home_screen.dart';
import 'package:smart_ventas/views/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final AuthViewModel authViewModel;
  final ProductoViewModel productoViewModel;
  final VentaViewModel ventaViewModel;
  final CompraViewModel compraViewModel;
  final DashboardViewModel dashboardViewModel;
  final CobrarViewModel cobrarViewModel;
  final PagarViewModel pagarViewModel;
  final ReporteViewModel reporteViewModel;

  const SplashScreen({
    super.key,
    required this.authViewModel,
    required this.productoViewModel,
    required this.ventaViewModel,
    required this.compraViewModel,
    required this.dashboardViewModel,
    required this.cobrarViewModel,
    required this.pagarViewModel,
    required this.reporteViewModel,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: AppConstants.splashDuration));
    if (!mounted) return;

    if (widget.authViewModel.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            authViewModel: widget.authViewModel,
            productoViewModel: widget.productoViewModel,
            ventaViewModel: widget.ventaViewModel,
            compraViewModel: widget.compraViewModel,
            dashboardViewModel: widget.dashboardViewModel,
            cobrarViewModel: widget.cobrarViewModel,
            pagarViewModel: widget.pagarViewModel,
            reporteViewModel: widget.reporteViewModel,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            authViewModel: widget.authViewModel,
            productoViewModel: widget.productoViewModel,
            ventaViewModel: widget.ventaViewModel,
            compraViewModel: widget.compraViewModel,
            dashboardViewModel: widget.dashboardViewModel,
            cobrarViewModel: widget.cobrarViewModel,
            pagarViewModel: widget.pagarViewModel,
            reporteViewModel: widget.reporteViewModel,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.store_rounded,
                size: 56,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
