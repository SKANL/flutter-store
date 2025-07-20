import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Test de Conectividad API');
  print('==========================');
  
  final baseUrl = 'http://localhost:5041';
  print('Probando: $baseUrl');
  
  try {
    final client = HttpClient();
    client.connectionTimeout = Duration(seconds: 5);
    
    // Test 1: Conexión básica
    print('\n1. Probando conexión básica...');
    final request = await client.getUrl(Uri.parse('$baseUrl/api/categorias'));
    final response = await request.close();
    
    print('✅ Respuesta: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      print('📄 Contenido: ${body.length} caracteres');
      
      // Intentar parsear JSON
      try {
        final data = json.decode(body);
        if (data is List) {
          print('✅ JSON válido: ${data.length} categorías encontradas');
        } else {
          print('⚠️ JSON válido pero formato inesperado');
        }
      } catch (e) {
        print('❌ Error parsing JSON: $e');
      }
    }
    
    client.close();
    print('\n🎉 Test completado');
    
  } catch (e) {
    print('❌ Error de conexión: $e');
    print('\n💡 Posibles soluciones:');
    print('1. Verificar que la API esté corriendo en http://localhost:5041');
    print('2. Agregar CORS a tu API C#');
    print('3. Verificar firewall/antivirus');
  }
}
