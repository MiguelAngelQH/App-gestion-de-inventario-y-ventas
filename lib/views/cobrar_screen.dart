import 'package:flutter/material.dart';
import 'package:smart_ventas/models/cliente.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/cobrar_viewmodel.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';
import 'package:uuid/uuid.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () =>
            _mostrarAgregarCliente(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Cliente'),
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
                                  const SizedBox(width: 8),
                                  _accionesMenu(context, cliente, theme),
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

  Widget _accionesMenu(
      BuildContext context, Cliente cliente, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (opcion) {
        switch (opcion) {
          case 'historial':
            _mostrarHistorialPagos(context, cliente.id, cliente.nombre);
            break;
          case 'editar':
            _mostrarEditarCliente(context, cliente);
            break;
          case 'eliminar':
            _confirmarEliminar(context, cliente);
            break;
          default:
            viewModel.actualizarEstado(cliente.id, opcion);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
            value: 'historial',
            child: ListTile(
              leading: Icon(Icons.history, size: 20),
              title: Text('Historial de Pagos'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        const PopupMenuItem(
            value: 'editar',
            child: ListTile(
              leading: Icon(Icons.edit, size: 20),
              title: Text('Editar'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        const PopupMenuItem(
            value: 'eliminar',
            child: ListTile(
              leading: Icon(Icons.delete, size: 20, color: Colors.red),
              title: Text('Eliminar', style: TextStyle(color: Colors.red)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        const PopupMenuDivider(),
        if (cliente.estado != 'pendiente')
          const PopupMenuItem(
              value: 'pendiente', child: Text('Marcar Pendiente')),
        if (cliente.estado != 'pagado')
          const PopupMenuItem(
              value: 'pagado', child: Text('Marcar Pagado')),
        if (cliente.estado != 'vencido')
          const PopupMenuItem(
              value: 'vencido', child: Text('Marcar Vencido')),
      ],
    );
  }

  void _mostrarHistorialPagos(
      BuildContext context, String clienteId, String nombre) async {
    final pagos = await viewModel.getPagosHistorial(clienteId);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historial de Pagos - $nombre',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (pagos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Sin pagos registrados')),
              )
            else
              ...pagos.map((p) => ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(Formatters.currency(
                        (p['monto'] ?? 0).toDouble())),
                    subtitle: Text(Formatters.dateTime(p['fecha'] ?? '')),
                    trailing: p['nota'] != null && (p['nota'] as String).isNotEmpty
                        ? Chip(label: Text(p['nota'] as String))
                        : null,
                    dense: true,
                  )),
          ],
        ),
      ),
    );
  }

  void _mostrarEditarCliente(BuildContext context, Cliente cliente) {
    final nombreCtrl = TextEditingController(text: cliente.nombre);
    final telCtrl = TextEditingController(text: cliente.telefono);
    final emailCtrl = TextEditingController(text: cliente.email);
    final dirCtrl = TextEditingController(text: cliente.direccion);
    final deudaCtrl =
        TextEditingController(text: cliente.deuda.toStringAsFixed(2));
    DateTime? fechaVenc = cliente.fechaVencimiento;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deudaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Deuda (S/)',
                      prefixText: 'S/ ',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dirCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fechaVenc ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => fechaVenc = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Vencimiento',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      fechaVenc != null
                          ? Formatters.shortDate(fechaVenc)
                          : 'Seleccionar fecha',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                viewModel.updateCliente(cliente.copyWith(
                  nombre: nombreCtrl.text.trim(),
                  deuda: double.tryParse(deudaCtrl.text) ?? cliente.deuda,
                  telefono: telCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  direccion: dirCtrl.text.trim(),
                  fechaVencimiento: fechaVenc,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Eliminar a "${cliente.nombre}"?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              viewModel.deleteCliente(cliente.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
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
                prefixText: 'S/ ',
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

  void _mostrarAgregarCliente(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final deudaCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    DateTime? fechaVenc;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo Cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deudaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Deuda (S/) *',
                  prefixText: 'S/ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => fechaVenc = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Vencimiento',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    fechaVenc != null
                        ? Formatters.shortDate(fechaVenc!)
                        : 'Seleccionar fecha',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                final deuda = double.tryParse(deudaCtrl.text) ?? 0;
                viewModel.addCliente(Cliente(
                  id: const Uuid().v4(),
                  nombre: nombreCtrl.text.trim(),
                  deuda: deuda,
                  telefono: telCtrl.text.trim(),
                  fechaVencimiento: fechaVenc,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
