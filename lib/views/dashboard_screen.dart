import 'package:flutter/material.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartVentas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.refresh(),
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumenCards(theme),
                  const SizedBox(height: 24),
                  SectionHeader(
                    titulo: 'Últimas Ventas',
                    accionTexto: 'Ver todas',
                  ),
                  if (viewModel.ultimasVentas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay ventas registradas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...viewModel.ultimasVentas.map(
                      (venta) => VentaItem(
                        folio: venta.folio,
                        cliente: venta.clienteNombre ?? 'Cliente general',
                        total: Formatters.currency(venta.total),
                        estado: venta.estado,
                        fecha: Formatters.shortDate(venta.fecha),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SectionHeader(titulo: 'Productos Más Vendidos'),
                  const SizedBox(height: 8),
                  if (viewModel.topProductos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay productos vendidos aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...viewModel.topProductos.map(
                      (producto) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(producto.nombre),
                          subtitle: Text(producto.categoria),
                          trailing: Text(
                            Formatters.currency(producto.precio),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumenCards(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                titulo: 'Ventas Hoy',
                valor: Formatters.currency(viewModel.totalVentasHoy),
                icono: Icons.today,
                color: Colors.blue,
                subtitulo: '${viewModel.ventasHoy} transacciones',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Esta Semana',
                valor: Formatters.currency(viewModel.totalVentasSemana),
                icono: Icons.date_range,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                titulo: 'Stock Bajo',
                valor: '${viewModel.productosStockBajo}',
                icono: Icons.inventory,
                color: Colors.red,
                subtitulo: 'productos por reabastecer',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Por Cobrar',
                valor: Formatters.currency(viewModel.totalCuentasCobrar),
                icono: Icons.account_balance_wallet,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                titulo: 'Por Pagar',
                valor: Formatters.currency(viewModel.totalCuentasPagar),
                icono: Icons.receipt_long,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Ganancia',
                valor: Formatters.currency(viewModel.gananciaTotal),
                icono: Icons.trending_up,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
