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
// ...existing code...
}

class _StoreInventoryScreenState extends State<StoreInventoryScreen> {
  bool _isDeleting = false;
  final TextEditingController _searchController = TextEditingController();
  int? _statRevealedIndex;
  // Cache para widgets reutilizables
  static const Key _refreshIndicatorKey = Key('inventory_refresh_indicator');
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final state = InventoryProvider.of(context);
      state?.setSearchQuery(_searchController.text);
    });
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
    return Stack(
      children: [
        Container(
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
        ),
        if (_isDeleting)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
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
            InventoryBuilder(
              builder: (context, state) {
                final stats = [
                  {
                    'title': 'Productos',
                    'value': '${state.totalProducts}',
                    'icon': Icons.inventory_2,
                    'color': AppColors.primary,
                  },
                  {
                    'title': 'Valor Total',
                    'value': '\$${state.totalInventoryValue.toStringAsFixed(2)}',
                    'icon': Icons.attach_money,
                    'color': Colors.green,
                  },
                  {
                    'title': 'Stock Bajo',
                    'value': '${state.lowStockProducts.length}',
                    'icon': Icons.warning,
                    'color': state.lowStockProducts.isNotEmpty ? Colors.red : Colors.grey,
                  },
                ];
                if (_statRevealedIndex != null) {
                  final i = _statRevealedIndex!;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: SizedBox(
                      key: ValueKey('stat-revealed-$i'),
                      width: double.infinity,
                      child: _buildRevealStatCard(
                        stats[i]['title'] as String,
                        stats[i]['value'] as String,
                        stats[i]['icon'] as IconData,
                        stats[i]['color'] as Color,
                        i,
                        isFullWidth: true,
                      ),
                    ),
                  );
                } else {
                  return Row(
                    children: List.generate(stats.length, (i) =>
                      Expanded(
                        child: _buildRevealStatCard(
                          stats[i]['title'] as String,
                          stats[i]['value'] as String,
                          stats[i]['icon'] as IconData,
                          stats[i]['color'] as Color,
                          i,
                          isFullWidth: false,
                        ),
                      ),
                    ).expand((w) => [w, if (w != stats.last) const SizedBox(width: 12)]).toList()..removeLast(),
                  );
                }
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
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.backgroundComponent,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          PopupMenuItem<String?>(
                            value: null,
                            child: const Text('Todas las categorías'),
                          ),
                          ...state.categorias.map((cat) => PopupMenuItem<String?>(
                            value: cat.nombre,
                            child: Text(cat.nombre),
                          )),
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

  Widget _buildRevealStatCard(String title, String value, IconData icon, Color color, int index, {required bool isFullWidth}) {
    final isRevealed = _statRevealedIndex == index;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withOpacity(0.10),
        onTap: () {
          setState(() {
            _statRevealedIndex = isRevealed ? null : index;
          });
          if (!isRevealed) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _statRevealedIndex == index) {
                setState(() {
                  _statRevealedIndex = null;
                });
              }
            });
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: isRevealed
              ? Container(
                  key: ValueKey('value$index'),
                  width: isFullWidth ? double.infinity : null,
                  padding: EdgeInsets.symmetric(vertical: isFullWidth ? 24 : 18, horizontal: isFullWidth ? 32 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.13),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: color.withOpacity(0.22), width: 1.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: isFullWidth ? 38 : 28,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: isFullWidth ? 24 : 18,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  key: ValueKey('icon$index'),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.13),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: color.withOpacity(0.22), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 38),
                  ),
                ),
        ),
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
      key: _refreshIndicatorKey,
      color: AppColors.primary,
      onRefresh: state.refreshProducts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: products.length,
        // Optimizaciones de rendimiento para ListView
        cacheExtent: 500, // Cache más elementos fuera de pantalla
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            key: ValueKey('product_${product.idProducto}'), // Key único para optimizar rebuilds
            product: product,
            onEdit: () => _editProduct(product),
            onDelete: () => _deleteProduct(product),
            showDeleteButton: true,
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
                if (context.mounted) {
                  final state = InventoryProvider.of(context);
                  state?.loadProducts();
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
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      // Recargar lista e informar actualización exitosa
      final state = InventoryProvider.of(context);
      try {
        await state?.loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) Navigator.of(context).pop(); // Cierra el loader
      }
    }
  }

  void _deleteProduct(Product product) {
    if (!mounted || !context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${product.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (!mounted || !context.mounted) return;
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              setState(() => _isDeleting = true);
              final state = InventoryProvider.of(context);
              try {
                if (state != null && product.idProducto != null) {
                  await state.deleteProduct(product.idProducto!);
                  await state.loadProducts();
                  if (mounted && context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Producto eliminado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isDeleting = false);
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
