import 'package:flutter/material.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/precios_viewmodel.dart';

class ConfiguracionPreciosScreen extends StatefulWidget {
  final PreciosViewModel viewModel;

  const ConfiguracionPreciosScreen({super.key, required this.viewModel});

  @override
  State<ConfiguracionPreciosScreen> createState() =>
      _ConfiguracionPreciosScreenState();
}

class _ConfiguracionPreciosScreenState
    extends State<ConfiguracionPreciosScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Precios'),
        centerTitle: true,
      ),
      body: widget.viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.viewModel.flat.isEmpty
          ? const Center(child: Text('No hay productos con presentaciones'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.viewModel.flat.length,
              itemBuilder: (context, index) {
                final item = widget.viewModel.flat[index];
                final pres = item.presentacion;
                final prod = item.producto;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                pres.nombre,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    _PriceField(
                      label: 'Precio',
                      value: pres.precio,
                      pairedValue: pres.costo,
                      pairedLabel: 'Costo',
                      isPrecio: true,
                      onSave: (v) => widget.viewModel.actualizarPrecio(
                        prod.id,
                        pres.id,
                        v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PriceField(
                      label: 'Costo',
                      value: pres.costo,
                      pairedValue: pres.precio,
                      pairedLabel: 'Precio',
                      isPrecio: false,
                      onSave: (v) => widget.viewModel.actualizarCosto(
                        prod.id,
                        pres.id,
                        v,
                      ),
                    ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final double value;
  final double pairedValue;
  final String pairedLabel;
  final bool isPrecio;
  final ValueChanged<double> onSave;

  const _PriceField({
    required this.label,
    required this.value,
    required this.pairedValue,
    required this.pairedLabel,
    required this.isPrecio,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _editar(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              Formatters.currency(value),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _editar(BuildContext context) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(2));
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Editar $label'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              prefixText: 'S/ ',
              border: const OutlineInputBorder(),
              errorText: error,
            ),
            onChanged: (_) => setDialogState(() => error = null),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text);
                if (v == null) {
                  setDialogState(() => error = 'Ingresa un n\u00famero v\u00e1lido');
                  return;
                }
                if (v < 0) {
                  setDialogState(() => error = 'No puede ser negativo');
                  return;
                }
                if (isPrecio && v < pairedValue) {
                  setDialogState(() => error = 'El precio no puede ser menor al costo (${Formatters.currency(pairedValue)})');
                  return;
                }
                if (!isPrecio && v > pairedValue) {
                  setDialogState(() => error = 'El costo no puede superar al precio (${Formatters.currency(pairedValue)})');
                  return;
                }
                onSave(v);
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
