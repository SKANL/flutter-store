import 'package:flutter/material.dart';
import 'dart:async';
import '../models/product.dart';
import '../models/categoria.dart';
import '../models/proveedor.dart';
import '../services/api_service.dart';
import '../core/app_logger.dart';
import '../services/background_task_service.dart';

class InventoryState extends ChangeNotifier {
  List<Product> _products = [];
  List<Categoria> _categorias = [];
  List<Proveedor> _proveedores = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _suppressNotifications = false; // Para evitar notificaciones durante inicialización

  // Timer para debouncing de búsqueda
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  // Cache optimizado para productos filtrados
  List<Product>? _filteredProductsCache;
  String? _lastSearchQuery;
  String? _lastSelectedCategory;
  
  // Cache para estadísticas calculadas para evitar recálculos innecesarios
  double? _totalInventoryValueCache;
  double? _totalProfitCache;
  List<Product>? _lowStockProductsCache;
  List<Product>? _expiringProductsCache;
  List<Product>? _expiredProductsCache;
  List<String>? _categoriesCache;

  // Getters básicos
  List<Product> get products => _products;
  List<Categoria> get categorias => _categorias;
  List<Proveedor> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // Limpiar todos los caches cuando los productos cambian
  void _clearCalculatedCaches() {
    _filteredProductsCache = null;
    _totalInventoryValueCache = null;
    _totalProfitCache = null;
    _lowStockProductsCache = null;
    _expiringProductsCache = null;
    _expiredProductsCache = null;
    _categoriesCache = null;
  }

