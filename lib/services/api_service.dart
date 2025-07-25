// ...existing code...
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
  /// Busca un producto por código de barras usando el endpoint RESTful /api/productos/barcode/{codigo}
  static Future<Product?> getProductByBarcodeRestful(String barcode) async {
    try {
      // Construir la URL manualmente si el método no existe en ApiEndpoints
      final url = '${ApiConfig.currentBaseUrl}/api/productos/barcode/${Uri.encodeComponent(barcode)}';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.timeout);
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
      print('❌ [API] Error obteniendo producto por código de barras RESTful: $e');
      return null;
    }
  }
  // Cache mejorado para rendimiento óptimo
  static List<Categoria>? _categoriasCache;
  static List<Proveedor>? _proveedoresCache;
  static List<Product>? _productsCache;
  
  static DateTime? _categoriasLastFetch;
  static DateTime? _proveedoresLastFetch;
  static DateTime? _productsLastFetch;
  
  // Cache más agresivo para datos estables
  static const int _categoriasAndProveedoresCacheMinutes = 15; // Datos estables más tiempo
  static const int _productsCacheMinutes = 3; // Datos dinámicos menos tiempo  
  
  // Pool de conexiones reutilizables para HTTP
  static final http.Client _httpClient = http.Client();
  
  // Getters para acceso a configuración
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Método para actualizar la URL base
  static void updateBaseUrl(String newBaseUrl) {
    ApiConfig.updateBaseUrl(newBaseUrl);
    // Limpiar cache cuando cambie la URL
    clearCache();
  }
  
  // Métodos para limpiar cache selectivo
  static void clearCache() {
    _categoriasCache = null;
    _proveedoresCache = null;
    _productsCache = null;
    _categoriasLastFetch = null;
    _proveedoresLastFetch = null;
    _productsLastFetch = null;
  }
  
  static void clearProductsCache() {
    _productsCache = null;
    _productsLastFetch = null;
  }
  
  static bool _isCacheValid(DateTime? lastFetch, int cacheMinutes) {
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch).inMinutes < cacheMinutes;
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
    // Verificar cache primero con duración apropiada
    if (_isCacheValid(_categoriasLastFetch, _categoriasAndProveedoresCacheMinutes)) {
      print('🧠 [CACHE] Usando categorías desde caché (${_categoriasCache?.length} items)');
      return _categoriasCache!;
    }

    try {
      final url = '${ApiConfig.currentBaseUrl}${ApiEndpoints.categorias}';
      print('🌐 [API] Intentando conectar a: $url'); // Debug log
      
      final response = await http
          .get(
            Uri.parse(url), 
            headers: _headers,
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
            headers: _headers,
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
            headers: _headers,
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
    // Verificar cache primero con duración apropiada
    if (_isCacheValid(_proveedoresLastFetch, _categoriasAndProveedoresCacheMinutes)) {
      print('🧠 [CACHE] Usando proveedores desde caché (${_proveedoresCache?.length} items)');
      return _proveedoresCache!;
    }

    try {
      final url = '${ApiConfig.currentBaseUrl}${ApiEndpoints.proveedores}';
      print('🌐 [API] Intentando conectar a: $url'); // Debug log
      
      final response = await http
          .get(
            Uri.parse(url), 
            headers: _headers,
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
            headers: _headers,
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

  static Future<Proveedor> createProveedor(Proveedor proveedor) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.proveedores}'),
            headers: _headers,
            body: json.encode(proveedor.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        // Limpiar cache al crear un proveedor nuevo
        _proveedoresCache = null;
        _proveedoresLastFetch = null;
        return Proveedor.fromJson(json.decode(response.body));
      }
      
      _handleHttpError(response);
      throw ServerException('Error al crear proveedor');
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> updateProveedor(Proveedor proveedor) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.proveedorById(proveedor.idProveedor!)}'),
            headers: _headers,
            body: json.encode(proveedor.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        // Limpiar cache al actualizar
        _proveedoresCache = null;
        _proveedoresLastFetch = null;
        return;
      }
      
      _handleHttpError(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> deleteProveedor(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.proveedorById(id)}'), 
            headers: _headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        // Limpiar cache al eliminar
        _proveedoresCache = null;
        _proveedoresLastFetch = null;
        return;
      }
      
      _handleHttpError(response);
    } catch (e) {
      throw _mapException(e);
    }
  }

  // --- PRODUCTOS ---

  static Future<List<Product>> getAllProducts() async {
    // Verificar cache de productos primero
    if (_isCacheValid(_productsLastFetch, _productsCacheMinutes)) {
      print('🧠 [CACHE] Usando productos desde caché (${_productsCache?.length} items)');
      return _productsCache!;
    }

    try {
      final response = await _httpClient
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productos}'), 
            headers: _headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final products = jsonList.map((json) => Product.fromJson(json)).toList();
        
        // Enriquecer productos con información de categorías y caducidades
        final enrichedProducts = await _enrichProducts(products);
        
        // Guardar en cache
        _productsCache = enrichedProducts;
        _productsLastFetch = DateTime.now();
        print('🧠 [CACHE] Productos guardados en caché (${enrichedProducts.length} items)');
        
        return enrichedProducts;
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
            headers: _headers,
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
      // 🔍 LOGGING DETALLADO - Verificar datos antes del envío
      print('🔍 [API] === DIAGNÓSTICO CÓDIGO DE BARRAS ===');
      print('🔍 [API] Producto a crear: ${product.nombre}');
      print('🔍 [API] Código de barras en modelo: "${product.codigoDeBarra}"');
      print('🔍 [API] ¿Código de barras es null?: ${product.codigoDeBarra == null}');
      print('🔍 [API] ¿Código de barras está vacío?: ${product.codigoDeBarra?.isEmpty ?? true}');
      
      final jsonData = product.toJson();
      print('🔍 [API] JSON a enviar: ${json.encode(jsonData)}');
      print('🔍 [API] Campo codigoDeBarra en JSON: "${jsonData['codigoDeBarra']}"');
      print('🔍 [API] =======================================');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productos}'),
            headers: _headers,
            body: json.encode(jsonData),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        // 🔍 LOGGING DETALLADO - Verificar respuesta del backend
        print('🔍 [API] === RESPUESTA DEL BACKEND ===');
        print('🔍 [API] Status: ${response.statusCode}');
        print('🔍 [API] Response body: ${response.body}');
        
        final responseData = json.decode(response.body);
        print('🔍 [API] Código de barras en respuesta: "${responseData['codigoDeBarra']}"');
        print('🔍 [API] ================================');

        final createdProduct = Product.fromJson(responseData);
        
        // 🔍 LOGGING DETALLADO - Verificar producto creado
        print('🔍 [API] === PRODUCTO CREADO ===');
        print('🔍 [API] ID del producto: ${createdProduct.idProducto}');
        print('🔍 [API] Nombre: ${createdProduct.nombre}');
        print('🔍 [API] Código de barras en producto creado: "${createdProduct.codigoDeBarra}"');
        print('🔍 [API] ===========================');
        
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
        final finalProduct = enrichedProducts.isNotEmpty ? enrichedProducts.first : createdProduct;
        
        // 🔍 LOGGING DETALLADO - Verificar producto final
        print('🔍 [API] === PRODUCTO FINAL ===');
        print('🔍 [API] Código de barras en producto final: "${finalProduct.codigoDeBarra}"');
        print('🔍 [API] =======================');
        
        return finalProduct;
      }
      
      _handleHttpError(response);
      throw ServerException('Error al crear producto');
    } catch (e) {
      print('❌ [API] Error en createProduct: $e');
      throw _mapException(e);
    }
  }

  static Future<Product> updateProduct(Product product) async {
    try {
      // 🔍 LOGGING DETALLADO - Verificar datos antes del envío (UPDATE)
      print('🔍 [API] === DIAGNÓSTICO CÓDIGO DE BARRAS (UPDATE) ===');
      print('🔍 [API] Producto a actualizar: ${product.nombre} (ID: ${product.idProducto})');
      print('🔍 [API] Código de barras en modelo: "${product.codigoDeBarra}"');
      print('🔍 [API] ¿Código de barras es null?: ${product.codigoDeBarra == null}');
      print('🔍 [API] ¿Código de barras está vacío?: ${product.codigoDeBarra?.isEmpty ?? true}');
      
      final jsonData = product.toJson();
      print('🔍 [API] JSON a enviar: ${json.encode(jsonData)}');
      print('🔍 [API] Campo codigoDeBarra en JSON: "${jsonData['codigoDeBarra']}"');
      print('🔍 [API] =======================================');

      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoById(product.idProducto!)}'),
            headers: _headers,
            body: json.encode(jsonData),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        print('🔍 [API] === RESPUESTA DEL BACKEND (UPDATE) ===');
        print('🔍 [API] Status: ${response.statusCode} (No Content)');
        print('🔍 [API] ========================================');

        // Actualizar caducidades si es necesario
        if (product.idProducto != null) {
          await _updateProductCaducidades(product.idProducto!, product.caducidades);
        }
        
        // Obtener el producto actualizado
        final updatedProduct = await getProductById(product.idProducto!);
        
        // 🔍 LOGGING DETALLADO - Verificar producto actualizado
        print('🔍 [API] === PRODUCTO ACTUALIZADO ===');
        print('🔍 [API] Código de barras en producto actualizado: "${updatedProduct?.codigoDeBarra}"');
        print('🔍 [API] ===============================');
        
        return updatedProduct ?? product;
      }
      
      _handleHttpError(response);
      throw ServerException('Error al actualizar producto');
    } catch (e) {
      print('❌ [API] Error en updateProduct: $e');
      throw _mapException(e);
    }
  }

  static Future<void> deleteProduct(int id) async {
    try {
      // Eliminar caducidades relacionadas, pero no fallar si alguna no se puede borrar
      final caducidades = await getProductoCaducidadesByProducto(id);
      for (final caducidad in caducidades) {
        if (caducidad.idProductoCaducidad != null) {
          try {
            await deleteProductoCaducidad(caducidad.idProductoCaducidad!);
          } catch (e) {
            print('⚠️ [API] Error eliminando caducidad ${caducidad.idProductoCaducidad}: $e');
            // Continuar con el resto
          }
        }
      }

      // Eliminar el producto principal
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoById(id)}'),
            headers: _headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        print('✅ [API] Producto eliminado correctamente');
        return;
      }

      // Si el backend responde con error, mostrar mensaje claro
      print('❌ [API] Error eliminando producto: ${response.statusCode} - ${response.body}');
      _handleHttpError(response);
    } catch (e) {
      print('❌ [API] Error general en deleteProduct: $e');
      throw _mapException(e);
    }
  }

  // --- PRODUCTO CADUCIDAD ---

  static Future<List<ProductoCaducidad>> getAllProductosCaducidad() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoCaducidad}'), 
            headers: _headers,
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

  static Future<ProductoCaducidad> updateProductoCaducidad(ProductoCaducidad caducidad) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoCaducidadById(caducidad.idProductoCaducidad!)}'),
            headers: _headers,
            body: json.encode(caducidad.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 204) {
        return caducidad;
      } else if (response.statusCode == 200) {
        return ProductoCaducidad.fromJson(json.decode(response.body));
      }
      
      _handleHttpError(response);
      throw ServerException('Error al actualizar caducidad');
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> deleteProductoCaducidad(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoCaducidadById(id)}'), 
            headers: _headers,
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
        ),);
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
        ),);
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
      (product.codigoDeBarra?.toLowerCase().contains(lowercaseQuery) ?? false),
    ).toList();
  }

  static Future<List<Product>> getProductsByCategory(int idCategoria) async {
    final products = await getAllProducts();
    return products.where((product) => product.idCategoria == idCategoria).toList();
  }

  static Future<List<Product>> getLowStockProducts() async {
    try {
      // Usar la vista optimizada de la BD
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.vistasStockBajo}'), 
            headers: _headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final products = jsonList.map((json) => Product.fromJson(json)).toList();
        return await _enrichProducts(products);
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      // Fallback al método local si la vista no está disponible
      print('⚠️ [API] Vista stock-bajo no disponible, usando método local: $e');
      final products = await getAllProducts();
      return products.where((product) => product.isLowStock).toList();
    }
  }

  static Future<List<Product>> getProductosStatus() async {
    try {
      // Usar la vista optimizada de productos-status
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.vistasProductosStatus}'), 
            headers: _headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final products = jsonList.map((json) => Product.fromJson(json)).toList();
        return await _enrichProducts(products);
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      // Fallback al método normal si la vista no está disponible
      print('⚠️ [API] Vista productos-status no disponible, usando getAllProducts: $e');
      return await getAllProducts();
    }
  }

  static Future<List<Product>> getExpiringProducts() async {
    final products = await getAllProducts();
    return products.where((product) => 
      product.status == ProductStatus.expiringSoon,
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
            headers: _headers,
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
            headers: _headers,
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
      // Aseguramos que siempre enviamos una venta con total=0 para evitar la duplicación
      // El backend calculará el total correcto mediante sus triggers
      final ventaToSend = venta.copyWith(total: 0);
      
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventas}'),
            headers: _headers,
            body: json.encode(ventaToSend.toJson()),
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

  static Future<void> updateVenta(Venta venta) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventaById(venta.idVenta!)}'),
            headers: _headers,
            body: json.encode(venta.toJson()),
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

  static Future<void> deleteVenta(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventaById(id)}'), 
            headers: _headers,
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

  // --- DETALLES DE VENTA ---

  static Future<List<DetalleVenta>> getAllDetallesVenta() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.detallesVenta}'), 
            headers: _headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DetalleVenta.fromJson(json)).toList();
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<List<DetalleVenta>> getDetallesVentaByVentaId(int idVenta) async {
    try {
      // Obtener todos los detalles y filtrar por venta ID
      final allDetalles = await getAllDetallesVenta();
      return allDetalles.where((detalle) => detalle.idVenta == idVenta).toList();
    } catch (e) {
      // Fallback: usar query parameter si el backend lo soporta
      try {
        final response = await http
            .get(
              Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.detallesVenta}?idVenta=$idVenta'), 
              headers: _headers,
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
      } catch (e2) {
        throw _mapException(e);
      }
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

  static Future<DetalleVenta?> getDetalleVentaById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.detalleVentaById(id)}'), 
            headers: _headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return DetalleVenta.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      }
      
      _handleHttpError(response);
      return null;
    } catch (e) {
      throw _mapException(e);
    }
  }

  static Future<void> updateDetalleVenta(DetalleVenta detalle) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.detalleVentaById(detalle.idDetalle!)}'),
            headers: _headers,
            body: json.encode(detalle.toJson()),
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

  static Future<void> deleteDetalleVenta(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.detalleVentaById(id)}'), 
            headers: _headers,
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

  // --- MÉTODOS DE ALTO NIVEL PARA VENTAS ---

  /// Busca un producto por código de barras
  static Future<Product?> getProductByBarcode(String barcode) async {
    try {
      // Intentar búsqueda directa por API primero
      try {
        final response = await http
            .get(
              Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productos}?codigoBarras=${Uri.encodeComponent(barcode)}'), 
              headers: _headers,
            )
            .timeout(ApiConfig.timeout);

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          if (jsonList.isNotEmpty) {
            // Filtrar por coincidencia exacta de código de barras
            final filtered = jsonList.where((item) {
              final rawCode = item['codigoDeBarra'];
              if (rawCode == null) return false;
              final code = rawCode.toString().trim().toLowerCase();
              return code == barcode.trim().toLowerCase();
            }).toList();
            if (filtered.isNotEmpty) {
              final product = Product.fromJson(filtered.first);
              final enrichedProducts = await _enrichProducts([product]);
              return enrichedProducts.first;
            }
          }
        }
        // Si es 404, no es error, simplemente no existe
      } catch (e) {
        // Si falla la búsqueda directa, usar búsqueda local
        print('🔍 [API] Búsqueda directa falló, usando búsqueda local: $e');
      }
      
      // Búsqueda de respaldo usando getAllProducts()
      try {
        print('🔍 [API] Iniciando búsqueda local por código de barras: $barcode');
        final products = await getAllProducts();
        print('🔍 [API] Productos obtenidos para búsqueda: ${products.length}');
        
        // Buscar el producto que coincida con el código de barras
        for (final product in products) {
          print('🔍 [API] Verificando producto: ${product.nombre} - código: "${product.codigoDeBarra}"');
          
          // Verificar que ambos valores no sean null/vacíos antes de comparar
          if (product.codigoDeBarra != null && 
              product.codigoDeBarra!.trim().isNotEmpty &&
              product.codigoDeBarra!.trim().toLowerCase() == barcode.trim().toLowerCase()) {
            print('✅ [API] ENCONTRADO! Producto: ${product.nombre} con código: ${product.codigoDeBarra}');
            return product;
          }
        }
        
        print('❌ [API] Ningún producto encontrado con código de barras válido: $barcode');
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
      
      // Calcular el total solo para logging (no lo usaremos en el objeto enviado)
      final totalCalculado = detalles.fold(0.0, (sum, detalle) => sum + detalle.subtotal);
      print('🛒 [VENTA] Calculando total local: \$${totalCalculado.toStringAsFixed(2)} (el backend calculará el total oficial)');
      print('🛒 [VENTA] ${detalles.length} productos en el carrito');
      
      // Crear la venta completa con sus detalles - enviando 0 como total para que lo calcule el backend
      final nuevaVenta = Venta(
        fecha: DateTime.now(),
        total: 0, // Establecer a 0 para que el backend lo calcule mediante sus triggers
        detalles: detalles,
      );
      final ventaJson = nuevaVenta.toJson();
      
      print('🛒 [VENTA] Enviando venta completa al servidor...');
      print('📄 [VENTA] JSON enviado: ${json.encode(ventaJson)}');
      
      // Intentar primero con el endpoint optimizado, si falla usar el método legacy
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.ventasWithDetails}'),
              headers: _headers,
              body: json.encode(ventaJson),
            )
            .timeout(ApiConfig.timeout);
      } catch (e) {
        print('⚠️ [VENTA] Endpoint withdetails no disponible, usando método legacy...');
        return createVentaCompletaLegacy(detalles);
      }

      print('🌐 [VENTA] Respuesta del servidor: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final ventaCreada = Venta.fromJson(json.decode(response.body));
        print('✅ [VENTA] Venta creada exitosamente con ID: ${ventaCreada.idVenta}');
        print('✅ [VENTA] Stock actualizado automáticamente por la API');
        print('🛒 [VENTA] === FIN PROCESO VENTA ===');
        return ventaCreada;
      } else if (response.statusCode == 405) {
        print('⚠️ [VENTA] Método no permitido (405), usando método legacy...');
        return createVentaCompletaLegacy(detalles);
      }
      
      print('❌ [VENTA] Error del servidor: ${response.body}');
      _handleHttpError(response);
      throw ServerException('Error al crear venta completa');
    } catch (e) {
      print('❌ [VENTA] Error en createVentaCompleta: $e');
      throw _mapException(e);
    }
  }

  /// Método legacy - crear venta paso a paso (compatibilidad con APIs básicas)
  static Future<Venta> createVentaCompletaLegacy(List<DetalleVenta> detalles) async {
    try {
      print('🔄 [LEGACY] Usando método de compatibilidad...');
      
      // Validar que tenemos detalles
      if (detalles.isEmpty) {
        throw Exception('No se pueden crear ventas sin productos');
      }
      
      // Calcular el total solo para logging (no lo usaremos en el objeto enviado)
      final totalCalculado = detalles.fold(0.0, (sum, detalle) => sum + detalle.subtotal);
      print('🛒 [LEGACY] Total calculado localmente: \$${totalCalculado.toStringAsFixed(2)} (el backend calculará el total oficial)');
      print('🛒 [LEGACY] ${detalles.length} productos en el carrito');
      
      // Crear la venta - estableciendo total en 0 para que el backend lo calcule
      final nuevaVenta = Venta(
        fecha: DateTime.now(),
        total: 0, // Establecer a 0 para que el backend lo calcule mediante sus triggers
      );
      
      print('🛒 [LEGACY] Enviando venta al servidor...');
      final ventaCreada = await createVenta(nuevaVenta);
      print('✅ [LEGACY] Venta creada con ID: ${ventaCreada.idVenta}');
      
      // Crear los detalles de la venta uno por uno
      final detallesCreados = <DetalleVenta>[];
      for (int i = 0; i < detalles.length; i++) {
        final detalle = detalles[i];
        print('📦 [LEGACY] Creando detalle ${i + 1}/${detalles.length}: Producto ID ${detalle.idProducto}, Cantidad: ${detalle.cantidad}, Precio: \$${detalle.precioUnitario}');
        
        final detalleConVenta = detalle.copyWith(idVenta: ventaCreada.idVenta);
        try {
          final detalleCreado = await createDetalleVenta(detalleConVenta);
          detallesCreados.add(detalleCreado);
          print('✅ [LEGACY] Detalle ${i + 1} creado exitosamente');
        } catch (e) {
          print('❌ [LEGACY] Error creando detalle ${i + 1}: $e');
          print('📄 [LEGACY] Datos enviados: ${json.encode(detalleConVenta.toJson())}');
          throw Exception('Error creando detalle del producto ${detalle.nombreProducto ?? "ID: ${detalle.idProducto}"}: $e');
        }
      }
      
      print('✅ [LEGACY] Venta completa creada exitosamente con ${detallesCreados.length} detalles');
      print('🛒 [LEGACY] === FIN PROCESO VENTA ===');
      
      // Retornar la venta completa con sus detalles
      return ventaCreada.copyWith(detalles: detallesCreados);
    } catch (e) {
      print('❌ [LEGACY] Error en createVentaCompletaLegacy: $e');
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

  // --- ESTADÍSTICAS DE VENTAS ---

  /// Obtiene un resumen completo de ventas y ganancias
  static Future<Map<String, dynamic>> getSalesAndProfitSummary() async {
    try {
      final ventas = await getAllVentas();
      final productos = await getAllProducts();
      
      // Calcular estadísticas de ventas
      final totalVentas = ventas.length;
      final ventasHoy = ventas.where((v) => 
        v.fecha.year == DateTime.now().year &&
        v.fecha.month == DateTime.now().month &&
        v.fecha.day == DateTime.now().day,
      ).length;
      
      final ingresosTotales = ventas.fold(0.0, (sum, venta) => sum + venta.total);
      final ingresosHoy = ventas.where((v) => 
        v.fecha.year == DateTime.now().year &&
        v.fecha.month == DateTime.now().month &&
        v.fecha.day == DateTime.now().day,
      ).fold(0.0, (sum, venta) => sum + venta.total);
      
      // Calcular ganancias potenciales basadas en productos
      final gananciasPotenciales = productos.fold(0.0, (sum, producto) => 
        sum + ((producto.precioVenta - producto.precioCosto) * producto.stockActual),);
      
      // Productos con más stock (como indicador de popularidad)
      final productosOrdenados = productos..sort((a, b) => 
        b.stockActual.compareTo(a.stockActual),);
      final topProductos = productosOrdenados.take(5).toList();
      
      // Productos con bajo stock (necesitan reposición)
      final stockBajo = productos.where((p) => p.stockActual <= p.stockMinimo).length;
      
      return {
        'totalVentas': totalVentas,
        'ventasHoy': ventasHoy,
        'ingresosTotales': ingresosTotales,
        'ingresosHoy': ingresosHoy,
        'gananciasPotenciales': gananciasPotenciales,
        'promedioVentaDiaria': totalVentas > 0 ? ingresosTotales / totalVentas : 0.0,
        'totalProductos': productos.length,
        'stockBajo': stockBajo,
        'valorInventario': productos.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stockActual)),
        'topProductos': topProductos.map((p) => {
          'nombre': p.nombre,
          'stockActual': p.stockActual,
          'precioVenta': p.precioVenta,
          'gananciaUnitaria': p.precioVenta - p.precioCosto,
        },).toList(),
        'fechaActualizacion': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw ServerException('Error al obtener estadísticas de ventas: $e');
    }
  }

  /// Obtiene ventas del último mes
  static Future<List<Venta>> getVentasUltimoMes() async {
    try {
      final ventas = await getAllVentas();
      final fechaLimite = DateTime.now().subtract(const Duration(days: 30));
      
      return ventas.where((venta) => venta.fecha.isAfter(fechaLimite)).toList();
    } catch (e) {
      throw ServerException('Error al obtener ventas del último mes: $e');
    }
  }

  /// Obtiene las ventas de hoy
  static Future<List<Venta>> getVentasHoy() async {
    try {
      final ventas = await getAllVentas();
      final hoy = DateTime.now();
      
      return ventas.where((venta) => 
        venta.fecha.year == hoy.year &&
        venta.fecha.month == hoy.month &&
        venta.fecha.day == hoy.day,
      ).toList();
    } catch (e) {
      throw ServerException('Error al obtener ventas de hoy: $e');
    }
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

// Método utilitario para probar la conexión a la API
// This method has been moved to ApiConfig to avoid circular dependencies
