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
        title: Text(
          'SmartVentas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          if (viewModel.usingServerData)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Servidor', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.refresh(),
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            if (viewModel.isLoading) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Row(children: const [
                      Expanded(child: SkeletonCard(height: 120)),
                      SizedBox(width: 12),
                      Expanded(child: SkeletonCard(height: 120)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: const [
                      Expanded(child: SkeletonCard(height: 120)),
                      SizedBox(width: 12),
                      Expanded(child: SkeletonCard(height: 120)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: const [
                      Expanded(child: SkeletonCard(height: 120)),
                      SizedBox(width: 12),
                      Expanded(child: SkeletonCard(height: 120)),
                    ]),
                    const SizedBox(height: 28),
                    const SkeletonListTile(),
                    const SkeletonListTile(),
                    const SkeletonListTile(),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumenCards(theme),
                  const SizedBox(height: 28),
                  SectionHeader(
                    titulo: 'Últimas Ventas',
                    accionTexto: 'Ver todas',
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.ultimasVentas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay ventas registradas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...viewModel.ultimasVentas.asMap().entries.map(
                      (entry) => AnimatedListItem(
                        index: entry.key,
                        child: VentaItem(
                          folio: entry.value.folio,
                          cliente: entry.value.clienteNombre ??
                              'Cliente general',
                          total: Formatters.currency(entry.value.total),
                          estado: entry.value.estado,
                          fecha: Formatters.shortDate(entry.value.fecha),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  SectionHeader(titulo: 'Productos Más Vendidos'),
                  const SizedBox(height: 12),
                  if (viewModel.topProductos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay productos vendidos aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...viewModel.topProductos.asMap().entries.map(
                      (entry) => AnimatedListItem(
                        index: entry.key,
                        child: Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          theme.colorScheme.primaryContainer,
                                          theme.colorScheme.primaryContainer
                                              .withValues(alpha: 0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: theme
                                          .colorScheme.onPrimaryContainer,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.value.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          entry.value.categoria,
                                          style: theme
                                              .textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(entry.value.presentaciones.isNotEmpty
                                        ? entry.value.presentaciones.first.precio
                                        : 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF00897B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                color: const Color(0xFF00897B),
                subtitulo: '${viewModel.ventasHoy} transacciones',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Esta Semana',
                valor: Formatters.currency(viewModel.totalVentasSemana),
                icono: Icons.date_range,
                color: const Color(0xFF00897B),
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
                color: const Color(0xFFE53935),
                subtitulo: 'productos por reabastecer',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Por Cobrar',
                valor: Formatters.currency(viewModel.totalCuentasCobrar),
                icono: Icons.account_balance_wallet,
                color: const Color(0xFFFB8C00),
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
                color: const Color(0xFFE53935),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Ganancia',
                valor: Formatters.currency(viewModel.gananciaTotal),
                icono: Icons.trending_up,
                color: const Color(0xFF43A047),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
