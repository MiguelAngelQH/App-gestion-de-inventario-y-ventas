import 'package:flutter/material.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/viewmodels/venta_viewmodel.dart';

class VentaFormScreen extends StatefulWidget {
  final VentaViewModel ventaViewModel;
  final ProductoViewModel productoViewModel;

  const VentaFormScreen({
    super.key,
    required this.ventaViewModel,
    required this.productoViewModel,
  });

  @override
  State<VentaFormScreen> createState() => _VentaFormScreenState();
}

class _VentaFormScreenState extends State<VentaFormScreen> {
  final _clienteCtrl = TextEditingController();
  final _items = <ItemVenta>[];
  String _metodoPago = 'Efectivo';
  bool _guardando = false;

  @override
  void dispose() {
    _clienteCtrl.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0, (s, i) => s + i.subtotal);

  void _agregarProducto() {
    final productos = widget.productoViewModel.productos
        .where((p) =>
            p.stockTotal > 0 && !_items.any((i) => i.productoId == p.id))
        .toList();

    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _SeleccionarProductoDialog(
        productos: productos,
        onSeleccionar: (producto, presentacion, cantidad) {
          setState(() {
            _items.add(ItemVenta(
              productoId: producto.id,
              productoNombre: producto.nombre,
              categoria: producto.categoria,
              presentacionId: presentacion.id,
              presentacionNombre: presentacion.nombreVisual,
              factor: presentacion.factor,
              cantidad: cantidad,
              precioUnitario: presentacion.precio,
              costoUnitario: presentacion.costo,
            ));
          });
        },
      ),
    );
  }

  void _quitarItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _guardarVenta() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    setState(() => _guardando = true);

    final venta = Venta(
      id: '',
      fecha: DateTime.now(),
      clienteNombre:
          _clienteCtrl.text.isNotEmpty ? _clienteCtrl.text.trim() : null,
      items: List.from(_items),
      total: _total,
      metodoPago: _metodoPago,
      estado: 'completada',
    );

    final id = await widget.ventaViewModel.addVenta(venta);
    if (mounted) {
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta registrada exitosamente')),
        );
        Navigator.pop(context);
      } else {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _clienteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cliente (opcional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _metodoPago,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: AppConstants.metodosPago
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _metodoPago = v ?? 'Efectivo'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Productos',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: _agregarProducto,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Agrega productos a la venta',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ..._items.asMap().entries.map(
                        (entry) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(entry.value.productoNombre),
                            subtitle: Text(
                              '${entry.value.cantidad} ${entry.value.presentacionNombre} x ${Formatters.currency(entry.value.precioUnitario)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Formatters.currency(entry.value.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () => _quitarItem(entry.key),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          Formatters.currency(_total),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _guardarVenta,
                      icon: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                          _guardando ? 'Guardando...' : 'Completar Venta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeleccionarProductoDialog extends StatefulWidget {
  final List<Producto> productos;
  final void Function(Producto, Presentacion, double) onSeleccionar;

  const _SeleccionarProductoDialog({
    required this.productos,
    required this.onSeleccionar,
  });

  @override
  State<_SeleccionarProductoDialog> createState() =>
      _SeleccionarProductoDialogState();
}

class _SeleccionarProductoDialogState
    extends State<_SeleccionarProductoDialog> {
  Producto? _seleccionado;
  Presentacion? _presentacion;
  final _cantidadCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Producto>(
            initialValue: _seleccionado,
            decoration: const InputDecoration(labelText: 'Producto'),
            items: widget.productos
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                          '${p.nombre} (stock: ${p.stockTotal.toStringAsFixed(1)} ${p.unidadBase})'),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() {
                _seleccionado = v;
                _presentacion = v?.presentaciones.isNotEmpty == true
                    ? v!.presentaciones.first
                    : null;
              });
            },
          ),
          if (_seleccionado != null && _seleccionado!.presentaciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<Presentacion>(
              initialValue: _presentacion,
              decoration: const InputDecoration(labelText: 'Presentación'),
              items: _seleccionado!.presentaciones
                  .map((pr) => DropdownMenuItem(
                        value: pr,
                        child: Text(
                            '${pr.nombreVisual} — ${Formatters.currency(pr.precio)}/${pr.unidad}'),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _presentacion = v),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              prefixIcon: Icon(Icons.production_quantity_limits),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            controller: _cantidadCtrl,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _seleccionado == null || _presentacion == null
              ? null
              : () {
                  final cant = double.tryParse(_cantidadCtrl.text) ?? 1;
                  widget.onSeleccionar(
                      _seleccionado!, _presentacion!, cant);
                  Navigator.pop(context);
                },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
