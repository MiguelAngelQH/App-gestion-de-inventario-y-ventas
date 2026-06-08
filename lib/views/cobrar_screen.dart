import 'package:flutter/material.dart';
import 'package:smart_ventas/models/cliente.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/cobrar_viewmodel.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';

class CobrarScreen extends StatelessWidget {
  final CobrarViewModel viewModel;

  const CobrarScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientes = viewModel.clientesConDeuda;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas por Cobrar'),
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
                        titulo: 'Total por Cobrar',
                        valor: Formatters.currency(viewModel.totalDeuda),
                        icono: Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        titulo: 'Clientes',
                        valor: '${viewModel.clientesMorosos}',
                        icono: Icons.people,
                        color: Colors.blue,
                        subtitulo: 'con deuda pendiente',
                      ),
                    ),
                  ],
                ),
              ),
              if (clientes.isEmpty)
                const Expanded(
                  child: EmptyState(
                    icono: Icons.check_circle_outline,
                    mensaje: 'No hay cuentas por cobrar',
                    subtitulo: 'Todos los clientes están al corriente',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
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
                                        .colorScheme.primaryContainer,
                                    child: Text(
                                      cliente.nombre
                                          .split(' ')
                                          .where((w) => w.isNotEmpty)
                                          .map((w) => w[0])
                                          .take(2)
                                          .join(),
                                      style: TextStyle(
                                        color: theme.colorScheme
                                            .onPrimaryContainer,
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
                                          cliente.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (cliente.telefono.isNotEmpty)
                                          Text(
                                            cliente.telefono,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        if (cliente.fechaVencimiento != null)
                                          Text(
                                            'Vence: ${Formatters.shortDate(cliente.fechaVencimiento!)}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: cliente.vencido
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
                                        Formatters.currency(cliente.deuda),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _estadoBadge(cliente.estado, theme),
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
                                              context, cliente.id, cliente.nombre),
                                      icon: const Icon(Icons.payments_outlined,
                                          size: 18),
                                      label: const Text('Registrar Pago'),
                                    ),
                                  ),
                                  if (cliente.estado != 'pagado') ...[
                                    const SizedBox(width: 8),
                                    _estadoMenu(context, cliente, theme),
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
      BuildContext context, Cliente cliente, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (estado) =>
          viewModel.actualizarEstado(cliente.id, estado),
      itemBuilder: (_) => [
        if (cliente.estado != 'pendiente')
          const PopupMenuItem(value: 'pendiente', child: Text('Marcar Pendiente')),
        if (cliente.estado != 'pagado')
          const PopupMenuItem(value: 'pagado', child: Text('Marcar Pagado')),
        if (cliente.estado != 'vencido')
          const PopupMenuItem(value: 'vencido', child: Text('Marcar Vencido')),
      ],
    );
  }

  void _mostrarRegistrarPago(
      BuildContext context, String clienteId, String nombre) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cliente: $nombre'),
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
                viewModel.registrarPago(clienteId, monto);
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
