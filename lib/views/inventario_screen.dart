import 'package:flutter/material.dart';
import 'package:smart_ventas/models/producto.dart';
import 'package:smart_ventas/utils/formatters.dart';
import 'package:smart_ventas/viewmodels/producto_viewmodel.dart';
import 'package:smart_ventas/views/producto_form_screen.dart';
import 'package:smart_ventas/widgets/reusable_widgets.dart';

class InventarioScreen extends StatelessWidget {
  final ProductoViewModel viewModel;

  const InventarioScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildSearchBar(theme),
              _buildFilterChips(theme),
              Expanded(
                child: viewModel.productos.isEmpty
                    ? const EmptyState(
                        icono: Icons.inventory_2_outlined,
                        mensaje: 'No se encontraron productos',
                        subtitulo:
                            'Agrega tu primer producto con el botón +',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: viewModel.productos.length,
                        itemBuilder: (context, index) {
                          final producto = viewModel.productos[index];
                          return _buildProductoCard(
                              context, theme, producto);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductoFormScreen(
              viewModel: viewModel,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          TextField(
            onChanged: viewModel.setBusqueda,
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${viewModel.productos.length} productos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Stock bajo'),
                selected: viewModel.soloStockBajo,
                onSelected: (_) =>
                    viewModel.setSoloStockBajo(!viewModel.soloStockBajo),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final categorias = viewModel.categorias;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categorias[index];
          final seleccionada = viewModel.categoriaSeleccionada == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: seleccionada,
            onSelected: (_) => viewModel.setCategoria(cat),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildProductoCard(
      BuildContext context, ThemeData theme, Producto producto) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductoFormScreen(
              viewModel: viewModel,
              producto: producto,
            ),
          ),
        ),
        onLongPress: () => _confirmarEliminar(context, producto),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.sell_outlined,
                          Formatters.currency(producto.precio),
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.category_outlined,
                          producto.categoria,
                          theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: producto.stockBajo
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${producto.stock}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            producto.stockBajo ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'uds',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              viewModel.deleteProducto(producto.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String texto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
