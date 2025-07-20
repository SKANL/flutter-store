import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Script completo de diagnóstico de conectividad API
void main() async {
  developer.log('🔍 DIAGNÓSTICO COMPLETO DE CONECTIVIDAD API');
  developer.log('===============================================');
  
  // Lista de URLs posibles para probar
  final urlsToTest = [
    'https://localhost:7139',  // ASP.NET Core HTTPS típico
    'http://localhost:5000',   // ASP.NET Core HTTP típico
    'https://localhost:5001',  // ASP.NET Core HTTPS alternativo
    'http://localhost:5139',   // Puerto personalizado HTTP
  ];
  
  for (final baseUrl in urlsToTest) {
    await testApiConnection(baseUrl);
  }
}

Future<void> testApiConnection(String baseUrl) async {
  developer.log('\n🌐 Probando conexión con: $baseUrl');
  developer.log('-------------------------------------------');
  
  try {
    // 1. Test de conectividad básica
    developer.log('1️⃣ Test de conectividad básica...');
    final response = await http
        .get(Uri.parse('$baseUrl/api/categorias'))
        .timeout(const Duration(seconds: 10));
    
    developer.log('✅ Respuesta recibida');
    developer.log('   Status Code: ${response.statusCode}');
    developer.log('   Headers: ${response.headers}');
    
    if (response.statusCode == 200) {
      developer.log('✅ Conexión exitosa!');
      
      // 2. Test de parseo JSON
      developer.log('2️⃣ Test de parseo de datos...');
      try {
        final data = json.decode(response.body);
        developer.log('✅ JSON válido recibido');
        developer.log('   Tipo de datos: ${data.runtimeType}');
        
        if (data is List) {
          developer.log('   Elementos recibidos: ${data.length}');
          if (data.isNotEmpty) {
            developer.log('   Primer elemento: ${data.first}');
          }
        } else {
          developer.log('   Estructura: $data');
        }
        
        // 3. Test de endpoints adicionales
        await testAllEndpoints(baseUrl);
        
      } catch (e) {
        developer.log('❌ Error parseando JSON: $e');
        developer.log('   Respuesta raw: ${response.body}');
      }
      
    } else {
      developer.log('⚠️ Conexión establecida pero error HTTP');
      developer.log('   Status: ${response.statusCode}');
      developer.log('   Body: ${response.body}');
    }
    
  } catch (e) {
    developer.log('❌ Error de conexión: ${e.runtimeType}');
    developer.log('   Mensaje: $e');
    
    // Diagnóstico específico del error
    if (e is SocketException) {
      developer.log('💡 Posibles soluciones:');
      developer.log('   - Verificar que la API C# esté ejecutándose');
      developer.log('   - Revisar el puerto correcto');
      developer.log('   - Verificar configuración de firewall');
    } else if (e.toString().contains('certificate')) {
      developer.log('💡 Problema de certificado HTTPS:');
      developer.log('   - Intentar con HTTP en lugar de HTTPS');
      developer.log('   - Configurar certificado de desarrollo');
    }
  }
}

Future<void> testAllEndpoints(String baseUrl) async {
  developer.log('3️⃣ Test de endpoints específicos...');
  
  final endpoints = {
    'Categorías': '/api/categorias',
    'Proveedores': '/api/proveedores',
    'Productos': '/api/productos',
    'Producto Caducidad': '/api/productocaducidad',
  };
  
  for (final entry in endpoints.entries) {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl${entry.value}'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data is List ? data.length : 'N/A';
        developer.log('   ✅ ${entry.key}: $count registros');
      } else {
        developer.log('   ⚠️ ${entry.key}: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('   ❌ ${entry.key}: Error - $e');
    }
  }
  
  developer.log('\n🎯 ESTA URL FUNCIONA CORRECTAMENTE: $baseUrl');
  developer.log('   Actualiza tu api_config.dart con esta URL');
}
