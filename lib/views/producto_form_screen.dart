import 'package:flutter/material.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/services/api_service.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/views/scanner_screen.dart';

final _unidades = ['kg', 'lb', 'lt', 'caja', 'docena', 'unidad'];

class _HelpIcon extends StatelessWidget {
  final String message;
  const _HelpIcon({required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ayuda'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      ),
      child: Icon(Icons.help_outline, size: 18, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class ProductoFormScreen extends StatefulWidget {
  final ProductoViewModel viewModel;
  final Producto? producto;

  const ProductoFormScreen({
    super.key,
    required this.viewModel,
    this.producto,
  });

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _costoCtrl;
  String _categoria = 'General';
  String _proveedorId = '';
  List<_VarForm> _variants = [];
  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _codigoCtrl = TextEditingController(text: p?.codigoBarras ?? '');
    _marcaCtrl = TextEditingController(text: p?.marca ?? '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '0');
    _costoCtrl = TextEditingController(text: p != null ? p.costo.toString() : '0');
    _categoria = p?.categoria ?? 'General';
    _proveedorId = p?.proveedorId ?? '';
    if (p != null && p.presentaciones.isNotEmpty) {
      _variants = p.presentaciones.map((pr) => _VarForm(
            id: pr.id,
            nombreCtrl: TextEditingController(text: pr.nombre),
            unidad: _unidades.contains(pr.unidad) ? pr.unidad : 'unidad',
            precioCtrl: TextEditingController(text: pr.precio.toString()),
          )).toList();
    } else if (p == null) {
      _variants = [_VarForm(
        id: '',
        nombreCtrl: TextEditingController(text: 'Unidad'),
        unidad: 'unidad',
        precioCtrl: TextEditingController(),
      )];
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _codigoCtrl.dispose();
    _marcaCtrl.dispose();
    _stockCtrl.dispose();
    _costoCtrl.dispose();
    for (final v in _variants) {
      v.nombreCtrl.dispose();
      v.precioCtrl.dispose();
    }
    super.dispose();
  }

  void _agregarVariant() {
    setState(() {
      _variants.add(_VarForm(
        id: '',
        nombreCtrl: TextEditingController(),
        unidad: 'unidad',
        precioCtrl: TextEditingController(text: '0'),
      ));
    });
  }

  void _quitarVariant(int index) {
    final v = _variants[index];
    v.nombreCtrl.dispose();
    v.precioCtrl.dispose();
    setState(() => _variants.removeAt(index));
  }

  Future<void> _escanearCodigo() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (codigo == null || codigo.isEmpty) return;

    _codigoCtrl.text = codigo;

    String? nombre;
    String? descripcion;
    String? marca;
    String? proveedorNombre;
    String? categoria;

    try {
      await _apiService.authenticate();
      final data = await _apiService.getProductoBarcode(codigo);
      if (data != null) {
        nombre = data['nombre'] as String?;
        descripcion = data['descripcion'] as String?;
        marca = data['marca'] as String?;
        proveedorNombre = data['proveedorNombre'] as String?;
        categoria = data['categoria'] as String?;
      }
    } catch (_) {}

    if (nombre == null || nombre.isEmpty) {
      final prod = widget.viewModel.getProductoByBarcode(codigo);
      if (prod != null) {
        nombre = prod.nombre;
        descripcion = prod.descripcion;
        marca = prod.marca;
        proveedorNombre = prod.proveedorNombre;
        categoria = prod.categoria;
      }
    }

    if (nombre == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se encontr\u00f3 un producto con este c\u00f3digo de barras'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final aceptado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(ctx).colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            const Text('Producto encontrado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campoLectura('Nombre', nombre!),
            if (descripcion != null && descripcion.isNotEmpty)
              _campoLectura('Descripci\u00f3n', descripcion),
            if (marca != null && marca.isNotEmpty)
              _campoLectura('Marca', marca),
            if (proveedorNombre != null && proveedorNombre.isNotEmpty)
              _campoLectura('Proveedor', proveedorNombre),
            if (categoria != null && categoria.isNotEmpty)
              _campoLectura('Categor\u00eda', categoria),
            const SizedBox(height: 12),
            Text(
              'Se llenar\u00e1n los datos autom\u00e1ticamente.\nStock y costo se cargar\u00e1n al registrar compras.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usar datos'),
          ),
        ],
      ),
    );

    if (aceptado == true && mounted) {
      _nombreCtrl.text = nombre;
      _descripcionCtrl.text = descripcion ?? '';
      _marcaCtrl.text = marca ?? '';
      _categoria = categoria ?? 'General';

      if (proveedorNombre != null && proveedorNombre.isNotEmpty) {
        final provId = await widget.viewModel
            .crearProveedorSiNoExiste(proveedorNombre);
        if (!mounted) return;
        _proveedorId = provId;
      }

      setState(() {});
    }
  }

  Widget _campoLectura(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una variante')),
      );
      return;
    }

