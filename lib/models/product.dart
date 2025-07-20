class Product {
  final String? id;
  final String name;
  final String category;
  final String? barcode;
  final int stock;
  final int minStock;
  final double costPrice;
  final double salePrice;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.category,
    this.barcode,
    required this.stock,
    this.minStock = 5,
    required this.costPrice,
    required this.salePrice,
    this.expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calcula el estado de caducidad automáticamente
  ProductStatus get status {
    if (expiryDate == null) return ProductStatus.notExpiring;
    
    final now = DateTime.now();
    final daysToExpire = expiryDate!.difference(now).inDays;
    
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

  // Calcula la ganancia por unidad
  double get profitPerUnit => salePrice - costPrice;

  // Calcula la ganancia total del stock
  double get totalProfit => profitPerUnit * stock;

  // Calcula el valor total del inventario
  double get totalInventoryValue => costPrice * stock;

  // Verifica si el stock está bajo
  bool get isLowStock => stock <= minStock;

  // Crea una copia con campos modificados
  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? barcode,
    int? stock,
    int? minStock,
    double? costPrice,
    double? salePrice,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convierte a Map para enviar a la API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'barcode': barcode,
      'stock': stock,
      'minStock': minStock,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Crea desde Map recibido de la API
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      barcode: json['barcode'],
      stock: json['stock'],
      minStock: json['minStock'] ?? 5,
      costPrice: json['costPrice'].toDouble(),
      salePrice: json['salePrice'].toDouble(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum ProductStatus {
  notExpiring,
  expiringSoon,
  expired,
}
