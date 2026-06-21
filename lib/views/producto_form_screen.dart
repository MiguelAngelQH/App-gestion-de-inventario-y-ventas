import 'package:flutter/material.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/models/proveedor.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';

final _unidadesMedida = [
  'kg', 'lb', 'lt', 'caja', 'docena', 'unidad',
];

class _HelpIcon extends StatelessWidget {
  final String message;
  const _HelpIcon({required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
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
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _costoCtrl;
  String _categoria = 'General';
  String _unidad = 'kg';
  String _proveedorId = '';
  bool _variantsExpanded = false;
  List<_VariantForm> _variants = [];
  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _codigoCtrl = TextEditingController(text: p?.codigoBarras ?? '');
    _stockCtrl = TextEditingController(text: p?.stockTotal.toString() ?? '0');
    _marcaCtrl = TextEditingController(text: p?.marca ?? '');
    _precioCtrl = TextEditingController(text: p?.precio.toString() ?? '0');
    _costoCtrl = TextEditingController(text: p?.costo.toString() ?? '0');
    _categoria = p?.categoria ?? 'General';
    _unidad = p?.unidadBase ?? 'kg';
    _proveedorId = p?.proveedorId ?? '';
    if (p != null && p.presentaciones.isNotEmpty) {
      _variantsExpanded = true;
      _variants = p.presentaciones
          .map((pr) => _VariantForm(
                id: pr.id,
                nombreVisualCtrl: TextEditingController(text: pr.nombreVisual),
                unidad: pr.unidad,
                precioCtrl: TextEditingController(text: pr.precio.toString()),
                costoCtrl: TextEditingController(text: pr.costo.toString()),
                factorCtrl: TextEditingController(text: pr.factor.toString()),
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _codigoCtrl.dispose();
    _stockCtrl.dispose();
    _marcaCtrl.dispose();
    _precioCtrl.dispose();
    _costoCtrl.dispose();
    for (final v in _variants) {
      v.nombreVisualCtrl.dispose();
      v.precioCtrl.dispose();
      v.costoCtrl.dispose();
      v.factorCtrl.dispose();
    }
    super.dispose();
  }

  void _agregarVariant() {
    setState(() {
      _variants.add(_VariantForm(
        id: '',
        nombreVisualCtrl: TextEditingController(),
        unidad: _unidad,
        precioCtrl: TextEditingController(text: '0'),
        costoCtrl: TextEditingController(text: '0'),
        factorCtrl: TextEditingController(text: '1'),
      ));
    });
  }

  void _quitarVariant(int index) {
    final v = _variants[index];
    v.nombreVisualCtrl.dispose();
    v.precioCtrl.dispose();
    v.costoCtrl.dispose();
    v.factorCtrl.dispose();
    setState(() => _variants.removeAt(index));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final precio = double.tryParse(_precioCtrl.text) ?? 0;
    final costo = double.tryParse(_costoCtrl.text) ?? 0;

    List<Presentacion> presentaciones;
    if (_variantsExpanded && _variants.isNotEmpty) {
      presentaciones = _variants.map((v) {
        return Presentacion(
          id: v.id,
          nombreVisual: v.nombreVisualCtrl.text.trim(),
          unidad: v.unidad,
          precio: double.tryParse(v.precioCtrl.text) ?? 0,
          costo: double.tryParse(v.costoCtrl.text) ?? 0,
          factor: double.tryParse(v.factorCtrl.text) ?? 1,
        );
      }).toList();
    } else {
      presentaciones = [
        Presentacion(
          id: '',
          nombreVisual: 'Unidad',
          unidad: _unidad,
          precio: precio,
          costo: costo,
          factor: 1,
        ),
      ];
    }

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
      unidadBase: _unidad,
      stockTotal: double.tryParse(_stockCtrl.text) ?? 0,
      precio: precio,
      costo: costo,
      presentaciones: presentaciones,
    );

    if (_editando) {
      await widget.viewModel.updateProducto(producto);
    } else {
      await widget.viewModel.addProducto(producto);
    }

    if (mounted) Navigator.pop(context);
  }

  InputDecoration _dec(String label, IconData icon, {String? help}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: help != null ? _HelpIcon(message: help) : null,
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
                    help: 'Nombre con el que identificas el producto en tu tienda'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Descripción + Marca
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 2,
                      decoration: _dec('Descripción', Icons.description_outlined,
                          help: 'Información adicional opcional (sabor, presentación, etc.)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _marcaCtrl,
                      decoration: _dec('Marca', Icons.badge_outlined,
                          help: 'Nombre de la marca del producto (ej: Gloria, Nestlé, Molitalia)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Proveedor
              DropdownButtonFormField<String>(
                initialValue: _proveedorId,
                decoration: _dec('Proveedor', Icons.local_shipping_outlined,
                    help: 'Selecciona el proveedor que te vende este producto'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Sin proveedor')),
                  ...proveedores.map((prov) => DropdownMenuItem(
                        value: prov.id,
                        child: Text(prov.nombre),
                      )),
                ],
                onChanged: (v) => setState(() => _proveedorId = v ?? ''),
              ),
              const SizedBox(height: 16),

              // Unidad + Stock
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unidad,
                      decoration: _dec('Unidad', Icons.scale,
                          help: 'Cómo se mide este producto: kg, litros, unidades, etc.'),
                      items: _unidadesMedida
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _unidad = v ?? 'kg');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Stock actual', Icons.inventory_2_outlined,
                          help: 'Cantidad disponible actualmente en tu inventario'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categoría + Código barras
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: _dec('Categoría', Icons.category_outlined,
                          help: 'Clasifica el producto para organizar tu inventario y reportes'),
                      items: AppConstants.categorias
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _categoria = v ?? 'General'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codigoCtrl,
                      decoration: _dec('Código de barras', Icons.qr_code,
                          help: 'Código único del producto (EAN-13). Puedes escanearlo con la cámara'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Precio + Costo
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Precio de venta', Icons.monetization_on_outlined,
                          help: 'Precio al que vendes este producto al cliente'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Costo', Icons.shopping_cart_outlined,
                          help: 'Cuánto te costó adquirir este producto (tu costo)'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Variants section (collapsible)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _variantsExpanded = !_variantsExpanded),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.ballot_outlined, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              'Variantes del producto',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  content: const Text(
                                    'Si vendes este producto en diferentes formatos (ej: "Por Kilo" y "Bolsa 20kg"), '
                                    'agrégalos aquí. Si solo tienes un formato, puedes ignorar esta sección.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Entendido'),
                                    ),
                                  ],
                                ),
                              ),
                              child: Icon(Icons.help_outline, size: 18, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: _variantsExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.expand_more),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_variantsExpanded) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (_variants.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Aún no hay variantes. Agrega una si vendes este producto en varios formatos.',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ..._variants.asMap().entries.map((entry) {
                                final i = entry.key;
                                final v = entry.value;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  surfaceTintColor: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Text('Variante ${i + 1}',
                                                style: const TextStyle(fontWeight: FontWeight.w600)),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                              onPressed: () => _quitarVariant(i),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: v.nombreVisualCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Nombre',
                                            hintText: 'Ej: Por Kilo, Caja 20kg',
                                            isDense: true,
                                          ),
                                          validator: (val) =>
                                              (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                initialValue: v.unidad,
                                                decoration: const InputDecoration(
                                                  labelText: 'Unidad',
                                                  isDense: true,
                                                ),
                                                items: _unidadesMedida
                                                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                                    .toList(),
                                                onChanged: (val) {
                                                  setState(() {
                                                    v.unidad = val ?? _unidad;
                                                    if (v.unidad == _unidad) v.factorCtrl.text = '1';
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                controller: v.factorCtrl,
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Factor',
                                                  hintText: '1 $_unidad = ?',
                                                  isDense: true,
                                                ),
                                                validator: (val) {
                                                  if (val == null || val.isEmpty) return 'Req';
                                                  final f = double.tryParse(val);
                                                  if (f == null || f <= 0) return 'Inv';
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: v.precioCtrl,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                decoration: const InputDecoration(
                                                  labelText: 'Precio',
                                                  prefixText: 'S/ ',
                                                  isDense: true,
                                                ),
                                                validator: (val) {
                                                  if (val == null || val.isEmpty) return 'Req';
                                                  if (double.tryParse(val) == null) return 'Inv';
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                controller: v.costoCtrl,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                decoration: const InputDecoration(
                                                  labelText: 'Costo',
                                                  prefixText: 'S/ ',
                                                  isDense: true,
                                                ),
                                                validator: (val) {
                                                  if (val == null || val.isEmpty) return 'Req';
                                                  if (double.tryParse(val) == null) return 'Inv';
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _agregarVariant,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Agregar variante'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _guardar,
                  icon: Icon(_editando ? Icons.save : Icons.add_circle_outline),
                  label: Text(_editando ? 'Guardar Cambios' : 'Agregar Producto'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

class _VariantForm {
  String id;
  TextEditingController nombreVisualCtrl;
  String unidad;
  TextEditingController precioCtrl;
  TextEditingController costoCtrl;
  TextEditingController factorCtrl;

  _VariantForm({
    required this.id,
    required this.nombreVisualCtrl,
    required this.unidad,
    required this.precioCtrl,
    required this.costoCtrl,
    required this.factorCtrl,
  });
}
