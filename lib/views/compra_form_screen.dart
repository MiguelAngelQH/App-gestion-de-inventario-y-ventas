import 'package:flutter/material.dart';
import 'package:smart_ventas/models/compra.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/compra_viewmodel.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';

class _ItemSeleccionado {
  final Producto? producto;
  final String nombre;
  final String categoria;
  final String unidad;
  final double cantidad;
  final double costo;
  final double precioVenta;

  _ItemSeleccionado._({
    this.producto,
    required this.nombre,
    required this.categoria,
    required this.unidad,
    required this.cantidad,
    required this.costo,
    this.precioVenta = 0,
  });

  factory _ItemSeleccionado.existente(
      Producto p, double cant, double cost) {
    return _ItemSeleccionado._(
      producto: p,
      nombre: p.nombre,
      categoria: p.categoria,
      unidad: p.presentaciones.isNotEmpty ? p.presentaciones.first.nombre : 'unidad',
      cantidad: cant,
      costo: cost,
    );
  }

  factory _ItemSeleccionado.nuevo(
    String nombre,
    String categoria,
    String unidad,
    double cant,
    double cost,
    {double precioVenta = 0}
  ) {
    return _ItemSeleccionado._(
      producto: null,
      nombre: nombre,
      categoria: categoria,
      unidad: unidad,
      cantidad: cant,
      costo: cost,
      precioVenta: precioVenta,
    );
  }

