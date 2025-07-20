import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/categoria.dart';
import '../models/proveedor.dart';
import '../models/producto_caducidad.dart';
import '../models/venta.dart';
import '../models/detalle_venta.dart';
import '../core/api_config.dart';

class ApiService {
  // Cache estático para mejorar rendimiento
  static List<Categoria>? _categoriasCache;
  static List<Proveedor>? _proveedoresCache;
  static List<ProductoCaducidad>? _caducidadesCache;
  static DateTime? _categoriasLastFetch;
  static DateTime? _proveedoresLastFetch;
  static DateTime? _caducidadesLastFetch;
  
  // Duración del cache en minutos
  static const int _cacheDurationMinutes = 5;
  
  // Métodos para limpiar cache cuando sea necesario
  static void clearCache() {
    _categoriasCache = null;
    _proveedoresCache = null;
    _caducidadesCache = null;
    _categoriasLastFetch = null;
    _proveedoresLastFetch = null;
    _caducidadesLastFetch = null;
  }
  
  static bool _isCacheValid(DateTime? lastFetch) {
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch).inMinutes < _cacheDurationMinutes;
  }
  
  // Headers comunes
  static Map<String, String> get _headers => ApiConfig.defaultHeaders;

  // Manejo de errores HTTP
  static void _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        throw BadRequestException('Solicitud inválida: ${response.body}');
      case 404:
        throw NotFoundException('Recurso no encontrado');
      case 500:
        throw ServerException('Error interno del servidor');
      default:
        if (response.statusCode >= 400) {
          throw HttpException('Error HTTP ${response.statusCode}: ${response.body}');
        }
    }
  }

  // --- CATEGORIAS ---
  
  static Future<List<Categoria>> getCategorias() async {
    // Verificar cache primero
    if (_isCacheValid(_categoriasLastFetch)) {
      print('🧠 [CACHE] Usando categorías desde caché (${_categoriasCache?.length} items)');
      return _categoriasCache!;
    }

    try {
      final url = '${ApiConfig.currentBaseUrl}${ApiEndpoints.categorias}';
      print('🌐 [API] Intentando conectar a: $url'); // Debug log
      
      final response = await http
          .get(
            Uri.parse(url), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      print('🌐 [API] Respuesta recibida: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('🌐 [API] Categorías encontradas: ${jsonList.length}'); // Debug log
        
        // Actualizar caché
        _categoriasCache = jsonList.map((json) => Categoria.fromJson(json)).toList();
        _categoriasLastFetch = DateTime.now();
        print('🧠 [CACHE] Categorías guardadas en caché');
        
        return _categoriasCache!;
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ [API] Error en getCategorias: $e'); // Debug log
      throw _mapException(e);
    }
  }

  static Future<Categoria?> getCategoriaById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.categoriaById(id)}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Categoria.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      }
      
      _handleHttpError(response);
      return null;
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Categoria> createCategoria(Categoria categoria) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.categorias}'),
            headers: _headers,
            body: json.encode(categoria.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        return Categoria.fromJson(json.decode(response.body));
      }
      
      _handleHttpError(response);
      throw ServerException('Error al crear categoría');
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> updateCategoria(Categoria categoria) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.categoriaById(categoria.idCategoria!)}'),
            headers: _headers,
            body: json.encode(categoria.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        return;
      }
      
      _handleHttpError(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> deleteCategoria(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.categoriaById(id)}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        return;
      }
      
      _handleHttpError(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  // --- PROVEEDORES ---

  static Future<List<Proveedor>> getProveedores() async {
    // Verificar cache primero
    if (_isCacheValid(_proveedoresLastFetch)) {
      print('🧠 [CACHE] Usando proveedores desde caché (${_proveedoresCache?.length} items)');
      return _proveedoresCache!;
    }

    try {
      final url = '${ApiConfig.currentBaseUrl}${ApiEndpoints.proveedores}';
      print('🌐 [API] Intentando conectar a: $url'); // Debug log
      
      final response = await http
          .get(
            Uri.parse(url), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      print('🌐 [API] Respuesta recibida: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('🌐 [API] Proveedores encontrados: ${jsonList.length}'); // Debug log
        
        // Actualizar caché
        _proveedoresCache = jsonList.map((json) => Proveedor.fromJson(json)).toList();
        _proveedoresLastFetch = DateTime.now();
        print('🧠 [CACHE] Proveedores guardados en caché');
        
        return _proveedoresCache!;
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ [API] Error en getProveedores: $e'); // Debug log
      throw _mapException(e);
    }
  }

  static Future<Proveedor?> getProveedorById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.proveedorById(id)}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Proveedor.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      }
      
      _handleHttpError(response);
      return null;
    } catch (e) {
      throw _mapException(e);
    }
  }

  // --- PRODUCTOS ---

  static Future<List<Product>> getAllProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productos}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final products = jsonList.map((json) => Product.fromJson(json)).toList();
        
        // Enriquecer productos con información de categorías y caducidades
        return await _enrichProducts(products);
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Product?> getProductById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoById(id)}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final product = Product.fromJson(json.decode(response.body));
        final enrichedProducts = await _enrichProducts([product]);
        return enrichedProducts.isNotEmpty ? enrichedProducts.first : product;
      } else if (response.statusCode == 404) {
        return null;
      }
      
      _handleHttpError(response);
      return null;
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Product> createProduct(Product product) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productos}'),
            headers: _headers,
            body: json.encode(product.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final createdProduct = Product.fromJson(json.decode(response.body));
        
        // Si tiene fecha de caducidad, crear el registro de caducidad
        if (product.fechaCaducidad != null && createdProduct.idProducto != null) {
          final caducidad = ProductoCaducidad(
            idProducto: createdProduct.idProducto!,
            fechaCaducidad: product.fechaCaducidad!,
          );
          await createProductoCaducidad(caducidad);
        }
        
        // Retornar producto enriquecido
        final enrichedProducts = await _enrichProducts([createdProduct]);
        return enrichedProducts.isNotEmpty ? enrichedProducts.first : createdProduct;
      }
      
      _handleHttpError(response);
      throw ServerException('Error al crear producto');
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Product> updateProduct(Product product) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoById(product.idProducto!)}'),
            headers: _headers,
            body: json.encode(product.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        // Actualizar caducidades si es necesario
        if (product.idProducto != null) {
          await _updateProductCaducidades(product.idProducto!, product.caducidades);
        }
        
        // Obtener el producto actualizado
        final updatedProduct = await getProductById(product.idProducto!);
        return updatedProduct ?? product;
      }
      
      _handleHttpError(response);
      throw ServerException('Error al actualizar producto');
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> deleteProduct(int id) async {
    try {
      // Primero eliminar las caducidades relacionadas
      final caducidades = await getProductoCaducidadesByProducto(id);
      for (final caducidad in caducidades) {
        if (caducidad.idProductoCaducidad != null) {
          await deleteProductoCaducidad(caducidad.idProductoCaducidad!);
        }
      }
      
      // Luego eliminar el producto
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoById(id)}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        return;
      }
      
      _handleHttpError(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  // --- PRODUCTO CADUCIDAD ---

  static Future<List<ProductoCaducidad>> getAllProductosCaducidad() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoCaducidad}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ProductoCaducidad.fromJson(json)).toList();
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<List<ProductoCaducidad>> getProductoCaducidadesByProducto(int idProducto) async {
    // Optimización: usar getAllProductosCaducidad y filtrar en memoria
    final todasLasCaducidades = await getAllProductosCaducidad();
    return todasLasCaducidades
        .where((caducidad) => caducidad.idProducto == idProducto)
        .toList();
  }

  static Future<ProductoCaducidad> createProductoCaducidad(ProductoCaducidad caducidad) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoCaducidad}'),
            headers: _headers,
            body: json.encode(caducidad.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        return ProductoCaducidad.fromJson(json.decode(response.body));
      }
      
      _handleHttpError(response);
      throw ServerException('Error al crear caducidad');
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> deleteProductoCaducidad(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoCaducidadById(id)}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        return;
      }
      
      _handleHttpError(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  // --- MÉTODOS AUXILIARES ---

  static Future<List<Product>> _enrichProducts(List<Product> products) async {
    if (products.isEmpty) return products;

    try {
      // Cargar categorías, proveedores y TODAS las caducidades en paralelo
      final categoriasFuture = getCategorias();
      final proveedoresFuture = getProveedores();
      final caducidadesFuture = getAllProductosCaducidad(); // Una sola consulta para todas las caducidades
      
      final categorias = await categoriasFuture;
      final proveedores = await proveedoresFuture;
      final todasLasCaducidades = await caducidadesFuture;

      // Mapear por ID para búsqueda rápida
      final categoriasMap = {for (var c in categorias) c.idCategoria: c};
      final proveedoresMap = {for (var p in proveedores) p.idProveedor: p};
      
      // Agrupar caducidades por producto para búsqueda O(1)
      final caducidadesPorProducto = <int, List<ProductoCaducidad>>{};
      for (final caducidad in todasLasCaducidades) {
        caducidadesPorProducto.putIfAbsent(caducidad.idProducto, () => [])
            .add(caducidad);
      }

      // Enriquecer productos
      final enrichedProducts = <Product>[];
      
      for (final product in products) {
        final categoria = categoriasMap[product.idCategoria];
        final proveedor = product.idProveedor != null 
            ? proveedoresMap[product.idProveedor] 
            : null;
        
        // Obtener caducidades del producto desde el mapa (O(1))
        final caducidades = product.idProducto != null
            ? caducidadesPorProducto[product.idProducto!] ?? <ProductoCaducidad>[]
            : <ProductoCaducidad>[];

        enrichedProducts.add(product.copyWith(
          categoria: categoria,
          proveedor: proveedor,
          caducidades: caducidades,
        ));
      }

      return enrichedProducts;
    } catch (e) {
      // Si falla el enriquecimiento, devolver productos básicos
      return products;
    }
  }

  static Future<void> _updateProductCaducidades(int idProducto, List<ProductoCaducidad> nuevasCaducidades) async {
    try {
      // Obtener caducidades actuales
      final caducidadesActuales = await getProductoCaducidadesByProducto(idProducto);
      
      // Eliminar caducidades existentes
      for (final caducidad in caducidadesActuales) {
        if (caducidad.idProductoCaducidad != null) {
          await deleteProductoCaducidad(caducidad.idProductoCaducidad!);
        }
      }
      
      // Crear nuevas caducidades
      for (final caducidad in nuevasCaducidades) {
        await createProductoCaducidad(ProductoCaducidad(
          idProducto: idProducto,
          fechaCaducidad: caducidad.fechaCaducidad,
        ));
      }
    } catch (e) {
      // No fallar si hay problema con caducidades - Log para debugging
      // En producción, usar un logger apropiado como flutter's developer log
      // import 'dart:developer' as developer;
      // developer.log('Error actualizando caducidades: $e', name: 'ApiService');
    }
  }

  // Métodos de búsqueda y filtrado
  static Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final lowercaseQuery = query.toLowerCase();
    
    return products.where((product) =>
      product.nombre.toLowerCase().contains(lowercaseQuery) ||
      product.categoryName.toLowerCase().contains(lowercaseQuery) ||
      (product.codigoDeBarra?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }

  static Future<List<Product>> getProductsByCategory(int idCategoria) async {
    final products = await getAllProducts();
    return products.where((product) => product.idCategoria == idCategoria).toList();
  }

  static Future<List<Product>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.isLowStock).toList();
  }

  static Future<List<Product>> getExpiringProducts() async {
    final products = await getAllProducts();
    return products.where((product) => 
      product.status == ProductStatus.expiringSoon
    ).toList();
  }

  static Future<InventoryStats> getInventoryStats() async {
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

  // --- VENTAS ---

  static Future<List<Venta>> getAllVentas() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventas}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Venta.fromJson(json)).toList();
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Venta?> getVentaById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventaById(id)}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Venta.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      }
      
      _handleHttpError(response);
      return null;
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<Venta> createVenta(Venta venta) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventas}'),
            headers: _headers,
            body: json.encode(venta.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        return Venta.fromJson(json.decode(response.body));
      }
      
      _handleHttpError(response);
      throw ServerException('Error al crear venta');
    } catch (e) {
      throw _mapException(e);
    }
  }

  // --- DETALLES DE VENTA ---

  static Future<List<DetalleVenta>> getDetallesVentaByVentaId(int idVenta) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.detallesVenta}?idVenta=$idVenta'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => DetalleVenta.fromJson(json))
            .where((detalle) => detalle.idVenta == idVenta)
            .toList();
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<DetalleVenta> createDetalleVenta(DetalleVenta detalle) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.detallesVenta}'),
            headers: _headers,
            body: json.encode(detalle.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        return DetalleVenta.fromJson(json.decode(response.body));
      }
      
      _handleHttpError(response);
      throw ServerException('Error al crear detalle de venta');
    } catch (e) {
      throw _mapException(e);
    }
  }

  // --- MÉTODOS DE ALTO NIVEL PARA VENTAS ---

  /// Busca un producto por código de barras
  static Future<Product?> getProductByBarcode(String barcode) async {
    try {
      // Intentar búsqueda directa por API primero
      try {
        final response = await http
            .get(
              Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productos}?codigoBarras=${Uri.encodeComponent(barcode)}'), 
              headers: _headers
            )
            .timeout(ApiConfig.timeout);

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          if (jsonList.isNotEmpty) {
            final product = Product.fromJson(jsonList.first);
            final enrichedProducts = await _enrichProducts([product]);
            return enrichedProducts.first;
          }
        }
        // Si es 404, no es error, simplemente no existe
      } catch (e) {
        // Si falla la búsqueda directa, usar búsqueda local
        print('🔍 [API] Búsqueda directa falló, usando búsqueda local: $e');
      }
      
      // Búsqueda de respaldo usando getAllProducts()
      try {
        final products = await getAllProducts();
        
        // Buscar el producto que coincida con el código de barras
        for (final product in products) {
          if (product.codigoDeBarra?.trim().toLowerCase() == barcode.trim().toLowerCase()) {
            return product;
          }
        }
      } catch (e) {
        print('🔍 [API] Error en getAllProducts: $e');
      }
      
      // Si no se encuentra, retornar null en lugar de lanzar excepción
      print('🔍 [API] Producto no encontrado con código: $barcode');
      return null;
    } catch (e) {
      print('🔍 [API] Error general buscando producto por código: $e');
      return null;
    }
  }

  /// Crea una venta completa con sus detalles usando el endpoint optimizado
  static Future<Venta> createVentaCompleta(List<DetalleVenta> detalles) async {
    try {
      // Validar que tenemos detalles
      if (detalles.isEmpty) {
        throw Exception('No se pueden crear ventas sin productos');
      }
      
      // Log detallado para debugging
      print('🛒 [VENTA] === INICIO PROCESO VENTA ===');
      for (int i = 0; i < detalles.length; i++) {
        final detalle = detalles[i];
        print('🛒 [VENTA] Producto ${i + 1}: ID=${detalle.idProducto}, Cantidad=${detalle.cantidad}, Precio=\$${detalle.precioUnitario}');
      }
      
      // Calcular el total
      final total = detalles.fold(0.0, (sum, detalle) => sum + detalle.subtotal);
      print('🛒 [VENTA] Creando venta por total: \$${total.toStringAsFixed(2)}');
      print('🛒 [VENTA] ${detalles.length} productos en el carrito');
      
      // Crear la venta completa con sus detalles
      final nuevaVenta = Venta(
        fecha: DateTime.now(),
        total: total,
        detalles: detalles,
      );
      
      print('🛒 [VENTA] Enviando venta completa al servidor...');
      print('📄 [VENTA] JSON enviado: ${json.encode(nuevaVenta.toJson())}');
      
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventasWithDetails}'),
            headers: _headers,
            body: json.encode(nuevaVenta.toJson()),
          )
          .timeout(ApiConfig.timeout);

      print('🌐 [VENTA] Respuesta del servidor: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final ventaCreada = Venta.fromJson(json.decode(response.body));
        print('✅ [VENTA] Venta creada exitosamente con ID: ${ventaCreada.idVenta}');
        print('✅ [VENTA] Stock actualizado automáticamente por la API');
        print('🛒 [VENTA] === FIN PROCESO VENTA ===');
        return ventaCreada;
      }
      
      print('❌ [VENTA] Error del servidor: ${response.body}');
      _handleHttpError(response);
      throw ServerException('Error al crear venta completa');
    } catch (e) {
      print('❌ [VENTA] Error en createVentaCompleta: $e');
      throw _mapException(e);
    }
  }

  /// Método legacy - mantener por compatibilidad (ya no se usa)
  static Future<Venta> createVentaCompletaLegacy(List<DetalleVenta> detalles) async {
    try {
      // Validar que tenemos detalles
      if (detalles.isEmpty) {
        throw Exception('No se pueden crear ventas sin productos');
      }
      
      // Calcular el total
      final total = detalles.fold(0.0, (sum, detalle) => sum + detalle.subtotal);
      print('🛒 [VENTA] Creando venta por total: \$${total.toStringAsFixed(2)}');
      print('🛒 [VENTA] ${detalles.length} productos en el carrito');
      
      // Crear la venta
      final nuevaVenta = Venta(
        fecha: DateTime.now(),
        total: total,
      );
      
      print('🛒 [VENTA] Enviando venta al servidor...');
      final ventaCreada = await createVenta(nuevaVenta);
      print('✅ [VENTA] Venta creada con ID: ${ventaCreada.idVenta}');
      
      // Crear los detalles de la venta uno por uno
      final detallesCreados = <DetalleVenta>[];
      for (int i = 0; i < detalles.length; i++) {
        final detalle = detalles[i];
        print('📦 [DETALLE] Creando detalle ${i + 1}/${detalles.length}: Producto ID ${detalle.idProducto}, Cantidad: ${detalle.cantidad}, Precio: \$${detalle.precioUnitario}');
        
        final detalleConVenta = detalle.copyWith(idVenta: ventaCreada.idVenta);
        try {
          final detalleCreado = await createDetalleVenta(detalleConVenta);
          detallesCreados.add(detalleCreado);
          print('✅ [DETALLE] Detalle ${i + 1} creado exitosamente');
        } catch (e) {
          print('❌ [DETALLE] Error creando detalle ${i + 1}: $e');
          print('📄 [DETALLE] Datos enviados: ${json.encode(detalleConVenta.toJson())}');
          throw Exception('Error creando detalle del producto ${detalle.nombreProducto ?? "ID: ${detalle.idProducto}"}: $e');
        }
      }
      
      print('✅ [VENTA] Venta completa creada exitosamente con ${detallesCreados.length} detalles');
      // Retornar la venta completa con sus detalles
      return ventaCreada.copyWith(detalles: detallesCreados);
    } catch (e) {
      print('❌ [VENTA] Error en createVentaCompleta: $e');
      throw _mapException(e);
    }
  }

  // Mapeo de excepciones
  static Exception _mapException(dynamic e) {
    print('🔍 [API] Mapeando excepción: ${e.runtimeType} - $e'); // Debug log
    
    if (e is SocketException) {
      return NetworkException('No se puede conectar al servidor. Verifica que tu API esté ejecutándose en ${ApiConfig.currentBaseUrl}');
    }
    if (e is http.ClientException) {
      return NetworkException('Error de cliente HTTP: ${e.message}');
    }
    if (e is FormatException) {
      return DataFormatException('La API devolvió datos en formato incorrecto: ${e.message}');
    }
    if (e is ApiException) {
      return e;
    }
    if (e.toString().contains('TimeoutException')) {
      return NetworkException('Timeout: El servidor no responde. Verifica la conexión.');
    }
    return UnknownException('Error desconocido: $e');
  }
}

// Estadísticas del inventario
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

// Excepciones personalizadas
abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class DataFormatException extends ApiException {
  DataFormatException(super.message);
}

class UnknownException extends ApiException {
  UnknownException(super.message);
}
