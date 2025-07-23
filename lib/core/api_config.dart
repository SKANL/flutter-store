import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_logger.dart';

class ApiConfig {
  // URL base de tu API de C# - CONFIGURACIÓN PARA ANDROID
  // Android no puede usar localhost, necesita la IP local de la PC
  static const String _defaultBaseUrl = 'http://10.0.2.2:5041'; // Emulador Android -> localhost en PC host
  static String _currentBaseUrl = _defaultBaseUrl;
  
  // Configuraciones de timeout
  static const Duration timeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  
  // Headers comunes
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };
  
  // URLs específicas para diferentes entornos
  static const String emulatorUrl = 'http://10.0.2.2:5041';     // 10.0.2.2 es localhost para emulador Android
  static const String localDeviceUrl = 'http://192.168.1.7:5041'; // IP de la PC en la red local
  static const String localHostUrl = 'http://localhost:5041';     // Para pruebas en Windows/Web
  static const String allInterfacesUrl = 'http://0.0.0.0:5041';  // Escucha en todas las interfaces
  static const String productionUrl = 'https://tu-dominio.com';
  
  // Determina si está en modo debug
  static bool get isDebug {
    bool debug = false;
    assert(debug = true);
    return debug;
  }
  
  // Obtiene la URL actual (configurable dinámicamente)
  static String get currentBaseUrl {
    return _currentBaseUrl;
  }
  
  // Método para actualizar la URL base
  static void updateBaseUrl(String newBaseUrl) {
    _currentBaseUrl = newBaseUrl;
    AppLogger.info('URL de API actualizada a: $_currentBaseUrl', 'API_CONFIG');
  }
  
  // Método para restaurar la URL por defecto
  static void resetToDefault() {
    _currentBaseUrl = _defaultBaseUrl;
    AppLogger.info('URL de API restaurada al valor predeterminado: $_currentBaseUrl', 'API_CONFIG');
  }
  
  // Auto-configurar la URL base según el entorno
  static Future<void> configureForEnvironment({String? manualUrl}) async {
    if (manualUrl != null && manualUrl.isNotEmpty) {
      updateBaseUrl(manualUrl);
      AppLogger.info('URL de API configurada manualmente: $manualUrl', 'API_CONFIG');
      return;
    }

    // Lista de URLs posibles para probar, incluyendo patrones comunes de IP local
    // Primero, obtenemos las IPs del dispositivo para poder generar URLs dinámicamente
    final deviceIps = await getDeviceIpAddresses();
    final dynamicIpUrls = <String>[];
    
    // Para cada IP del dispositivo, generamos variaciones de posibles IPs del servidor
    for (final ip in deviceIps) {
      if (ip.startsWith('192.168.')) {
        // Si es una IP 192.168.x.y, intentamos varias IPs de la misma subred
        final parts = ip.split('.');
        if (parts.length == 4) {
          final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
          // Probar los primeros N hosts de la subred (incluyendo puerta de enlace)
          for (int i = 1; i <= 10; i++) {
            dynamicIpUrls.add('http://$subnet.$i:5041');
          }
          // Probar algunos hosts comunes en subredes domésticas
          for (final lastOctet in [100, 101, 102, 200, 254]) {
            dynamicIpUrls.add('http://$subnet.$lastOctet:5041');
          }
        }
      }
    }
    
    // Combinamos las URLs predefinidas con las generadas dinámicamente
    final urlsToTry = [
      emulatorUrl,         // Para emulador Android
      localHostUrl,        // Para desarrollo local en Windows/Web
      localDeviceUrl,      // IP específica configurada
      allInterfacesUrl,    // Todas las interfaces (0.0.0.0)
      'http://127.0.0.1:5041',   // localhost alternativo
      'http://10.0.0.2:5041',    // IPs comunes para desarrollo
      'http://10.0.0.1:5041',
      'http://192.168.0.1:5041', // IPs comunes en routers domésticos
      'http://192.168.0.100:5041',
      'http://192.168.0.101:5041',
      'http://192.168.1.100:5041',
      'http://192.168.1.101:5041',
      'http://192.168.1.2:5041',
      'http://192.168.2.1:5041',
      ...dynamicIpUrls,    // URLs generadas dinámicamente basadas en la subred del dispositivo
    ];
    
    // Probar cada URL en paralelo para mayor velocidad
    final futures = <Future<String?>>[];
    
    for (final url in urlsToTry) {
      futures.add(_tryConnection(url));
    }
    
    // Esperar resultados y encontrar la primera URL que funcione
    final results = await Future.wait(futures);
    final workingUrl = results.firstWhere((url) => url != null, orElse: () => null);
    
    if (workingUrl != null) {
      updateBaseUrl(workingUrl);
      AppLogger.info('Conexión exitosa detectada en: $workingUrl', 'API_CONFIG');
    } else {
      AppLogger.warning('No se pudo detectar automáticamente un servidor API. Usando URL predeterminada: $_currentBaseUrl', 'API_CONFIG');
    }
  }
  
  // Intenta conectarse a una URL y devuelve la URL si la conexión es exitosa, null en caso contrario
  static Future<String?> _tryConnection(String url) async {
    try {
      final isConnected = await testApiConnection(url);
      return isConnected ? url : null;
    } catch (e) {
      return null;
    }
  }

  // Probar conexión a una URL específica
  static Future<bool> testApiConnection(String url) async {
    AppLogger.debug('Probando conexión a API: $url', 'API_CONFIG');
    final client = http.Client();
    
    // Lista de endpoints para probar en orden
    final endpoints = [
      '/api/ping',         // Endpoint específico para comprobaciones (si existe)
      '/api/categorias',   // Endpoint principal de la aplicación
      '/api/proveedores',  // Otro endpoint principal
      '/api/productos',    // Otro endpoint principal
      '/api',              // Ruta base de la API
      '/',                 // Raíz (podría devolver algo en la API)
    ];
    
    try {
      // Probar cada endpoint hasta encontrar uno que responda
      for (final endpoint in endpoints) {
        try {
          final response = await client
              .get(Uri.parse('$url$endpoint'))
              .timeout(const Duration(milliseconds: 1500)); // Timeout más corto para probar rápido
          
          // Cualquier respuesta HTTP válida (incluso 404) indica que el servidor está ejecutándose
          // 200 = OK, 404 = No encontrado pero el servidor responde, etc.
          if (response.statusCode >= 200 && response.statusCode < 600) {
            AppLogger.debug('Conexión exitosa a $url$endpoint (HTTP ${response.statusCode})', 'API_CONFIG');
            return true;
          }
        } catch (e) {
          // Ignorar errores individuales y continuar con el siguiente endpoint
          continue;
        }
      }
      
      // Si llegamos aquí, ningún endpoint respondió correctamente
      return false;
    } catch (e) {
      AppLogger.debug('Error de conexión API: $e', 'API_CONFIG');
      return false;
    } finally {
      client.close();
    }
  }
  
  // Este método ha sido reemplazado por _tryConnection
  
  // Getter para acceso desde otras clases
  static String get baseUrl => currentBaseUrl;
  
  // Detecta la dirección IP local del dispositivo
  static Future<List<String>> getDeviceIpAddresses() async {
    try {
      final interfaces = await _getNetworkInterfaces();
      return interfaces;
    } catch (e) {
      AppLogger.warning('Error al obtener direcciones IP: $e', 'API_CONFIG');
      return [];
    }
  }
  
  // Obtiene interfaces de red
  static Future<List<String>> _getNetworkInterfaces() async {
    try {
      final interfaces = <String>[];
      
      // Este código usa dart:io para obtener direcciones IP
      try {
        final networkInterfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        
        for (var interface in networkInterfaces) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              interfaces.add(addr.address);
            }
          }
        }
      } catch (e) {
        AppLogger.debug('Error en NetworkInterface.list: $e', 'API_CONFIG');
      }
      
      return interfaces;
    } catch (e) {
      return [];
    }
  }
}

class ApiEndpoints {
  // Categorías
  static const String categorias = '/api/categorias';
  static String categoriaById(int id) => '/api/categorias/$id';
  
  // Proveedores
  static const String proveedores = '/api/proveedores';
  static String proveedorById(int id) => '/api/proveedores/$id';
  
  // Productos
  static const String productos = '/api/productos';
  static String productoById(int id) => '/api/productos/$id';
  
  // Producto Caducidad
  static const String productoCaducidad = '/api/productocaducidad';
  static String productoCaducidadById(int id) => '/api/productocaducidad/$id';
  
  // Ventas
  static const String ventas = '/api/ventas';
  static const String ventasWithDetails = '/api/ventas/withdetails';
  static String ventaById(int id) => '/api/ventas/$id';
  
  // Detalles de Venta
  static const String detallesVenta = '/api/detallesventa';
  static String detalleVentaById(int id) => '/api/detallesventa/$id';
  
  // Vistas
  static const String vistasProductosStatus = '/api/vistas/productos-status';
  static const String vistasStockBajo = '/api/vistas/stock-bajo';
}
