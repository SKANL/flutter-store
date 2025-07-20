class ApiConfig {
  // URL base de tu API de C# - CONFIGURACIÓN PARA ANDROID
  // Android no puede usar localhost, necesita la IP local de la PC
  static const String baseUrl = 'http://192.168.1.7:5041';
  
  // Configuraciones de timeout
  static const Duration timeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  
  // Headers comunes
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };
  
  // URLs específicas para desarrollo y producción
  static const String developmentUrl = 'http://192.168.1.7:5041';  // IP local para Android
  static const String productionUrl = 'https://tu-dominio.com';
  
  // Determina si está en modo debug
  static bool get isDebug {
    bool debug = false;
    assert(debug = true);
    return debug;
  }
  
  // Obtiene la URL según el entorno
  static String get currentBaseUrl {
    return isDebug ? developmentUrl : productionUrl;
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
  static const String ventasWithDetails = '/api/ventas/with-details';
  static String ventaById(int id) => '/api/ventas/$id';
  
  // Detalles de Venta
  static const String detallesVenta = '/api/detallesventa';
  static String detalleVentaById(int id) => '/api/detallesventa/$id';
}
