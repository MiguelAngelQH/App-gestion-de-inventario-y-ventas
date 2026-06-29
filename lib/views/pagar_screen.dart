import 'package:flutter/material.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/pagar_viewmodel.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';
import 'package:uuid/uuid.dart';

class PagarScreen extends StatefulWidget {
  final PagarViewModel viewModel;

  const PagarScreen({super.key, required this.viewModel});

  @override
  State<PagarScreen> createState() => _PagarScreenState();
}

class _PagarScreenState extends State<PagarScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proveedores = widget.viewModel.proveedoresConDeuda;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas por Pagar'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _mostrarAgregarProveedor(context),
        icon: const Icon(Icons.business),
        label: const Text('Agregar Proveedor'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: MetricCard(
                    titulo: 'Total por Pagar',
                    valor: Formatters.currency(widget.viewModel.totalPendiente),
                    icono: Icons.account_balance_wallet,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    titulo: 'Proveedores',
                    valor: '${widget.viewModel.proveedoresPendientes}',
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
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.tertiaryContainer,
                                child: Text(
                                  proveedor.nombre
                                      .split(' ')
                                      .where((w) => w.isNotEmpty)
                                      .map((w) => w[0])
                                      .take(2)
                                      .join(),
                                  style: TextStyle(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  : theme
                                                        .colorScheme
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
                                      proveedor.saldoPendiente,
                                    ),
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
                                  onPressed: () => _mostrarRegistrarPago(
                                    context,
                                    proveedor.id,
                                    proveedor.nombre,
                                    proveedor.saldoPendiente,
                                  ),
                                  icon: const Icon(
                                    Icons.payments_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Registrar Pago'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _accionesMenu(context, proveedor, theme),
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
    BuildContext context,
    Proveedor proveedor,
    ThemeData theme,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (opcion) {
        switch (opcion) {
          case 'historial':
            _mostrarHistorialPagos(context, proveedor.id, proveedor.nombre);
            break;
          case 'editar':
            _mostrarEditarProveedor(context, proveedor);
            break;
          case 'eliminar':
            _confirmarEliminar(context, proveedor);
            break;
          default:
            widget.viewModel.actualizarEstado(proveedor.id, opcion);
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
          ),
        ),
        const PopupMenuItem(
          value: 'editar',
          child: ListTile(
            leading: Icon(Icons.edit, size: 20),
            title: Text('Editar'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'eliminar',
          child: ListTile(
            leading: Icon(Icons.delete, size: 20, color: Colors.red),
            title: Text('Eliminar', style: TextStyle(color: Colors.red)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        if (proveedor.estado != 'pendiente')
          const PopupMenuItem(
            value: 'pendiente',
            child: Text('Marcar Pendiente'),
          ),
        if (proveedor.estado != 'pagado')
          const PopupMenuItem(value: 'pagado', child: Text('Marcar Pagado')),
        if (proveedor.estado != 'vencido')
          const PopupMenuItem(value: 'vencido', child: Text('Marcar Vencido')),
      ],
    );
  }

  void _mostrarHistorialPagos(
    BuildContext context,
    String proveedorId,
    String nombre,
  ) async {
    final pagos = await widget.viewModel.getPagosHistorial(proveedorId);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Pagos - $nombre',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            if (pagos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Sin pagos registrados')),
              )
            else
              ...pagos.map(
                (p) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(
                    Formatters.currency((p['monto'] ?? 0).toDouble()),
                  ),
                  subtitle: Text(Formatters.dateTimeFromStr(p['fecha'] ?? '')),
                  trailing:
                      p['nota'] != null && (p['nota'] as String).isNotEmpty
                      ? Chip(label: Text(p['nota'] as String))
                      : null,
                  dense: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarEditarProveedor(BuildContext context, Proveedor proveedor) {
    final nombreCtrl = TextEditingController(text: proveedor.nombre);
    final telCtrl = TextEditingController(text: proveedor.telefono);
    final emailCtrl = TextEditingController(text: proveedor.email);
    final dirCtrl = TextEditingController(text: proveedor.direccion);
    final saldoCtrl = TextEditingController(
      text: proveedor.saldoPendiente.toStringAsFixed(2),
    );
    DateTime? fechaVenc = proveedor.fechaVencimiento;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Proveedor'),
          content: SingleChildScrollView(
            child: Column(
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
                  controller: saldoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Saldo Pendiente (S/)',
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
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dirCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          fechaVenc ??
                          DateTime.now().add(const Duration(days: 7)),
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
                          ? Formatters.shortDate(fechaVenc!)
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
                final saldo = double.tryParse(saldoCtrl.text);
                if (saldo != null && saldo < 0) return;
                widget.viewModel.updateProveedor(
                  proveedor.copyWith(
                    nombre: nombreCtrl.text.trim(),
                    saldoPendiente: saldo ?? proveedor.saldoPendiente,
                    telefono: telCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    direccion: dirCtrl.text.trim(),
                    fechaVencimiento: fechaVenc,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, Proveedor proveedor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: Text(
          '¿Eliminar a "${proveedor.nombre}"?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              widget.viewModel.deleteProveedor(proveedor.id);
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
    BuildContext context,
    String proveedorId,
    String nombre,
    double saldoPendiente,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Proveedor: $nombre'),
            const SizedBox(height: 8),
            Text('Saldo pendiente: ${Formatters.currency(saldoPendiente)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
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
              if (monto != null && monto > 0 && monto <= saldoPendiente) {
                widget.viewModel.registrarPago(proveedorId, monto);
                Navigator.pop(context);
              } else if (monto != null && monto > saldoPendiente) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El monto no puede superar el saldo pendiente'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarAgregarProveedor(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final saldoCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    DateTime? fechaVenc;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo Proveedor'),
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
                controller: saldoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo Pendiente (S/) *',
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
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty) return;
                final saldo = double.tryParse(saldoCtrl.text);
                if (saldo == null || saldo < 0) return;
                await widget.viewModel.addProveedor(
                  Proveedor(
                    id: const Uuid().v4(),
                    nombre: nombreCtrl.text.trim(),
                    saldoPendiente: saldo,
                    telefono: telCtrl.text.trim(),
                    fechaVencimiento: fechaVenc,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
