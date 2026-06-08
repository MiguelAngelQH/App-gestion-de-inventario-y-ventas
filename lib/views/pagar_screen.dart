import 'package:flutter/material.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/pagar_viewmodel.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';

class PagarScreen extends StatelessWidget {
  final PagarViewModel viewModel;

  const PagarScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proveedores = viewModel.proveedoresConDeuda;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas por Pagar'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceContainerLow,
                child: Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        titulo: 'Total por Pagar',
                        valor: Formatters.currency(viewModel.totalPendiente),
                        icono: Icons.account_balance_wallet,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        titulo: 'Proveedores',
                        valor: '${viewModel.proveedoresPendientes}',
                        icono: Icons.business,
                        color: Colors.purple,
                        subtitulo: 'con saldo pendiente',
                      ),
                    ),
                  ],
                ),
              ),
              if (proveedores.isEmpty)
                const Expanded(
                  child: EmptyState(
                    icono: Icons.check_circle_outline,
                    mensaje: 'No hay cuentas por pagar',
                    subtitulo: 'Todos los proveedores están liquidados',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: proveedores.length,
                    itemBuilder: (context, index) {
                      final proveedor = proveedores[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme
                                        .colorScheme.tertiaryContainer,
                                    child: Text(
                                      proveedor.nombre
                                          .split(' ')
                                          .where((w) => w.isNotEmpty)
                                          .map((w) => w[0])
                                          .take(2)
                                          .join(),
                                      style: TextStyle(
                                        color: theme.colorScheme
                                            .onTertiaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          proveedor.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (proveedor.fechaVencimiento != null)
                                          Text(
                                            'Vence: ${Formatters.shortDate(proveedor.fechaVencimiento!)}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: proveedor.vencido
                                                  ? Colors.red
                                                  : theme.colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Formatters.currency(
                                            proveedor.saldoPendiente),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _estadoBadge(proveedor.estado, theme),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _mostrarRegistrarPago(
                                              context, proveedor.id, proveedor.nombre),
                                      icon: const Icon(Icons.payments_outlined,
                                          size: 18),
                                      label: const Text('Registrar Pago'),
                                    ),
                                  ),
                                  if (proveedor.estado != 'pagado') ...[
                                    const SizedBox(width: 8),
                                    _estadoMenu(context, proveedor, theme),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _estadoBadge(String estado, ThemeData theme) {
    final esquema = EstadoBadge.esquema(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: esquema.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        esquema.texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: esquema.color,
        ),
      ),
    );
  }

  Widget _estadoMenu(
      BuildContext context, Proveedor proveedor, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (estado) =>
          viewModel.actualizarEstado(proveedor.id, estado),
      itemBuilder: (_) => [
        if (proveedor.estado != 'pendiente')
          const PopupMenuItem(value: 'pendiente', child: Text('Marcar Pendiente')),
        if (proveedor.estado != 'pagado')
          const PopupMenuItem(value: 'pagado', child: Text('Marcar Pagado')),
        if (proveedor.estado != 'vencido')
          const PopupMenuItem(value: 'vencido', child: Text('Marcar Vencido')),
      ],
    );
  }

  void _mostrarRegistrarPago(
      BuildContext context, String proveedorId, String nombre) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Proveedor: $nombre'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final monto = double.tryParse(controller.text);
              if (monto != null && monto > 0) {
                viewModel.registrarPago(proveedorId, monto);
                Navigator.pop(context);
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
