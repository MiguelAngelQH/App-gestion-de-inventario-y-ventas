import 'package:flutter/material.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/utils/constants.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';

final _unidadesMedida = [
  'kg', 'lb', 'lt', 'caja', 'docena', 'unidad',
];

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
  String _categoria = 'General';
  String _unidadBase = 'kg';
  List<_PresForm> _presentaciones = [];
  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _codigoCtrl = TextEditingController(text: p?.codigoBarras ?? '');
    _stockCtrl = TextEditingController(text: p?.stockTotal.toString() ?? '0');
    _categoria = p?.categoria ?? 'General';
    _unidadBase = p?.unidadBase ?? 'kg';
    if (p != null) {
      _presentaciones = p.presentaciones
          .map((pr) => _PresForm(
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
    for (final p in _presentaciones) {
      p.nombreVisualCtrl.dispose();
      p.precioCtrl.dispose();
      p.costoCtrl.dispose();
      p.factorCtrl.dispose();
    }
    super.dispose();
  }

  void _agregarPresentacion() {
    setState(() {
      _presentaciones.add(_PresForm(
        id: '',
        nombreVisualCtrl: TextEditingController(),
        unidad: _unidadBase,
        precioCtrl: TextEditingController(text: '0'),
        costoCtrl: TextEditingController(text: '0'),
        factorCtrl: TextEditingController(
            text: _presentaciones.isEmpty ? '1' : '1'),
      ));
    });
  }

  void _quitarPresentacion(int index) {
    final p = _presentaciones[index];
    p.nombreVisualCtrl.dispose();
    p.precioCtrl.dispose();
    p.costoCtrl.dispose();
    p.factorCtrl.dispose();
    setState(() => _presentaciones.removeAt(index));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_presentaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una presentación')),
      );
      return;
    }

    final presList = _presentaciones.map((p) {
      return Presentacion(
        id: p.id,
        nombreVisual: p.nombreVisualCtrl.text.trim(),
        unidad: p.unidad,
        precio: double.tryParse(p.precioCtrl.text) ?? 0,
        costo: double.tryParse(p.costoCtrl.text) ?? 0,
        factor: double.tryParse(p.factorCtrl.text) ?? 1,
      );
    }).toList();

    final producto = Producto(
      id: widget.producto?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      codigoBarras: _codigoCtrl.text.trim(),
      categoria: _categoria,
      unidadBase: _unidadBase,
      stockTotal: double.tryParse(_stockCtrl.text) ?? 0,
      presentaciones: presList,
    );

    if (_editando) {
      await widget.viewModel.updateProducto(producto);
    } else {
      await widget.viewModel.addProducto(producto);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unidadBase,
                      decoration: const InputDecoration(
                        labelText: 'Unidad Base',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      items: _unidadesMedida
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _unidadBase = v ?? 'kg');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Stock Total',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Código barras',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Presentaciones',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _agregarPresentacion,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_presentaciones.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Agrega al menos una presentación\n(ej: Por Kilo, Caja 20kg)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ..._presentaciones.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Presentación ${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () => _quitarPresentacion(i),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: p.nombreVisualCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre visual',
                              hintText: 'Ej: Por Kilo, Caja 20kg',
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: p.unidad,
                                  decoration: const InputDecoration(
                                    labelText: 'Unidad',
                                    isDense: true,
                                  ),
                                  items: _unidadesMedida
                                      .map((u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      p.unidad = v ?? _unidadBase;
                                      if (p.unidad == _unidadBase) {
                                        p.factorCtrl.text = '1';
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: p.factorCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Factor',
                                    hintText: '1 $_unidadBase = ?',
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Req';
                                    }
                                    final f = double.tryParse(v);
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
                                  controller: p.precioCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Precio',
                                    prefixText: 'S/ ',
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Req';
                                    if (double.tryParse(v) == null) {
                                      return 'Inv';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: p.costoCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Costo',
                                    prefixText: 'S/ ',
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Req';
                                    if (double.tryParse(v) == null) {
                                      return 'Inv';
                                    }
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _guardar,
                  icon: Icon(
                      _editando ? Icons.save : Icons.add_circle_outline),
                  label: Text(
                      _editando ? 'Guardar Cambios' : 'Agregar Producto'),
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

class _PresForm {
  String id;
  TextEditingController nombreVisualCtrl;
  String unidad;
  TextEditingController precioCtrl;
  TextEditingController costoCtrl;
  TextEditingController factorCtrl;

  _PresForm({
    required this.id,
    required this.nombreVisualCtrl,
    required this.unidad,
    required this.precioCtrl,
    required this.costoCtrl,
    required this.factorCtrl,
  });
}
