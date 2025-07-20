import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/categoria.dart';
import '../models/proveedor.dart';
import '../services/api_service.dart';

class InventoryState extends ChangeNotifier {
  List<Product> _products = [];
  List<Categoria> _categorias = [];
  List<Proveedor> _proveedores = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;

  // Getters
  List<Product> get products => _products;
  List<Categoria> get categorias => _categorias;
  List<Proveedor> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  // Productos filtrados
  List<Product> get filteredProducts {
    List<Product> filtered = _products;

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) =>
        product.nombre.toLowerCase().contains(query) ||
        product.categoryName.toLowerCase().contains(query) ||
        (product.codigoDeBarra?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Filtrar por categoría
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((product) => 
        product.categoryName == _selectedCategory
      ).toList();
    }

    return filtered;
  }

  // Obtiene todas las categorías únicas
  List<String> get categories {
    final categoriesSet = <String>{};
    for (final product in _products) {
      categoriesSet.add(product.categoryName);
    }
    return categoriesSet.toList()..sort();
  }

  // Productos con stock bajo
  List<Product> get lowStockProducts {
    return _products.where((product) => product.isLowStock).toList();
  }

  // Productos próximos a caducar
  List<Product> get expiringProducts {
    return _products.where((product) => 
      product.status == ProductStatus.expiringSoon
    ).toList();
  }

  // Productos caducados
  List<Product> get expiredProducts {
    return _products.where((product) => 
      product.status == ProductStatus.expired
    ).toList();
  }

  // Estadísticas calculadas
  double get totalInventoryValue {
    return _products.fold(0.0, (sum, product) => sum + product.totalInventoryValue);
  }

  double get totalProfit {
    return _products.fold(0.0, (sum, product) => sum + product.totalProfit);
  }

  int get totalProducts => _products.length;

  // Métodos para actualizar estado
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }

  // Métodos para interactuar con la API
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      print('📦 [STATE] Cargando productos...'); // Debug log
      final products = await ApiService.getAllProducts();
      _products = products;
      print('📦 [STATE] ${products.length} productos cargados'); // Debug log
      // Solo notificar una vez que todo esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('❌ [STATE] Error cargando productos: $e'); // Debug log
      _setError('Error al cargar productos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategorias() async {
    try {
      print('📂 [STATE] Cargando categorías...'); // Debug log
      final categorias = await ApiService.getCategorias();
      _categorias = categorias;
      print('📂 [STATE] ${categorias.length} categorías cargadas'); // Debug log
      // Solo notificar una vez que todo esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('❌ [STATE] Error cargando categorías: $e'); // Debug log
      _setError('Error al cargar categorías: ${e.toString()}');
    }
  }

  Future<void> loadProveedores() async {
    try {
      print('🏪 [STATE] Cargando proveedores...'); // Debug log
      final proveedores = await ApiService.getProveedores();
      _proveedores = proveedores;
      print('🏪 [STATE] ${proveedores.length} proveedores cargados'); // Debug log
      // Solo notificar una vez que todo esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('❌ [STATE] Error cargando proveedores: $e'); // Debug log
      _setError('Error al cargar proveedores: ${e.toString()}');
    }
  }

  Future<void> addProduct(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      final newProduct = await ApiService.createProduct(product);
      _products.add(newProduct);
      notifyListeners();
    } catch (e) {
      _setError('Error al agregar producto: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProduct(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedProduct = await ApiService.updateProduct(product);
      final index = _products.indexWhere((p) => p.idProducto == product.idProducto);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al actualizar producto: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      await ApiService.deleteProduct(productId);
      _products.removeWhere((product) => product.idProducto == productId);
      notifyListeners();
    } catch (e) {
      _setError('Error al eliminar producto: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // Métodos auxiliares privados
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      // Usar SchedulerBinding para evitar llamadas durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _setError(String error) {
    _error = error;
    // Usar SchedulerBinding para evitar llamadas durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      // Usar SchedulerBinding para evitar llamadas durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}

// InheritedWidget para proveer el estado a toda la app
class InventoryProvider extends InheritedNotifier<InventoryState> {
  const InventoryProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static InventoryState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InventoryProvider>()?.notifier;
  }

  static InventoryState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InventoryProvider>()?.notifier;
  }
}

// Widget de conveniencia para usar el estado
class InventoryBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, InventoryState state) builder;

  const InventoryBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final state = InventoryProvider.of(context);
    if (state == null) {
      throw StateError('InventoryBuilder usado sin InventoryProvider');
    }
    return builder(context, state);
  }
}