  bool get esNuevo => producto == null;
  String get productoId => producto?.id ?? '';
  String get presentacionNombre => unidad;
  double get subtotal => cantidad * costo;
}

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
  String? _proveedorId;
  String _proveedorNombre = '';
  bool _esCredito = false;
  final _items = <_ItemSeleccionado>[];
  bool _guardando = false;

  @override
  void dispose() {
    super.dispose();
  }

  double get _total => _items.fold(0, (s, i) => s + i.subtotal);
  List<Proveedor> get _proveedores => widget.compraViewModel.proveedores;

  void _agregarProducto() {
    final productos = widget.productoViewModel.productos;

    showDialog(
      context: context,
      builder: (ctx) => _SeleccionarProductoCompraDialog(
        productos: productos,
        categorias: AppConstants.categorias,
        onSeleccionar: (item) {
          setState(() => _items.add(item));
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
    if (_proveedorNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proveedor')),
      );
      return;
    }

    for (final item in _items) {
      if (item.esNuevo && item.precioVenta <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.nombre}": debe tener un precio de venta mayor a 0'),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _guardando = true);

    final itemsCompra = <ItemCompra>[];

    for (final item in _items) {
      String pid;
      String presNombre;

      if (item.esNuevo) {
        final nuevoId = await widget.compraViewModel.crearProductoDesdeCompra(
          nombre: item.nombre,
          categoria: item.categoria,
          unidad: item.unidad,
          costo: item.costo,
          stock: item.cantidad,
          precioVenta: item.precioVenta,
          proveedorId: _proveedorId ?? '',
          proveedorNombre: _proveedorNombre,
        );
        if (nuevoId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al crear producto')),
            );
            setState(() => _guardando = false);
          }
          return;
        }
        pid = nuevoId;
        presNombre = item.unidad;
      } else {
        pid = item.productoId;
        presNombre = item.presentacionNombre;
      }

      itemsCompra.add(ItemCompra(
        productoId: pid,
        productoNombre: item.nombre,
        categoria: item.categoria,
        presentacionId: '',
        presentacionNombre: presNombre,
        cantidad: item.cantidad,
        costoUnitario: item.costo,
      ));
    }

    final compra = Compra(
      id: '',
      fecha: DateTime.now(),
      proveedorId: _proveedorId ?? '',
      proveedorNombre: _proveedorNombre,
      items: itemsCompra,
      total: _total,
      estado: 'recibida',
      credito: _esCredito,
    );

    final id = await widget.compraViewModel.addCompra(compra);
    if (mounted) {
      if (id != null) {
        final msg = _esCredito
            ? 'Compra registrada. Deuda actualizada.'
            : 'Compra registrada. Stock actualizado.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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
                // Proveedor
                _buildProveedorSelector(theme),
                const SizedBox(height: 16),
                // Tipo de pago
                _buildTipoPago(theme),
                const SizedBox(height: 20),
                // Productos
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
                            title: Text(entry.value.nombre),
                            subtitle: Text(
                              '${entry.value.cantidad} ${entry.value.unidad} x ${Formatters.currency(entry.value.costo)}',
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

  Widget _buildProveedorSelector(ThemeData theme) {
    final ids = _proveedores.map((p) => p.id).toSet();
    assert(ids.length == _proveedores.length, 'IDs de proveedores duplicados');

    final valorValido = _proveedorId != null &&
        _proveedorId!.isNotEmpty &&
        _proveedores.any((p) => p.id == _proveedorId);

    return DropdownButtonFormField<String>(
      initialValue: valorValido ? _proveedorId : null,
      decoration: const InputDecoration(
        labelText: 'Proveedor',
        prefixIcon: Icon(Icons.business),
      ),
      items: [
        if (_proveedores.isEmpty)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('No hay proveedores \u2014 crea uno'),
          )
        else
          ..._proveedores.map((prov) => DropdownMenuItem<String>(
                value: prov.id,
                child: Text(prov.nombre),
              )),
        const DropdownMenuItem<String>(
          value: '__nuevo__',
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('Nuevo proveedor...'),
            ],
          ),
        ),
      ],
      onChanged: (v) async {
        if (v == '__nuevo__') {
          final nombre = await _mostrarNuevoProveedor(context);
          if (nombre != null && nombre.isNotEmpty) {
            final id = await widget.compraViewModel.crearProveedorSiNoExiste(nombre);
            if (mounted) {
              setState(() {
                _proveedorId = id;
                _proveedorNombre = nombre;
              });
            }
          }
        } else if (v != null) {
          final prov = _proveedores.firstWhere((p) => p.id == v);
          setState(() {
            _proveedorId = v;
            _proveedorNombre = prov.nombre;
          });
        }
      },
    );
  }

  Future<String?> _mostrarNuevoProveedor(BuildContext context) async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dialogCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Nuevo Proveedor'),
          content: TextField(
            controller: dialogCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre del proveedor',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, dialogCtrl.text.trim()),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
    return nombre;
  }

  Widget _buildTipoPago(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.payments_outlined,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Tipo de pago:'),
            const Spacer(),
            ChoiceChip(
              label: const Text('Contado'),
              selected: !_esCredito,
              onSelected: (_) => setState(() => _esCredito = false),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Cr\u00e9dito'),
              selected: _esCredito,
              onSelected: (_) => setState(() => _esCredito = true),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeleccionarProductoCompraDialog extends StatefulWidget {
  final List<Producto> productos;
  final List<String> categorias;
  final void Function(_ItemSeleccionado) onSeleccionar;

  const _SeleccionarProductoCompraDialog({
    required this.productos,
    required this.categorias,
    required this.onSeleccionar,
  });

  @override
  State<_SeleccionarProductoCompraDialog> createState() =>
      _SeleccionarProductoCompraDialogState();
}

class _SeleccionarProductoCompraDialogState
    extends State<_SeleccionarProductoCompraDialog> {
  final _searchCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _costoCtrl = TextEditingController(text: '0');
  final _precioVentaCtrl = TextEditingController(text: '0');
  final _nuevoNombreCtrl = TextEditingController();
  String _busqueda = '';
  Producto? _seleccionado;
  String _unidad = 'unidad';
  bool _modoNuevo = false;
  String _nuevaCategoria = 'General';

  List<Producto> get _productosFiltrados {
    if (_busqueda.isEmpty) return widget.productos;
    final q = _busqueda.toLowerCase();
    return widget.productos
        .where((p) => p.nombre.toLowerCase().contains(q))
        .toList();
  }

  bool get _hayCoincidenciaExacta =>
      widget.productos.any((p) => p.nombre.toLowerCase() == _busqueda.toLowerCase());

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _busqueda = _searchCtrl.text.trim();
        if (_busqueda.isEmpty) {
          _modoNuevo = false;
          _seleccionado = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cantidadCtrl.dispose();
    _costoCtrl.dispose();
    _precioVentaCtrl.dispose();
    _nuevoNombreCtrl.dispose();
    super.dispose();
  }

  void _seleccionarExistente(Producto p) {
    setState(() {
      _seleccionado = p;
      _modoNuevo = false;
      _costoCtrl.text = p.costo.toStringAsFixed(2);
      _unidad = p.presentaciones.isNotEmpty ? p.presentaciones.first.nombre : 'unidad';
    });
  }

  void _entrarModoNuevo() {
    setState(() {
      _modoNuevo = true;
      _seleccionado = null;
      _unidad = 'unidad';
      _costoCtrl.text = '0';
      _precioVentaCtrl.text = '0';
      _nuevoNombreCtrl.text = _busqueda;
    });
  }

  bool _validar() {
    final cant = double.tryParse(_cantidadCtrl.text) ?? 0;
    final costo = double.tryParse(_costoCtrl.text) ?? 0;
    if (cant <= 0) return false;
    if (costo < 0) return false;
    if (_modoNuevo) {
      final pv = double.tryParse(_precioVentaCtrl.text) ?? 0;
      return _nuevoNombreCtrl.text.trim().isNotEmpty && pv > 0;
    }
    return _seleccionado != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),

            // Search results or new product option
            if (!_modoNuevo && _busqueda.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_productosFiltrados.isEmpty)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text(
                          'Crear "$_busqueda"',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                        subtitle: const Text('Nuevo producto'),
                        onTap: _entrarModoNuevo,
                      )
                    else ...[
                      ..._productosFiltrados.take(5).map(
                            (p) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(p.nombre, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              subtitle: p.marca.isNotEmpty
                                  ? Text(p.marca,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant))
                                  : null,
                              selected: _seleccionado?.id == p.id,
                              onTap: () => _seleccionarExistente(p),
                            ),
                          ),
                      if (!_hayCoincidenciaExacta)
                        ListTile(
                          dense: true,
                          leading: Icon(Icons.add_circle_outline,
                              size: 20, color: theme.colorScheme.primary),
                          title: Text(
                            'Crear "$_busqueda"',
                            style: TextStyle(
                                fontSize: 13, color: theme.colorScheme.primary),
                          ),
                          onTap: _entrarModoNuevo,
                        ),
                    ],
                  ],
                ),
              ),

            // New product: name + category + unit
            if (_modoNuevo) ...[
              TextField(
                controller: _nuevoNombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _nuevaCategoria,
                decoration: const InputDecoration(
                  labelText: 'Categor\u00eda',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _nuevaCategoria = v ?? 'General'),
              ),
              const SizedBox(height: 8),
            ],

            // Unit (always visible when no product selected or in new mode)
            if (_seleccionado == null || _modoNuevo)
              DropdownButtonFormField<String>(
                initialValue: _unidad,
                decoration: const InputDecoration(
                  labelText: 'Unidad',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _unidades
                    .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _unidad = v ?? 'unidad'),
              ),

            const SizedBox(height: 12),

            // Quantity and cost
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: _seleccionado != null
                          ? 'Cantidad (stock: ${_seleccionado!.stock.toStringAsFixed(1)})'
                          : 'Cantidad',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    controller: _cantidadCtrl,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Costo x unidad',
                      prefixText: 'S/ ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    controller: _costoCtrl,
                  ),
                ),
              ],
            ),
            if (_modoNuevo) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Precio de venta',
                  prefixText: 'S/ ',
                  hintText: 'A cu\u00e1nto lo vender\u00e1s',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                keyboardType: TextInputType.number,
                controller: _precioVentaCtrl,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: !_validar()
              ? null
              : () {
                  final cant = double.tryParse(_cantidadCtrl.text) ?? 1;
                  final costo = double.tryParse(_costoCtrl.text) ?? 0;
                  if (cant <= 0 || costo < 0) return;
                  if (_modoNuevo) {
                    final nombre = _nuevoNombreCtrl.text.trim();
                    final pv = double.tryParse(_precioVentaCtrl.text) ?? 0;
                    widget.onSeleccionar(_ItemSeleccionado.nuevo(nombre, _nuevaCategoria, _unidad, cant, costo, precioVenta: pv));
                  } else if (_seleccionado != null) {
                    widget.onSeleccionar(_ItemSeleccionado.existente(
                        _seleccionado!, cant, costo));
                  }
                  Navigator.pop(context);
                },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

const _unidades = ['kg', 'lb', 'lt', 'caja', 'docena', 'unidad', 'saco', 'pack', 'bolsa', 'botella'];
