import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';
import '../core/inventory_state.dart';
import '../components/product_card.dart';
import '../models/product.dart';
import 'store_add_product_screen.dart';

class StoreInventoryScreen extends StatefulWidget {
  const StoreInventoryScreen({super.key});

  @override
  State<StoreInventoryScreen> createState() => _StoreInventoryScreenState();
}

class _StoreInventoryScreenState extends State<StoreInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Cargar productos al inicializar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = InventoryProvider.of(context);
      if (state != null && state.products.isEmpty) {
        state.loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header con estadísticas y búsqueda
          _buildHeader(),
          
          // Lista de productos
          Expanded(
            child: InventoryBuilder(
              builder: (context, state) {
                if (state.isLoading && state.products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (state.error != null) {
                  return _buildErrorView(state);
                }

                if (state.products.isEmpty) {
                  return _buildEmptyView(context);
                }

                return _buildProductsList(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0, left: 10, right: 10),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Estadísticas rápidas
            InventoryBuilder(
              builder: (context, state) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Productos',
                        '${state.totalProducts}',
                        Icons.inventory_2,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Valor Total',
                        '\$${state.totalInventoryValue.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Stock Bajo',
                        '${state.lowStockProducts.length}',
                        Icons.warning,
                        state.lowStockProducts.isNotEmpty ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Barra de búsqueda y filtros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                final state = InventoryProvider.of(context);
                                state?.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.backgroundComponent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      final state = InventoryProvider.of(context);
                      state?.setSearchQuery(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de filtros por categoría
                InventoryBuilder(
                  builder: (context, state) {
                    return PopupMenuButton<String?>(
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filtrar por categoría',
                      onSelected: (category) {
                        state.setSelectedCategory(category);
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem<String?>(
                            value: null,
                            child: Text('Todas las categorías'),
                          ),
                          ...state.categories.map((category) {
                            return PopupMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }),
                        ];
                      },
                    );
                  },
                ),
              ],
            ),
            
            // Categoría seleccionada
            InventoryBuilder(
              builder: (context, state) {
                if (state.selectedCategory != null) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Chip(
                          label: Text('Categoría: ${state.selectedCategory}'),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => state.setSelectedCategory(null),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.description.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.small.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(InventoryState state) {
    final products = state.filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: AppTextStyles.title.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta cambiar los filtros de búsqueda',
              style: AppTextStyles.description,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: state.refreshProducts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onEdit: () => _editProduct(product),
            onDelete: () => _deleteProduct(product),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Inventario vacío',
            style: AppTextStyles.title.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Agrega tu primer producto para comenzar',
            textAlign: TextAlign.center,
            style: AppTextStyles.description,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              // Navegar a pantalla de agregar producto y esperar resultado
              if (!mounted) return;
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const StoreAddProductScreen(),
                ),
              );
              if (result == true && mounted) {
                // Recargar lista e informar éxito
                final state = InventoryProvider.of(context);
                state?.loadProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto agregado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(InventoryState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar inventario',
            style: AppTextStyles.title.copyWith(
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.description,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => state.loadProducts(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProduct(Product product) async {
    // Navegar a pantalla de edición y esperar resultado
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => StoreAddProductScreen(
          productToEdit: product,
        ),
      ),
    );
    if (result == true && mounted) {
      // Recargar lista e informar actualización exitosa
      final state = InventoryProvider.of(context);
      state?.loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${product.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final state = InventoryProvider.of(context);
              if (state != null && product.idProducto != null) {
                try {
                  await state.deleteProduct(product.idProducto!);
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Producto eliminado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
