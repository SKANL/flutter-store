import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 Test de Conectividad Android -> PC');
  print('=====================================');
  
  final testUrl = 'http://192.168.1.7:5041';
  
  // Test 1: Conexión Socket
  try {
    print('📡 Test 1: Conectividad Socket...');
    final socket = await Socket.connect('192.168.1.7', 5041, timeout: Duration(seconds: 5));
    socket.destroy();
    print('✅ Socket conectado exitosamente');
  } catch (e) {
    print('❌ Socket falló: $e');
    print('🚨 Tu API C# no acepta conexiones externas');
    return;
  }
  
  // Test 2: HTTP Request
  try {
    print('📡 Test 2: HTTP Request...');
    final response = await http.get(
      Uri.parse('$testUrl/api/categorias'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    print('✅ HTTP Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('🎉 API FUNCIONANDO CORRECTAMENTE');
      final data = json.decode(response.body);
      print('📦 Datos recibidos: ${data.length} categorías');
    } else {
      print('⚠️  API responde pero con status ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ HTTP falló: $e');
    print('💡 Configura tu API para aceptar conexiones externas');
  }
}
