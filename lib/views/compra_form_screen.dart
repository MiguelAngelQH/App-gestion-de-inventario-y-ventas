import 'package:flutter/material.dart';
import 'package:smart_ventas/models/compra.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/compra_viewmodel.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';

class CompraFormScreen extends StatefulWidget {
  final CompraViewModel compraViewModel;
  final ProductoViewModel productoViewModel;

  const CompraFormScreen({
    super.key,
    required this.compraViewModel,
    required this.productoViewModel,
  });

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final _proveedorCtrl = TextEditingController();
  final _items = <ItemCompra>[];
  bool _guardando = false;

  @override
  void dispose() {
    _proveedorCtrl.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0, (s, i) => s + i.subtotal);

  void _agregarProducto() {
    final productos = widget.productoViewModel.productos
        .where((p) => !_items.any((i) => i.productoId == p.id))
        .toList();

    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _SeleccionarProductoCompraDialog(
        productos: productos,
        onSeleccionar: (producto, presentacion, cantidad, costo) {
          setState(() {
            _items.add(ItemCompra(
              productoId: producto.id,
              productoNombre: producto.nombre,
              categoria: producto.categoria,
              presentacionId: presentacion.id,
              presentacionNombre: presentacion.nombreVisual,
              factor: presentacion.factor,
              cantidad: cantidad,
              costoUnitario: costo,
            ));
          });
        },
      ),
    );
  }

  void _quitarItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _guardarCompra() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }
    if (_proveedorCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre del proveedor')),
      );
      return;
    }

    setState(() => _guardando = true);

    final compra = Compra(
      id: '',
      fecha: DateTime.now(),
      proveedorId: '',
      proveedorNombre: _proveedorCtrl.text.trim(),
      items: List.from(_items),
      total: _total,
      estado: 'recibida',
    );

    final id = await widget.compraViewModel.addCompra(compra);
    if (mounted) {
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compra registrada. Stock actualizado.')),
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
        title: const Text('Nueva Compra'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _proveedorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    prefixIcon: Icon(Icons.business),
                  ),
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
                          'Agrega productos a la compra',
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
                              '${entry.value.cantidad} ${entry.value.presentacionNombre} x ${Formatters.currency(entry.value.costoUnitario)}',
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
                      onPressed: _guardando ? null : _guardarCompra,
                      icon: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                          _guardando ? 'Guardando...' : 'Registrar Compra'),
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

class _SeleccionarProductoCompraDialog extends StatefulWidget {
  final List<Producto> productos;
  final void Function(Producto, Presentacion, double, double) onSeleccionar;

  const _SeleccionarProductoCompraDialog({
    required this.productos,
    required this.onSeleccionar,
  });

  @override
  State<_SeleccionarProductoCompraDialog> createState() =>
      _SeleccionarProductoCompraDialogState();
}

class _SeleccionarProductoCompraDialogState
    extends State<_SeleccionarProductoCompraDialog> {
  Producto? _seleccionado;
  Presentacion? _presentacion;
  final _cantidadCtrl = TextEditingController(text: '1');
  final _costoCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _costoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Producto>(
            initialValue: _seleccionado,
            decoration: const InputDecoration(labelText: 'Producto'),
            items: widget.productos
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.nombre),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() {
                _seleccionado = v;
                _presentacion = v?.presentaciones.isNotEmpty == true
                    ? v!.presentaciones.first
                    : null;
                if (_presentacion != null) {
                  _costoCtrl.text = _presentacion!.costo.toStringAsFixed(2);
                }
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
                            '${pr.nombreVisual} — ${Formatters.currency(pr.costo)}/${pr.unidad}'),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _presentacion = v;
                  if (v != null) {
                    _costoCtrl.text = v.costo.toStringAsFixed(2);
                  }
                });
              },
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
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Costo unitario',
              prefixText: 'S/ ',
              prefixIcon: Icon(Icons.money_off),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            controller: _costoCtrl,
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
                  final costo = double.tryParse(_costoCtrl.text) ?? 0;
                  widget.onSeleccionar(
                      _seleccionado!, _presentacion!, cant, costo);
                  Navigator.pop(context);
                },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
