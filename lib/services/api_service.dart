import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://your-api.com/api'; // Cambiar por tu API real
  
  // Simulamos datos para desarrollo
  static final List<Product> _mockProducts = [
    Product(
      id: '1',
      name: 'Leche Entera 1L',
      category: 'Lácteos',
      barcode: '7501234567890',
      stock: 25,
      minStock: 10,
      costPrice: 18.50,
      salePrice: 25.00,
      expiryDate: DateTime.now().add(const Duration(days: 15)),
    ),
    Product(
      id: '2',
      name: 'Pan de Caja Integral',
      category: 'Panadería',
      barcode: '7501234567891',
      stock: 8,
      minStock: 5,
      costPrice: 22.00,
      salePrice: 32.00,
      expiryDate: DateTime.now().add(const Duration(days: 5)),
    ),
    Product(
      id: '3',
      name: 'Detergente Liquido 1L',
      category: 'Limpieza',
      stock: 12,
      minStock: 8,
      costPrice: 35.00,
      salePrice: 48.00,
    ),
  ];

  // Simula delay de red
  static Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Obtiene todos los productos
  static Future<List<Product>> getAllProducts() async {
    await _simulateNetworkDelay();
    // TODO: Implementar llamada real a la API de C#
    // final response = await http.get(Uri.parse('$baseUrl/products'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Product.fromJson(json)).toList();
    // }
    // throw Exception('Error al obtener productos');
    
    return List.from(_mockProducts);
  }

  // Obtiene un producto por ID
  static Future<Product?> getProductById(String id) async {
    await _simulateNetworkDelay();
    // TODO: Implementar llamada real a la API de C#
    // final response = await http.get(Uri.parse('$baseUrl/products/$id'));
    // if (response.statusCode == 200) {
    //   return Product.fromJson(json.decode(response.body));
    // }
    // return null;
    
    return _mockProducts.firstWhere(
      (product) => product.id == id,
      orElse: () => throw StateError('Producto no encontrado'),
    );
  }

  // Crea un nuevo producto
  static Future<Product> createProduct(Product product) async {
    await _simulateNetworkDelay();
    // TODO: Implementar llamada real a la API de C#
    // final response = await http.post(
    //   Uri.parse('$baseUrl/products'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(product.toJson()),
    // );
    // if (response.statusCode == 201) {
    //   return Product.fromJson(json.decode(response.body));
    // }
    // throw Exception('Error al crear producto');
    
    final newProduct = product.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _mockProducts.add(newProduct);
    return newProduct;
  }

  // Actualiza un producto existente
  static Future<Product> updateProduct(Product product) async {
    await _simulateNetworkDelay();
    // TODO: Implementar llamada real a la API de C#
    // final response = await http.put(
    //   Uri.parse('$baseUrl/products/${product.id}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(product.toJson()),
    // );
    // if (response.statusCode == 200) {
    //   return Product.fromJson(json.decode(response.body));
    // }
    // throw Exception('Error al actualizar producto');
    
    final index = _mockProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _mockProducts[index] = product.copyWith(updatedAt: DateTime.now());
      return _mockProducts[index];
    }
    throw Exception('Producto no encontrado');
  }

  // Elimina un producto
  static Future<void> deleteProduct(String id) async {
    await _simulateNetworkDelay();
    // TODO: Implementar llamada real a la API de C#
    // final response = await http.delete(Uri.parse('$baseUrl/products/$id'));
    // if (response.statusCode != 204) {
    //   throw Exception('Error al eliminar producto');
    // }
    
    _mockProducts.removeWhere((product) => product.id == id);
  }

  // Busca productos por nombre o categoría
  static Future<List<Product>> searchProducts(String query) async {
    await _simulateNetworkDelay();
    // TODO: Implementar llamada real a la API de C#
    // final response = await http.get(
    //   Uri.parse('$baseUrl/products/search?q=$query')
    // );
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Product.fromJson(json)).toList();
    // }
    // throw Exception('Error en la búsqueda');
    
    final lowercaseQuery = query.toLowerCase();
    return _mockProducts.where((product) =>
      product.name.toLowerCase().contains(lowercaseQuery) ||
      product.category.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Obtiene productos por categoría
  static Future<List<Product>> getProductsByCategory(String category) async {
    await _simulateNetworkDelay();
    return _mockProducts.where((product) => product.category == category).toList();
  }

  // Obtiene productos con stock bajo
  static Future<List<Product>> getLowStockProducts() async {
    await _simulateNetworkDelay();
    return _mockProducts.where((product) => product.isLowStock).toList();
  }

  // Obtiene productos próximos a caducar
  static Future<List<Product>> getExpiringProducts() async {
    await _simulateNetworkDelay();
    return _mockProducts.where((product) => 
      product.status == ProductStatus.expiringSoon
    ).toList();
  }

  // Obtiene estadísticas del inventario
  static Future<InventoryStats> getInventoryStats() async {
    await _simulateNetworkDelay();
    final products = await getAllProducts();
    
    return InventoryStats(
      totalProducts: products.length,
      totalValue: products.fold(0.0, (sum, product) => sum + product.totalInventoryValue),
      totalProfit: products.fold(0.0, (sum, product) => sum + product.totalProfit),
      lowStockCount: products.where((p) => p.isLowStock).length,
      expiringCount: products.where((p) => p.status == ProductStatus.expiringSoon).length,
      expiredCount: products.where((p) => p.status == ProductStatus.expired).length,
    );
  }
}

class InventoryStats {
  final int totalProducts;
  final double totalValue;
  final double totalProfit;
  final int lowStockCount;
  final int expiringCount;
  final int expiredCount;

  InventoryStats({
    required this.totalProducts,
    required this.totalValue,
    required this.totalProfit,
    required this.lowStockCount,
    required this.expiringCount,
    required this.expiredCount,
  });
}
