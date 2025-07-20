import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Test de Conectividad API - OPTIMIZADO');
  print('=======================================');
  
  final url = 'http://localhost:5041';
  
  // Verificar si el puerto está abierto primero
  print('\n1. Verificando si el puerto 5041 está abierto...');
  try {
    final socket = await Socket.connect('localhost', 5041, timeout: Duration(seconds: 3));
    socket.destroy();
    print('✅ Puerto 5041 está abierto');
  } catch (e) {
    print('❌ Puerto 5041 no está abierto o no responde');
    print('💡 Verifica que tu API C# esté ejecutándose');
    return;
  }
  
  // Probar endpoint específico
  try {
    print('\n2. Probando endpoint /api/categorias...');
    
    final response = await http.get(
      Uri.parse('$url/api/categorias'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 10));
    
    print('✅ Status Code: ${response.statusCode}');
    print('✅ Content-Type: ${response.headers['content-type']}');
    
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        print('✅ JSON válido recibido');
        if (data is List) {
          print('✅ Número de categorías: ${data.length}');
          if (data.isNotEmpty) {
            print('✅ Primera categoría: ${data[0]}');
          }
        }
        print('\n🎉 ¡CONEXIÓN EXITOSA! Tu API está funcionando correctamente.');
      } catch (e) {
        print('❌ Error al parsear JSON: $e');
        print('📄 Respuesta recibida: ${response.body.substring(0, 200)}...');
      }
    } else {
      print('❌ Error HTTP: ${response.statusCode}');
      print('❌ Respuesta: ${response.body}');
    }
    
  } catch (e) {
    print('❌ Error de conexión: $e');
    
    if (e is SocketException) {
      print('💡 La API no está disponible en $url');
      print('💡 Verifica que tu API C# esté corriendo');
    } else if (e.toString().contains('TimeoutException')) {
      print('💡 Timeout - la API no responde en 10 segundos');
    } else if (e is FormatException) {
      print('💡 La API devolvió datos en formato incorrecto');
    } else if (e.toString().contains('Connection refused')) {
      print('💡 Conexión rechazada - la API no está escuchando en el puerto 5041');
    } else if (e.toString().contains('CORS')) {
      print('💡 Problema de CORS - verifica la configuración de tu API');
    }
  }
}
