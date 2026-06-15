import 'package:flutter/material.dart';
import 'package:smart_ventas/models/compra.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/compra_viewmodel.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/views/compra_form_screen.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';

class ComprasScreen extends StatelessWidget {
  final CompraViewModel viewModel;
  final ProductoViewModel productoViewModel;

  const ComprasScreen({
    super.key,
    required this.viewModel,
    required this.productoViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
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
                child: viewModel.compras.isEmpty
                    ? const EmptyState(
                        icono: Icons.shopping_cart_outlined,
                        mensaje: 'No hay compras registradas',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: viewModel.compras.length,
                        itemBuilder: (context, index) {
                          final compra = viewModel.compras[index];
                          return _buildCompraCard(context, theme, compra);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondary) => CompraFormScreen(
              compraViewModel: viewModel,
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
              titulo: 'Total Compras',
              valor: Formatters.currency(viewModel.totalCompras),
              icono: Icons.shopping_cart,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              titulo: 'Pendiente',
              valor: Formatters.currency(viewModel.totalPendiente),
              icono: Icons.pending_actions,
              color: Colors.orange,
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
          _buildFilterChip('pendiente', 'Pendientes'),
          const SizedBox(width: 8),
          _buildFilterChip('recibida', 'Recibidas'),
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

  Widget _buildCompraCard(
      BuildContext context, ThemeData theme, Compra compra) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Text(
                    compra.folio.length >= 2
                        ? compra.folio.substring(0, 2)
                        : 'C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compra.folio,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        compra.proveedorNombre,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                EstadoBadge(estado: compra.estado),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.date(compra.fecha),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  Formatters.currency(compra.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _mostrarDetalle(context, theme, compra),
                child: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(
      BuildContext context, ThemeData theme, Compra compra) {
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
                  compra.folio,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                EstadoBadge(estado: compra.estado),
              ],
            ),
            const Divider(height: 24),
            InfoRow(
              label: 'Fecha',
              value: Formatters.dateTime(compra.fecha),
              icon: Icons.calendar_today,
            ),
            InfoRow(
              label: 'Proveedor',
              value: compra.proveedorNombre,
              icon: Icons.business,
            ),
            const Divider(height: 16),
            Text(
              'Productos',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...compra.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad}x ${item.productoNombre}',
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
                  Formatters.currency(compra.total),
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