    final stock = double.tryParse(_stockCtrl.text) ?? 0;
    final costo = double.tryParse(_costoCtrl.text) ?? 0;

    if (stock < 0) {
      _mostrarErrorDialog(
        'Stock inv\u00e1lido',
        'El stock no puede ser negativo.',
      );
      return;
    }
    if (costo < 0) {
      _mostrarErrorDialog(
        'Costo inv\u00e1lido',
        'El costo no puede ser negativo.',
      );
      return;
    }

    for (final v in _variants) {
      final nom = v.nombreCtrl.text.trim();
      final precio = double.tryParse(v.precioCtrl.text) ?? 0;
      if (precio <= 0) {
        _mostrarErrorDialog(
          'Precio inv\u00e1lido en "$nom"',
          'El precio de venta debe ser mayor a 0.\n\nSi no estableces un precio, no podr\u00e1s vender este producto.',
        );
        return;
      }
      if (costo > precio) {
        _mostrarErrorDialog(
          'Precio inv\u00e1lido en "$nom"',
          'El costo (S/ ${costo.toStringAsFixed(2)}) es mayor al precio de venta (S/ ${precio.toStringAsFixed(2)}).\n\n'
              'Esto significa que perder\u00e1s S/ ${(costo - precio).toStringAsFixed(2)} por cada unidad que vendas.\n\n'
              'Corrige el precio de venta o reduce el costo.',
        );
        return;
      }
    }

    final presentaciones = _variants.map((v) {
      return Presentacion(
        id: v.id,
        nombre: v.nombreCtrl.text.trim(),
        unidad: v.unidad,
        precio: double.tryParse(v.precioCtrl.text) ?? 0,
      );
    }).toList();

    final provNombre = widget.viewModel.proveedorNombre(_proveedorId);

    final producto = Producto(
      id: widget.producto?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      codigoBarras: _codigoCtrl.text.trim(),
      categoria: _categoria,
      marca: _marcaCtrl.text.trim(),
      proveedorId: _proveedorId,
      proveedorNombre: provNombre,
      stock: stock,
      costo: costo,
      presentaciones: presentaciones,
    );

    final barcode = _codigoCtrl.text.trim();
    final esNuevo = !_editando;

    if (_editando) {
      await widget.viewModel.updateProducto(producto);
    } else {
      await widget.viewModel.addProducto(producto);
    }

    if (barcode.isNotEmpty && esNuevo && mounted) {
      _contribuirAlCatalogo(barcode, producto);
    }

