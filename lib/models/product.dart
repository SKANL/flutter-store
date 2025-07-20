import 'categoria.dart';
import 'proveedor.dart';
import 'producto_caducidad.dart';

class Product {
  final int? idProducto;
  final String nombre;
  final String? codigoDeBarra;
  final double precioCosto;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  final int idCategoria;
  final int? idProveedor;
  
  // Campos relacionados (no se envían en el JSON, se obtienen por joins)
  final Categoria? categoria;
  final Proveedor? proveedor;
  final List<ProductoCaducidad> caducidades;
  
  // Campos calculados localmente
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.idProducto,
    required this.nombre,
    this.codigoDeBarra,
    required this.precioCosto,
    required this.precioVenta,
    required this.stockActual,
    this.stockMinimo = 5,
    required this.idCategoria,
    this.idProveedor,
    this.categoria,
    this.proveedor,
    this.caducidades = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Obtiene la fecha de caducidad más próxima
  DateTime? get fechaCaducidad {
    if (caducidades.isEmpty) return null;
    
    final fechasOrdenadas = caducidades
        .map((c) => c.fechaCaducidad)
        .toList()
      ..sort();
    
    return fechasOrdenadas.first;
  }

  // Calcula el estado de caducidad automáticamente
  ProductStatus get status {
    final caducidad = fechaCaducidad;
    if (caducidad == null) return ProductStatus.notExpiring;
    
    final now = DateTime.now();
    final daysToExpire = caducidad.difference(now).inDays;
    
    if (daysToExpire < 0) return ProductStatus.expired;
    if (daysToExpire <= 30) return ProductStatus.expiringSoon;
    return ProductStatus.notExpiring;
  }

  // Obtiene el ícono y color según el estado
  String get statusIcon {
    switch (status) {
      case ProductStatus.notExpiring:
        return '✅';
      case ProductStatus.expiringSoon:
        return '⚠️';
      case ProductStatus.expired:
        return '❌';
    }
  }

  String get statusText {
    switch (status) {
      case ProductStatus.notExpiring:
        return 'Sin caducar';
      case ProductStatus.expiringSoon:
        return 'Por caducar';
      case ProductStatus.expired:
        return 'Caducado';
    }
  }

  // Obtiene el nombre de la categoría
  String get categoryName => categoria?.nombre ?? 'Sin categoría';

  // Obtiene el nombre del proveedor
  String get providerName => proveedor?.nombre ?? '';

  // Calcula la ganancia por unidad
  double get profitPerUnit => precioVenta - precioCosto;

  // Calcula la ganancia total del stock
  double get totalProfit => profitPerUnit * stockActual;

  // Calcula el valor total del inventario
  double get totalInventoryValue => precioCosto * stockActual;

  // Verifica si el stock está bajo
  bool get isLowStock => stockActual <= stockMinimo;

  // Crea una copia con campos modificados
  Product copyWith({
    int? idProducto,
    String? nombre,
    String? codigoDeBarra,
    double? precioCosto,
    double? precioVenta,
    int? stockActual,
    int? stockMinimo,
    int? idCategoria,
    int? idProveedor,
    Categoria? categoria,
    Proveedor? proveedor,
    List<ProductoCaducidad>? caducidades,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      idProducto: idProducto ?? this.idProducto,
      nombre: nombre ?? this.nombre,
      codigoDeBarra: codigoDeBarra ?? this.codigoDeBarra,
      precioCosto: precioCosto ?? this.precioCosto,
      precioVenta: precioVenta ?? this.precioVenta,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      idCategoria: idCategoria ?? this.idCategoria,
      idProveedor: idProveedor ?? this.idProveedor,
      categoria: categoria ?? this.categoria,
      proveedor: proveedor ?? this.proveedor,
      caducidades: caducidades ?? this.caducidades,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convierte a Map para enviar a la API (solo campos del modelo de BD)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'nombre': nombre,
      'precioCosto': precioCosto,
      'precioVenta': precioVenta,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'idCategoria': idCategoria,
    };
    
    // Incluir ID solo si existe (para actualizaciones)
    if (idProducto != null) {
      json['idProducto'] = idProducto;
    }
    
    // Incluir código de barras siempre, incluso si es null o vacío
    // Esto asegura que el campo se envíe a la API
    json['codigoDeBarra'] = codigoDeBarra;
    
    // Incluir proveedor solo si existe
    if (idProveedor != null) {
      json['idProveedor'] = idProveedor;
    }
    
    return json;
  }

  // Crea desde Map recibido de la API
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      idProducto: json['idProducto'],
      nombre: json['nombre'],
      codigoDeBarra: json['codigoDeBarra'],
      precioCosto: (json['precioCosto'] as num).toDouble(),
      precioVenta: (json['precioVenta'] as num).toDouble(),
      stockActual: json['stockActual'],
      stockMinimo: json['stockMinimo'] ?? 5,
      idCategoria: json['idCategoria'],
      idProveedor: json['idProveedor'],
      categoria: json['categoria'] != null 
          ? Categoria.fromJson(json['categoria']) 
          : null,
      proveedor: json['proveedor'] != null 
          ? Proveedor.fromJson(json['proveedor']) 
          : null,
      caducidades: json['caducidades'] != null
          ? (json['caducidades'] as List)
              .map((c) => ProductoCaducidad.fromJson(c))
              .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  String toString() {
    return 'Product(id: $idProducto, nombre: $nombre, categoria: $idCategoria, stock: $stockActual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.idProducto == idProducto;
  }

  @override
  int get hashCode => idProducto.hashCode;
}

enum ProductStatus {
  notExpiring,
  expiringSoon,
  expired,
}
