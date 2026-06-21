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
        heroTag: null,
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondary) => ProductoFormScreen(
              viewModel: viewModel,
            ),
            transitionsBuilder: (context, animation, secondary, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
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
      margin: const EdgeInsets.only(bottom: 10),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondary) => ProductoFormScreen(
              viewModel: viewModel,
              producto: producto,
            ),
            transitionsBuilder: (context, animation, secondary, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        onLongPress: () => _confirmarEliminar(context, producto),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                          if (producto.marca.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              producto.marca,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: producto.presentaciones.map((pr) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${Formatters.currency(pr.precio)}/${pr.unidad}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme
                                      .colorScheme.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: producto.stockBajo
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          producto.stockTotal % 1 == 0
                              ? '${producto.stockTotal.toInt()}'
                              : producto.stockTotal.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: producto.stockBajo
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        Text(
                          'stock',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: producto.stockBajo
                                ? Colors.red.withValues(alpha: 0.7)
                                : Colors.green.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
}
