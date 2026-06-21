import 'package:flutter/material.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/precios_viewmodel.dart';

class ConfiguracionPreciosScreen extends StatelessWidget {
  final PreciosViewModel viewModel;

  const ConfiguracionPreciosScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Precios'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.flat.isEmpty) {
            return const Center(
              child: Text('No hay productos con presentaciones'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.flat.length,
            itemBuilder: (context, index) {
              final item = viewModel.flat[index];
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
                        onSave: (v) => viewModel.actualizarPrecio(
                            prod.id, pres.id, v),
                      ),
                      const SizedBox(width: 8),
                      _PriceField(
                        label: 'Costo',
                        value: pres.costo,
                        onSave: (v) => viewModel.actualizarCosto(
                            prod.id, pres.id, v),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onSave;

  const _PriceField({
    required this.label,
    required this.value,
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editar(BuildContext context) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $label'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: 'S/ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v >= 0) {
                onSave(v);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
