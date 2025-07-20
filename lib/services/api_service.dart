import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/categoria.dart';
import '../models/proveedor.dart';
import '../models/producto_caducidad.dart';
import '../core/api_config.dart';

class ApiService {
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
        return jsonList.map((json) => Categoria.fromJson(json)).toList();
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
        return jsonList.map((json) => Proveedor.fromJson(json)).toList();
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

  static Future<List<ProductoCaducidad>> getProductoCaducidadesByProducto(int idProducto) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiEndpoints.productoCaducidad}'), 
            headers: _headers
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => ProductoCaducidad.fromJson(json))
            .where((caducidad) => caducidad.idProducto == idProducto)
            .toList();
      }
      
      _handleHttpError(response);
      return [];
    } catch (e) {
      throw _mapException(e);
    }
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
      // Cargar categorías y proveedores en paralelo
      final categoriasFuture = getCategorias();
      final proveedoresFuture = getProveedores();
      
      final categorias = await categoriasFuture;
      final proveedores = await proveedoresFuture;

      // Mapear por ID para búsqueda rápida
      final categoriasMap = {for (var c in categorias) c.idCategoria: c};
      final proveedoresMap = {for (var p in proveedores) p.idProveedor: p};

      // Enriquecer productos
      final enrichedProducts = <Product>[];
      
      for (final product in products) {
        final categoria = categoriasMap[product.idCategoria];
        final proveedor = product.idProveedor != null 
            ? proveedoresMap[product.idProveedor] 
            : null;
        
        // Obtener caducidades del producto
        final caducidades = product.idProducto != null
            ? await getProductoCaducidadesByProducto(product.idProducto!)
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
