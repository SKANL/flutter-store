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
  bool _suppressNotifications = false; // Para evitar notificaciones durante inicialización

  // Getters
  List<Product> get products => _products;
  List<Categoria> get categorias => _categorias;
  List<Proveedor> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  // Cache para productos filtrados
  List<Product>? _filteredProductsCache;
  String? _lastSearchQuery;
  String? _lastSelectedCategory;

  // Productos filtrados con cache para mejorar rendimiento
  List<Product> get filteredProducts {
    // Verificar si el cache es válido
    if (_filteredProductsCache != null &&
        _lastSearchQuery == _searchQuery &&
        _lastSelectedCategory == _selectedCategory) {
      return _filteredProductsCache!;
    }

    // Recalcular filtros
    List<Product> filtered = List.from(_products);

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

    // Guardar en cache
    _filteredProductsCache = filtered;
    _lastSearchQuery = _searchQuery;
    _lastSelectedCategory = _selectedCategory;

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
    if (_searchQuery != query) {
      _searchQuery = query;
      _clearProductsCache();
      notifyListeners();
    }
  }

  void setSelectedCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _clearProductsCache();
      notifyListeners();
    }
  }

  void clearFilters() {
    if (_searchQuery.isNotEmpty || _selectedCategory != null) {
      _searchQuery = '';
      _selectedCategory = null;
      _clearProductsCache();
      notifyListeners();
    }
  }

  void _clearProductsCache() {
    _filteredProductsCache = null;
    _lastSearchQuery = null;
    _lastSelectedCategory = null;
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
    } catch (e) {
      print('❌ [STATE] Error cargando productos: $e'); // Debug log
      _setError('Error al cargar productos: ${e.toString()}');
      rethrow;
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
    } catch (e) {
      print('❌ [STATE] Error cargando categorías: $e'); // Debug log
      _setError('Error al cargar categorías: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> loadProveedores() async {
    try {
      print('🏪 [STATE] Cargando proveedores...'); // Debug log
      final proveedores = await ApiService.getProveedores();
      _proveedores = proveedores;
      print('🏪 [STATE] ${proveedores.length} proveedores cargados'); // Debug log
    } catch (e) {
      print('❌ [STATE] Error cargando proveedores: $e'); // Debug log
      _setError('Error al cargar proveedores: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    print('🔄 [STATE] Iniciando addProduct...');
    _setLoading(true);
    _clearError();

    try {
      print('📤 [STATE] Enviando producto a API...');
      final newProduct = await ApiService.createProduct(product);
      print('✅ [STATE] Producto creado en API: ${newProduct.idProducto}');
      
      _products.add(newProduct);
      print('✅ [STATE] Producto agregado a lista local');
      
      notifyListeners();
      print('✅ [STATE] Listeners notificados');
    } catch (e) {
      print('❌ [STATE] Error en addProduct: $e');
      _setError('Error al agregar producto: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
      print('🔚 [STATE] addProduct finalizado');
    }
  }

  Future<void> updateProduct(Product product) async {
    print('🔄 [STATE] Iniciando updateProduct...');
    _setLoading(true);
    _clearError();

    try {
      print('📤 [STATE] Enviando actualización a API...');
      final updatedProduct = await ApiService.updateProduct(product);
      print('✅ [STATE] Producto actualizado en API: ${updatedProduct.idProducto}');
      
      final index = _products.indexWhere((p) => p.idProducto == product.idProducto);
      if (index != -1) {
        _products[index] = updatedProduct;
        print('✅ [STATE] Producto actualizado en lista local');
        notifyListeners();
        print('✅ [STATE] Listeners notificados');
      } else {
        print('⚠️ [STATE] Producto no encontrado en lista local');
      }
    } catch (e) {
      print('❌ [STATE] Error en updateProduct: $e');
      _setError('Error al actualizar producto: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
      print('🔚 [STATE] updateProduct finalizado');
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

  // Método optimizado para carga inicial en paralelo
  Future<void> initializeData() async {
    print('🚀 [INIT] Inicializando aplicación...');
    setSuppressNotifications(true);
    _setLoading(true);
    _clearError();

    try {
      print('⏳ [INIT] Ejecutando cargas en paralelo...');
      
      // Ejecutar cargas en paralelo para mejorar el rendimiento
      await Future.wait([
        loadCategorias(),
        loadProveedores(),
        loadProducts(),
      ]);

      print('✅ [INIT] Todas las cargas completadas exitosamente');
    } catch (e) {
      print('❌ [INIT] Error durante inicialización: $e');
      _setError('Error durante la carga inicial: ${e.toString()}');
    } finally {
      setSuppressNotifications(false);
      _setLoading(false);
      notifyListeners();
    }
  }

  // Método para notificar listeners externamente después de inicialización
  void notifyAfterInit() {
    notifyListeners();
  }

  // Método para deshabilitar notificaciones temporalmente durante inicialización
  void setSuppressNotifications(bool suppress) {
    _suppressNotifications = suppress;
  }

  // Métodos auxiliares privados
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (!_suppressNotifications) {
        notifyListeners();
      }
    }
  }

  void _setError(String error) {
    _error = error;
    if (!_suppressNotifications) {
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      if (!_suppressNotifications) {
        notifyListeners();
      }
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