  // Productos filtrados con cache optimizado para mejor rendimiento
  List<Product> get filteredProducts {
    // Verificar si el cache es válido
    if (_filteredProductsCache != null &&
        _lastSearchQuery == _searchQuery &&
        _lastSelectedCategory == _selectedCategory) {
      return _filteredProductsCache!;
    }

    // Recalcular filtros solo cuando sea necesario
    List<Product> filtered = List.from(_products);

    // Filtrar por búsqueda con optimización
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final nombre = product.nombre.toLowerCase();
        final categoria = product.categoryName.toLowerCase();
        final codigo = product.codigoDeBarra?.toLowerCase();
        
        return nombre.contains(query) ||
               categoria.contains(query) ||
               (codigo != null && codigo.contains(query));
      }).toList();
    }

    // Filtrar por categoría
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((product) => 
        product.categoryName == _selectedCategory,
      ).toList();
    }

    // Guardar en cache
    _filteredProductsCache = filtered;
    _lastSearchQuery = _searchQuery;
    _lastSelectedCategory = _selectedCategory;

    return filtered;
  }

  // Obtiene todas las categorías únicas con cache
  List<String> get categories {
    if (_categoriesCache != null) {
      return _categoriesCache!;
    }

    final categoriesSet = <String>{};
    for (final product in _products) {
      categoriesSet.add(product.categoryName);
    }
    
    _categoriesCache = categoriesSet.toList()..sort();
    return _categoriesCache!;
  }

  // Productos con stock bajo con cache
  List<Product> get lowStockProducts {
    if (_lowStockProductsCache != null) {
      return _lowStockProductsCache!;
    }
    
    _lowStockProductsCache = _products.where((product) => product.isLowStock).toList();
    return _lowStockProductsCache!;
  }

  // Productos próximos a caducar con cache
  List<Product> get expiringProducts {
    if (_expiringProductsCache != null) {
      return _expiringProductsCache!;
    }
    
    _expiringProductsCache = _products.where((product) => 
      product.status == ProductStatus.expiringSoon,
    ).toList();
    return _expiringProductsCache!;
  }

  // Productos caducados con cache
  List<Product> get expiredProducts {
    if (_expiredProductsCache != null) {
      return _expiredProductsCache!;
    }
    
    _expiredProductsCache = _products.where((product) => 
      product.status == ProductStatus.expired,
    ).toList();
    return _expiredProductsCache!;
  }

  // Estadísticas calculadas con cache para evitar recálculos costosos
  double get totalInventoryValue {
    if (_totalInventoryValueCache != null) {
      return _totalInventoryValueCache!;
    }
    
    _totalInventoryValueCache = _products.fold(0.0, (sum, product) => (sum ?? 0.0) + product.totalInventoryValue);
    return _totalInventoryValueCache!;
  }

  double get totalProfit {
    if (_totalProfitCache != null) {
      return _totalProfitCache!;
    }
    
    _totalProfitCache = _products.fold(0.0, (sum, product) => (sum ?? 0.0) + product.totalProfit);
    return _totalProfitCache!;
  }

  int get totalProducts => _products.length;

  // Métodos para actualizar estado con optimizaciones de rendimiento
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      
      // Cancelar timer anterior si existe
      _searchDebounceTimer?.cancel();
      
      // Aplicar debouncing para evitar filtrado excesivo durante escritura rápida
      _searchDebounceTimer = Timer(_searchDebounceDelay, () {
        _clearProductsCache();
        if (!_suppressNotifications) {
          notifyListeners();
        }
      });
    }
  }

  // Método inmediato para casos donde no necesitamos debouncing
  void setSearchQueryImmediate(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _clearProductsCache();
      if (!_suppressNotifications) {
        notifyListeners();
      }
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
      AppLogger.debug('Cargando productos...', 'INVENTORY');
      final products = await BackgroundTaskService.runAsyncWithYield(
        () => ApiService.getAllProducts(),
        taskName: 'loadProducts',
      );
      
      if (products != null) {
        _products = products;
        _clearCalculatedCaches(); // Limpiar caches al actualizar productos
        AppLogger.info('${products.length} productos cargados', 'INVENTORY');
      } else {
        AppLogger.warning('No se pudieron cargar productos', 'INVENTORY');
        _products = [];
        _clearCalculatedCaches(); // También limpiar al vaciar
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error cargando productos', 'INVENTORY', e, stackTrace);
      _setError('Error al cargar productos: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategorias() async {
    try {
      AppLogger.debug('Cargando categorías...', 'INVENTORY');
      final categorias = await BackgroundTaskService.runAsyncWithYield(
        () => ApiService.getCategorias(),
        taskName: 'loadCategorias',
      );
      
      if (categorias != null) {
        _categorias = categorias;
        AppLogger.info('${categorias.length} categorías cargadas', 'INVENTORY');
      } else {
        AppLogger.warning('No se pudieron cargar categorías', 'INVENTORY');
        _categorias = [];
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error cargando categorías', 'INVENTORY', e, stackTrace);
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

  // --- MÉTODOS CRUD PARA PROVEEDORES ---

  Future<void> addProveedor(Proveedor proveedor) async {
    _setLoading(true);
    _clearError();

    try {
      final newProveedor = await ApiService.createProveedor(proveedor);
      _proveedores.add(newProveedor);
      notifyListeners();
    } catch (e) {
      _setError('Error al agregar proveedor: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProveedor(Proveedor proveedor) async {
    _setLoading(true);
    _clearError();

    try {
      await ApiService.updateProveedor(proveedor);
      
      final index = _proveedores.indexWhere((p) => p.idProveedor == proveedor.idProveedor);
      if (index != -1) {
        _proveedores[index] = proveedor;
      }
      notifyListeners();
    } catch (e) {
      _setError('Error al actualizar proveedor: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProveedor(int proveedorId) async {
    _setLoading(true);
    _clearError();

    try {
      await ApiService.deleteProveedor(proveedorId);
      _proveedores.removeWhere((proveedor) => proveedor.idProveedor == proveedorId);
      notifyListeners();
    } catch (e) {
      _setError('Error al eliminar proveedor: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- MÉTODOS CRUD PARA CATEGORÍAS ---
  Future<void> createCategoria(Categoria categoria) async {
    _setLoading(true);
    _clearError();
    try {
      final newCat = await ApiService.createCategoria(categoria);
      _categorias.add(newCat);
      notifyListeners();
    } catch (e) {
      _setError('Error al crear categoría: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCategoria(Categoria categoria) async {
    _setLoading(true);
    _clearError();
    try {
      await ApiService.updateCategoria(categoria);
      final idx = _categorias.indexWhere((c) => c.idCategoria == categoria.idCategoria);
      if (idx != -1) {
        _categorias[idx] = categoria;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al actualizar categoría: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategoria(int idCategoria) async {
    _setLoading(true);
    _clearError();
    try {
      await ApiService.deleteCategoria(idCategoria);
      _categorias.removeWhere((c) => c.idCategoria == idCategoria);
      notifyListeners();
    } catch (e) {
      _setError('Error al eliminar categoría: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // Método optimizado para carga inicial en paralelo con yield points
  Future<void> initializeData() async {
    print('🚀 [INIT] Inicializando aplicación...');
    setSuppressNotifications(true);
    _setLoading(true);
    _clearError();

    try {
      print('⏳ [INIT] Ejecutando cargas en paralelo...');
      
      // Dividir la carga en chunks para dar tiempo al hilo principal
      final List<Future<void>> loadTasks = [
        _loadWithYield(loadCategorias),
        _loadWithYield(loadProveedores),
        _loadWithYield(loadProducts),
      ];
      
      // Ejecutar en paralelo pero con yield points
      await Future.wait(loadTasks);

      print('✅ [INIT] Todas las cargas completadas exitosamente');
    } catch (e) {
      print('❌ [INIT] Error durante inicialización: $e');
      _setError('Error durante la carga inicial: ${e.toString()}');
    } finally {
      setSuppressNotifications(false);
      _setLoading(false);
      // Yield antes de notificar para evitar bloqueos
      await Future.microtask(() {});
      notifyListeners();
    }
  }

  // Helper para añadir yield points durante las cargas
  Future<void> _loadWithYield(Future<void> Function() loadFunction) async {
    await Future.microtask(() {});  // Yield point antes
    await loadFunction();
    await Future.microtask(() {});  // Yield point después
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
