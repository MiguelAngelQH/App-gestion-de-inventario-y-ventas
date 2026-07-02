import 'package:flutter/material.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/venta.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/viewmodels/venta_viewmodel.dart';
import 'package:smart_ventas/views/scanner_screen.dart';

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
            p.stock > 0 && !_items.any((i) => i.productoId == p.id))
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
              presentacionNombre: presentacion.nombre,
              cantidad: cantidad,
              precioUnitario: presentacion.precio,
              costoUnitario: producto.costo,
            ));
          });
        },
      ),
    );
  }

  Future<void> _escanearCodigo() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (codigo == null || codigo.isEmpty) return;
    if (!mounted) return;

    final encontrado = widget.productoViewModel.getProductoByBarcode(codigo);

    if (encontrado == null) {
      _mostrarNoEncontrado(codigo);
      return;
    }
    if (!mounted) return;

    if (_items.any((i) => i.productoId == encontrado.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${encontrado.nombre} ya est\u00e1 en la venta'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (encontrado.presentaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${encontrado.nombre} no tiene variantes'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _agregarDesdeProducto(encontrado);
  }

  void _mostrarNoEncontrado(String codigo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Producto no encontrado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('C\u00f3digo escaneado: $codigo',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay un producto con este c\u00f3digo de barras en tu inventario.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Para agregarlo, ve a Productos y usa el esc\u00e1ner desde el formulario de nuevo producto.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarDesdeProducto(Producto producto) async {
    final esUnica = producto.presentaciones.length == 1;
    var presentacion = esUnica ? producto.presentaciones.first : null;
    final ctrl = TextEditingController(text: '1');

    final result = await showDialog<MapEntry<Presentacion, double>>(
      context: context,
      builder: (ctx) {
        var sel = presentacion;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final pr = sel;
            final stock = producto.stock;
            final cantVal = double.tryParse(ctrl.text);
            final cantOk = cantVal != null && cantVal > 0;
            final stockOk = cantVal != null && cantVal <= stock;
            final puedeAgregar = pr != null && cantOk && stockOk;
            final pierde = pr != null && producto.costo > pr.precio;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(pierde ? Icons.warning_amber_rounded : Icons.shopping_cart,
                    color: pierde ? Colors.orange : Theme.of(ctx).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(producto.nombre, style: const TextStyle(fontSize: 18))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (esUnica) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sell, size: 18, color: Theme.of(ctx).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(presentacion!.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text(Formatters.currency(presentacion.precio),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(ctx).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          if (pierde) ...[
                            const SizedBox(height: 4),
                            Text('Costo: ${Formatters.currency(producto.costo)} — se vende con p\u00e9rdida',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text('Costo: ${Formatters.currency(producto.costo)} — Ganancia: ${Formatters.currency(presentacion.precio - producto.costo)}',
                              style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<Presentacion>(
                      isExpanded: true,
                      initialValue: sel,
                      decoration: const InputDecoration(
                        labelText: 'Variante',
                        prefixIcon: Icon(Icons.sell),
                      ),
                      items: producto.presentaciones
                          .map((pr) => DropdownMenuItem(
                                value: pr,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(pr.nombre, overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${Formatters.currency(pr.precio)}/${pr.unidad}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(ctx).colorScheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => sel = v),
                    ),
                    if (pierde)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Costo S/ ${producto.costo.toStringAsFixed(2)} — se vende con p\u00e9rdida',
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Cantidad (stock: ${stock.toStringAsFixed(1)})',
                      prefixIcon: const Icon(Icons.production_quantity_limits),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: ctrl,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (pr != null && cantVal != null && cantVal > stock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Stock insuficiente: solo tienes ${stock.toStringAsFixed(1)} unidades',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: puedeAgregar
                      ? () => Navigator.pop(ctx, MapEntry(pr, cantVal))
                      : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(pr != null
                      ? (!cantOk
                          ? 'Cantidad inv\u00e1lida'
                          : !stockOk
                              ? 'Stock insuficiente'
                              : 'Agregar a la venta')
                      : 'Selecciona variante'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      final pr = result.key;
      final cantidad = result.value;
      setState(() {
        _items.add(ItemVenta(
          productoId: producto.id,
          productoNombre: producto.nombre,
          categoria: producto.categoria,
          presentacionId: pr.id,
          presentacionNombre: pr.nombre,
          cantidad: cantidad,
          precioUnitario: pr.precio,
          costoUnitario: producto.costo,
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto.nombre} agregado (${cantidad.toStringAsFixed(0)} ${pr.nombre})'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                  isExpanded: true,
                  initialValue: _metodoPago,
                  decoration: const InputDecoration(
                    labelText: 'M\u00e9todo de pago',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: AppConstants.metodosPago
                      .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
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
                    IconButton(
                      onPressed: _escanearCodigo,
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Escanear c\u00f3digo de barras',
                    ),
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
              isExpanded: true,
              initialValue: _seleccionado,
              decoration: const InputDecoration(labelText: 'Producto'),
              items: widget.productos
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.nombre} (stock: ${p.stock.toStringAsFixed(1)})', overflow: TextOverflow.ellipsis),
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
                isExpanded: true,
                initialValue: _presentacion,
                decoration: const InputDecoration(labelText: 'Variante'),
                items: _seleccionado!.presentaciones
                    .map((pr) => DropdownMenuItem(
                          value: pr,
                          child: Text('${pr.nombre} — ${Formatters.currency(pr.precio)}/${pr.unidad}', overflow: TextOverflow.ellipsis),
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
