import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/reporte_viewmodel.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';

class ReportesScreen extends StatelessWidget {
  final ReporteViewModel viewModel;

  const ReportesScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricas(theme),
                const SizedBox(height: 24),
                _buildChartVentas7Dias(theme),
                const SizedBox(height: 24),
                _buildVentasCategoria(theme),
                const SizedBox(height: 24),
                _buildTopProductos(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricas(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                titulo: 'Ventas Hoy',
                valor: Formatters.currency(viewModel.ventasHoy),
                icono: Icons.today,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Esta Semana',
                valor: Formatters.currency(viewModel.ventasSemana),
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
                titulo: 'Ventas del Mes',
                valor: Formatters.currency(viewModel.ventasMes),
                icono: Icons.monetization_on,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Ganancia',
                valor: Formatters.currency(viewModel.gananciaTotal),
                icono: Icons.trending_up,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                titulo: 'Por Cobrar',
                valor: Formatters.currency(viewModel.cuentasCobrar),
                icono: Icons.account_balance_wallet,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Por Pagar',
                valor: Formatters.currency(viewModel.cuentasPagar),
                icono: Icons.receipt_long,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                titulo: 'Egresos del Mes',
                valor: Formatters.currency(viewModel.egresosMes),
                icono: Icons.shopping_cart,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                titulo: 'Ingreso Neto',
                valor: Formatters.currency(viewModel.ingresoNeto),
                icono: Icons.account_balance,
                color: viewModel.ingresoNeto >= 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartVentas7Dias(ThemeData theme) {
    final data = viewModel.ventasUltimos7Dias;
    final spots = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxY = spots.fold<double>(
            0, (max, e) => e.value > max ? e.value : max) *
        1.2;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ventas Últimos 7 Días',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY : 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex >= spots.length) {
                          return null;
                        }
                        return BarTooltipItem(
                          '${Formatters.shortDate(spots[groupIndex].key)}\n${Formatters.currency(rod.toY)}',
                          TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= spots.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              Formatters.shortDate(spots[index].key),
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            Formatters.currency(value),
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: spots.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value > 0 ? entry.value.value : 0,
                          color: theme.colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasCategoria(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ventas por Categoría',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...viewModel.ventasPorCategoria.entries.map((entry) {
              final total = viewModel.ventasPorCategoria.values
                  .fold(0.0, (s, v) => s + v);
              final porcentaje =
                  total > 0 ? (entry.value / total) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: theme.textTheme.bodyMedium),
                        Text(
                          Formatters.currency(entry.value),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: porcentaje / 100,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductos(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(titulo: 'Productos Más Vendidos'),
        const SizedBox(height: 8),
        ...viewModel.topProductos.asMap().entries.map((entry) {
          final index = entry.key;
          final producto = entry.value;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(producto.nombre),
              subtitle: Text(producto.categoria),
              trailing: Text(
                producto.presentaciones.isNotEmpty
                    ? Formatters.currency(producto.presentaciones.first.precio)
                    : '-',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }
}