    if (mounted) Navigator.pop(context);
  }

  void _mostrarErrorDialog(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(fontSize: 14)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _contribuirAlCatalogo(String barcode, Producto producto) async {
    try {
      final proveedorNombre = widget.viewModel.proveedorNombre(_proveedorId);
      await _apiService.contributeBarcode(
        codigo: barcode,
        nombre: producto.nombre,
        descripcion: producto.descripcion,
        marca: producto.marca,
        proveedorNombre: proveedorNombre,
        categoria: producto.categoria,
      );
    } catch (_) {}
  }

  InputDecoration _dec(String label, IconData icon, {String? help, bool isDense = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: help != null ? _HelpIcon(message: help) : null,
      isDense: isDense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proveedores = widget.viewModel.proveedores;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Producto' : 'Nuevo Producto'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                decoration: _dec('Nombre del producto', Icons.sell_outlined,
                    help: 'Nombre con el que identificas el producto'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 14),
              // Descripci\u00f3n + Marca
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 2,
                      decoration: _dec('Descripci\u00f3n', Icons.description_outlined,
                          help: 'Opcional: sabor, tama\u00f1o, detalles del producto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _marcaCtrl,
                      decoration: _dec('Marca', Icons.badge_outlined,
                          help: 'Ej: Gloria, Nestl\u00e9, Molitalia'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Proveedor
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _proveedorId,
                decoration: _dec('Proveedor', Icons.local_shipping_outlined,
                    help: 'Selecciona qui\u00e9n te vende este producto'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Sin proveedor')),
                  ...proveedores.map((prov) => DropdownMenuItem(
                        value: prov.id,
                        child: Text(prov.nombre, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => setState(() => _proveedorId = v ?? ''),
              ),
              const SizedBox(height: 14),
              // Categor\u00eda + C\u00f3digo
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _categoria,
                      decoration: _dec('Categor\u00eda', Icons.category_outlined,
                          help: 'Organiza tu inventario y reportes'),
                      items: AppConstants.categorias
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoria = v ?? 'General'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codigoCtrl,
                      decoration: InputDecoration(
                        labelText: 'C\u00f3digo de barras',
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: _escanearCodigo,
                          tooltip: 'Escanear c\u00f3digo',
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stock + Costo (product-level)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Stock actual', Icons.inventory_2_outlined, isDense: true,
                          help: 'Cantidad disponible actualmente. Se actualizar\u00e1 con compras y ventas.'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Req';
                        final n = double.tryParse(val);
                        if (n == null) return 'Inv';
                        if (n < 0) return '<0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Tu costo x unidad', Icons.shopping_cart_outlined, isDense: true,
                          help: 'Cu\u00e1nto te cost\u00f3 adquirir este producto'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Req';
                        final n = double.tryParse(val);
                        if (n == null) return 'Inv';
                        if (n < 0) return '<0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ======== VARIANTES ========
              Row(
                children: [
                  Icon(Icons.ballot_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Presentaciones de venta', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _agregarVariant,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_variants.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Agrega al menos una presentaci\u00f3n.\nEj: "Por Kilo", "Bolsa 20kg", "Unidad"',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                )
              else
                ..._variants.asMap().entries.map((entry) {
                  final i = entry.key;
                  final v = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    surfaceTintColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Presentaci\u00f3n ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const Spacer(),
                              if (_variants.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () => _quitarVariant(i),
                                ),
                            ],
                          ),
                          // Nombre + Unidad
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: v.nombreCtrl,
                                  decoration: _dec('Nombre', Icons.label_outline, isDense: true,
                                      help: 'Ej: "Unidad", "Caja de 12", "Botella 1L"'),
                                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Req' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: v.unidad,
                                  decoration: _dec('Unidad', Icons.scale, isDense: true,
                                      help: 'C\u00f3mo se vende: kg, litros, unidades, etc.'),
                                  items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) => setState(() => v.unidad = val ?? 'unidad'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Precio (solo precio, sin costo ni stock)
                          TextFormField(
                            controller: v.precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _dec('Precio de venta', Icons.monetization_on_outlined, isDense: true,
                                help: 'Precio al que vendes esta presentaci\u00f3n'),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Req';
                              final n = double.tryParse(val);
                              if (n == null) return 'Inv';
                              if (n <= 0) return '>0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Bot\u00f3n guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _guardar,
                  icon: Icon(_editando ? Icons.save : Icons.add_circle_outline),
                  label: Text(_editando ? 'Guardar Cambios' : 'Agregar Producto'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VarForm {
  String id;
  TextEditingController nombreCtrl;
  String unidad;
  TextEditingController precioCtrl;

  _VarForm({
    required this.id,
    required this.nombreCtrl,
    required this.unidad,
    required this.precioCtrl,
  });
}
