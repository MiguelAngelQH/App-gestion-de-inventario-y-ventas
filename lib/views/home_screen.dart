import 'package:flutter/material.dart';
import 'package:smart_ventas/viewmodels/auth_viewmodel.dart';
import 'package:smart_ventas/viewmodels/cobrar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/compra_viewmodel.dart';
import 'package:smart_ventas/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_ventas/viewmodels/pagar_viewmodel.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/viewmodels/reporte_viewmodel.dart';
import 'package:smart_ventas/viewmodels/venta_viewmodel.dart';
import 'package:smart_ventas/views/cobrar_screen.dart';
import 'package:smart_ventas/views/compras_screen.dart';
import 'package:smart_ventas/views/configuracion_screen.dart';
import 'package:smart_ventas/views/dashboard_screen.dart';
import 'package:smart_ventas/views/inventario_screen.dart';
import 'package:smart_ventas/views/pagar_screen.dart';
import 'package:smart_ventas/views/reportes_screen.dart';
import 'package:smart_ventas/views/ventas_screen.dart';
import 'package:smart_ventas/views/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthViewModel authViewModel;
  final ProductoViewModel productoViewModel;
  final VentaViewModel ventaViewModel;
  final CompraViewModel compraViewModel;
  final DashboardViewModel dashboardViewModel;
  final CobrarViewModel cobrarViewModel;
  final PagarViewModel pagarViewModel;
  final ReporteViewModel reporteViewModel;

  const HomeScreen({
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = widget.authViewModel.usuario;
    final inicial = usuario?.inicial ?? 'U';

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(viewModel: widget.dashboardViewModel),
          InventarioScreen(viewModel: widget.productoViewModel),
          VentasScreen(
            viewModel: widget.ventaViewModel,
            productoViewModel: widget.productoViewModel,
          ),
          ComprasScreen(
            viewModel: widget.compraViewModel,
            productoViewModel: widget.productoViewModel,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Ventas',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index < 4 ? index : _selectedIndex;
            _openDrawerScreen(context, index);
          });
        },
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            accountName: Text(
              usuario?.email ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            accountEmail: Text(usuario?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Text(
                inicial,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: const Text('Inicio'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: const Text('Inventario'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: const Text('Ventas'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: const Text('Compras'),
          ),
          const Divider(),
          NavigationDrawerDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: const Text('Cuentas por Cobrar'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: const Text('Cuentas por Pagar'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: const Text('Reportes'),
          ),
          const Divider(),
          NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: const Text('Configuración'),
          ),
          const Divider(),
          _buildLogoutTile(theme),
        ],
      ),
    );
  }

  Widget _buildLogoutTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded,
                  color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.authViewModel.logout();
              Navigator.of(context).pushAndRemoveUntil(
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
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _openDrawerScreen(BuildContext context, int index) {
    Navigator.pop(context);
    switch (index) {
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CobrarScreen(viewModel: widget.cobrarViewModel),
          ),
        );
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PagarScreen(viewModel: widget.pagarViewModel),
          ),
        );
      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ReportesScreen(viewModel: widget.reporteViewModel),
          ),
        );
      case 7:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ConfiguracionScreen(),
          ),
        );
    }
  }
}
