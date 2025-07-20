import 'dart:math';
import '../core/app_logger.dart';
import '../models/product.dart';

/// Servicio para generar y manejar códigos de barras de productos
class BarcodeService {
  
  /// Genera un código de barras único para un producto
  static String generateBarcode({
    required String productName,
    required int categoryId,
    int? existingId,
  }) {
    try {
      AppLogger.debug('Generando código de barras para: $productName', 'BARCODE');
      
      // Formato: XXXX-YYYY-ZZZZ
      // XXXX = Categoría + parte del nombre
      // YYYY = Timestamp reducido
      // ZZZZ = Random + ID si existe
      
      // Parte 1: Categoría (2 dígitos) + hash del nombre (2 dígitos)
      final categoryPart = categoryId.toString().padLeft(2, '0').substring(0, 2);
      final nameHash = productName.hashCode.abs() % 100;
      final namePart = nameHash.toString().padLeft(2, '0');
      final firstPart = categoryPart + namePart;
      
      // Parte 2: Timestamp (últimos 4 dígitos)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final timestampPart = (timestamp % 10000).toString().padLeft(4, '0');
      
      // Parte 3: Random + ID si existe
      final random = Random().nextInt(100);
      final idPart = existingId != null ? (existingId % 100) : random;
      final finalPart = idPart.toString().padLeft(2, '0') + 
                       random.toString().padLeft(2, '0');
      
      final barcode = '$firstPart$timestampPart$finalPart';
      
      AppLogger.info('Código generado: $barcode para $productName', 'BARCODE');
      return barcode;
    } catch (e, stackTrace) {
      AppLogger.error('Error generando código de barras', 'BARCODE', e, stackTrace);
      // Código de fallback
      return _generateFallbackBarcode();
    }
  }
  
  /// Genera un código de barras simple como fallback
  static String _generateFallbackBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${timestamp % 100000000}${random.toString().padLeft(4, '0')}';
  }
  
  /// Valida si un código de barras tiene el formato correcto
  static bool isValidBarcode(String? barcode) {
    if (barcode == null || barcode.isEmpty) return false;
    
    // Permitir diferentes formatos de código de barras
    // Formato propio: 12 dígitos
    // Otros formatos estándar: 8, 13 dígitos
    final validLengths = [8, 12, 13];
    
    // Solo números
    if (!RegExp(r'^\d+$').hasMatch(barcode)) return false;
    
    // Longitud válida
    return validLengths.contains(barcode.length);
  }
  
  /// Asegura que un producto tenga un código de barras válido
  static Product ensureBarcodeExists(Product product) {
    try {
      AppLogger.debug('Verificando código de barras para: ${product.nombre}', 'BARCODE');
      
      // Si ya tiene un código válido, no hacer nada
      if (isValidBarcode(product.codigoDeBarra)) {
        AppLogger.debug('Código existente válido: ${product.codigoDeBarra}', 'BARCODE');
        return product;
      }
      
      // Generar nuevo código
      final newBarcode = generateBarcode(
        productName: product.nombre,
        categoryId: product.idCategoria,
        existingId: product.idProducto,
      );
      
      AppLogger.info('Asignando nuevo código: $newBarcode', 'BARCODE');
      
      return product.copyWith(codigoDeBarra: newBarcode);
    } catch (e, stackTrace) {
      AppLogger.error('Error asegurando código de barras', 'BARCODE', e, stackTrace);
      return product;
    }
  }
  
  /// Busca un producto por código de barras en una lista
  static Product? findProductByBarcode(List<Product> products, String barcode) {
    try {
      if (!isValidBarcode(barcode)) {
        AppLogger.warning('Código de barras inválido para búsqueda: $barcode', 'BARCODE');
        return null;
      }
      
      final found = products.where((p) => p.codigoDeBarra == barcode).firstOrNull;
      
      if (found != null) {
        AppLogger.debug('Producto encontrado por código: ${found.nombre}', 'BARCODE');
      } else {
        AppLogger.debug('No se encontró producto con código: $barcode', 'BARCODE');
      }
      
      return found;
    } catch (e, stackTrace) {
      AppLogger.error('Error buscando producto por código', 'BARCODE', e, stackTrace);
      return null;
    }
  }
  
  /// Verifica si un código de barras está duplicado en una lista
  static bool isDuplicateBarcode(List<Product> products, String barcode, {int? excludeId}) {
    try {
      if (!isValidBarcode(barcode)) return false;
      
      final duplicates = products.where((p) => 
        p.codigoDeBarra == barcode && 
        (excludeId == null || p.idProducto != excludeId),
      ).toList();
      
      final isDuplicate = duplicates.isNotEmpty;
      
      if (isDuplicate) {
        AppLogger.warning('Código duplicado encontrado: $barcode', 'BARCODE');
      }
      
      return isDuplicate;
    } catch (e) {
      AppLogger.error('Error verificando duplicados', 'BARCODE', e);
      return false;
    }
  }
  
  /// Genera un código único que no esté duplicado en la lista
  static String generateUniqueBarcode(
    List<Product> existingProducts,
    String productName,
    int categoryId, {
    int? existingId,
    int maxAttempts = 10,
  }) {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = generateBarcode(
        productName: productName,
        categoryId: categoryId,
        existingId: existingId,
      );
      
      if (!isDuplicateBarcode(existingProducts, candidate, excludeId: existingId)) {
        AppLogger.info('Código único generado en intento ${attempt + 1}: $candidate', 'BARCODE');
        return candidate;
      }
      
      AppLogger.debug('Intento ${attempt + 1} duplicado: $candidate', 'BARCODE');
      
      // Pequeña pausa para cambiar el timestamp
      if (attempt < maxAttempts - 1) {
        Future.delayed(const Duration(milliseconds: 1));
      }
    }
    
    // Si no se pudo generar uno único, usar timestamp como fallback
    AppLogger.warning('No se pudo generar código único, usando fallback', 'BARCODE');
    return _generateFallbackBarcode();
  }
  
  /// Formatea un código de barras para mostrar (con guiones)
  static String formatBarcodeForDisplay(String? barcode) {
    if (barcode == null || barcode.isEmpty) return 'Sin código';
    
    if (barcode.length == 12) {
      // Formato: XXXX-YYYY-ZZZZ
      return '${barcode.substring(0, 4)}-${barcode.substring(4, 8)}-${barcode.substring(8)}';
    }
    
    return barcode;
  }
}
