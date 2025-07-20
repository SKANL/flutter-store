import 'dart:developer' as developer;
import 'lib/services/api_service.dart';
import 'lib/core/api_config.dart';

void main() async {
  developer.log('Probando conectividad con la API...');
  developer.log('URL Base: ${ApiConfig.currentBaseUrl}');
  
  try {
    // Probar categorías
    developer.log('1. Obteniendo categorías...');
    final categorias = await ApiService.getCategorias();
    developer.log('✓ Categorías obtenidas: ${categorias.length}');
    for (final categoria in categorias) {
      developer.log('  - ${categoria.nombre} (ID: ${categoria.idCategoria})');
    }
    
    // Probar proveedores
    developer.log('2. Obteniendo proveedores...');
    final proveedores = await ApiService.getProveedores();
    developer.log('✓ Proveedores obtenidos: ${proveedores.length}');
    for (final proveedor in proveedores) {
      developer.log('  - ${proveedor.nombre} (ID: ${proveedor.idProveedor})');
    }
    
    // Probar productos
    developer.log('3. Obteniendo productos...');
    final productos = await ApiService.getAllProducts();
    developer.log('✓ Productos obtenidos: ${productos.length}');
    for (final producto in productos) {
      developer.log('  - ${producto.nombre} - Stock: ${producto.stockActual} - Categoría: ${producto.categoryName}');
    }
    
    // Probar estadísticas
    developer.log('4. Obteniendo estadísticas del inventario...');
    final stats = await ApiService.getInventoryStats();
    developer.log('✓ Estadísticas:');
    developer.log('  - Total productos: ${stats.totalProducts}');
    developer.log('  - Valor total: \$${stats.totalValue.toStringAsFixed(2)}');
    developer.log('  - Ganancia total: \$${stats.totalProfit.toStringAsFixed(2)}');
    developer.log('  - Stock bajo: ${stats.lowStockCount}');
    developer.log('  - Por vencer: ${stats.expiringCount}');
    developer.log('  - Vencidos: ${stats.expiredCount}');
    
    developer.log('🎉 ¡Todas las pruebas exitosas! La API está funcionando correctamente.');
    
  } catch (e) {
    developer.log('❌ Error durante las pruebas:');
    developer.log('Tipo: ${e.runtimeType}');
    developer.log('Mensaje: $e');
    
    // Sugerencias basadas en el tipo de error
    if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
      developer.log('💡 Sugerencias:');
      developer.log('1. Verifica que el servidor C# esté ejecutándose');
      developer.log('2. Confirma que la URL de la API sea correcta: ${ApiConfig.currentBaseUrl}');
      developer.log('3. Verifica que no haya firewall bloqueando la conexión');
    } else if (e.toString().contains('FormatException') || e.toString().contains('DataFormatException')) {
      developer.log('💡 Sugerencias:');
      developer.log('1. Verifica que los modelos coincidan con la estructura de la API');
      developer.log('2. Revisa que los endpoints retornen el formato JSON esperado');
    }
  }
}
