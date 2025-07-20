import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class InventoryState extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;

  // Getters
  List<Product> get products => _products;
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
        product.name.toLowerCase().contains(query) ||
        product.category.toLowerCase().contains(query) ||
        (product.barcode?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Filtrar por categoría
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((product) => 
        product.category == _selectedCategory
      ).toList();
    }

    return filtered;
  }

  // Obtiene todas las categorías únicas
  List<String> get categories {
    final categoriesSet = <String>{};
    for (final product in _products) {
      categoriesSet.add(product.category);
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
      _products = await ApiService.getAllProducts();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar productos: ${e.toString()}');
    } finally {
      _setLoading(false);
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
      final index = _products.indexWhere((p) => p.id == product.id);
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

  Future<void> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await ApiService.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
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
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

// InheritedWidget para proveer el estado a toda la app
class InventoryProvider extends InheritedNotifier<InventoryState> {
  const InventoryProvider({
    Key? key,
    required InventoryState notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

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
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = InventoryProvider.of(context);
    if (state == null) {
      throw StateError('InventoryBuilder usado sin InventoryProvider');
    }
    return builder(context, state);
  }
}
