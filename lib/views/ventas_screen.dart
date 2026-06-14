import 'package:flutter/material.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/viewmodels/venta_viewmodel.dart';
import 'package:smart_ventas/views/venta_form_screen.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';

class VentasScreen extends StatelessWidget {
  final VentaViewModel viewModel;
  final ProductoViewModel productoViewModel;

  const VentasScreen({
    super.key,
    required this.viewModel,
    required this.productoViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildSummary(theme),
              _buildFilterBar(theme),
              Expanded(
                child: viewModel.ventas.isEmpty
                    ? const EmptyState(
                        icono: Icons.receipt_long_outlined,
                        mensaje: 'No hay ventas registradas',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: viewModel.ventas.length,
                        itemBuilder: (context, index) {
                          final venta = viewModel.ventas[index];
                          final totalStr = Formatters.currency(venta.total);
                          final clienteStr =
                              venta.clienteNombre ?? 'Cliente general';
                          final fechaStr = Formatters.date(venta.fecha);
                          return VentaItem(
                            folio: venta.folio,
                            cliente: clienteStr,
                            total: totalStr,
                            estado: venta.estado,
                            fecha: fechaStr,
                            onTap: () => _mostrarDetalle(
                                context, theme, venta, totalStr),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondary) => VentaFormScreen(
              ventaViewModel: viewModel,
              productoViewModel: productoViewModel,
            ),
            transitionsBuilder: (context, animation, secondary, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              titulo: 'Total Ventas',
              valor: Formatters.currency(viewModel.totalVentas),
              icono: Icons.monetization_on,
              color: Colors.green,
              subtitulo: '${viewModel.totalTransacciones} transacciones',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('todas', 'Todas'),
          const SizedBox(width: 8),
          _buildFilterChip('completada', 'Completadas'),
          const SizedBox(width: 8),
          _buildFilterChip('pendiente', 'Pendientes'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String estado, String label) {
    final seleccionado = viewModel.filtroEstado == estado;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) => viewModel.setFiltroEstado(estado),
      visualDensity: VisualDensity.compact,
    );
  }

  void _mostrarDetalle(BuildContext context, ThemeData theme, Venta venta,
      String totalStr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  venta.folio,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                EstadoBadge(estado: venta.estado),
              ],
            ),
            const Divider(height: 24),
            InfoRow(
              label: 'Fecha',
              value: Formatters.dateTime(venta.fecha),
              icon: Icons.calendar_today,
            ),
            InfoRow(
              label: 'Cliente',
              value: venta.clienteNombre ?? 'Cliente general',
              icon: Icons.person,
            ),
            InfoRow(
              label: 'Método de pago',
              value: venta.metodoPago,
              icon: Icons.payment,
            ),
            const Divider(height: 16),
            Text(
              'Productos',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...venta.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad}x ${item.producto.nombre}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      Formatters.currency(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  totalStr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
