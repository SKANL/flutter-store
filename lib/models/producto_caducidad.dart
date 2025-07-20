class ProductoCaducidad {
  final int? idProductoCaducidad;
  final int idProducto;
  final DateTime fechaCaducidad;

  ProductoCaducidad({
    this.idProductoCaducidad,
    required this.idProducto,
    required this.fechaCaducidad,
  });

  Map<String, dynamic> toJson() {
    return {
      if (idProductoCaducidad != null) 'idProductoCaducidad': idProductoCaducidad,
      'idProducto': idProducto,
      'fechaCaducidad': fechaCaducidad.toIso8601String().split('T')[0], // YYYY-MM-DD
    };
  }

  factory ProductoCaducidad.fromJson(Map<String, dynamic> json) {
    return ProductoCaducidad(
      idProductoCaducidad: json['idProductoCaducidad'],
      idProducto: json['idProducto'],
      fechaCaducidad: DateTime.parse(json['fechaCaducidad']),
    );
  }

  ProductoCaducidad copyWith({
    int? idProductoCaducidad,
    int? idProducto,
    DateTime? fechaCaducidad,
  }) {
    return ProductoCaducidad(
      idProductoCaducidad: idProductoCaducidad ?? this.idProductoCaducidad,
      idProducto: idProducto ?? this.idProducto,
      fechaCaducidad: fechaCaducidad ?? this.fechaCaducidad,
    );
  }

  @override
  String toString() {
    return 'ProductoCaducidad(id: $idProductoCaducidad, producto: $idProducto, fecha: $fechaCaducidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductoCaducidad && other.idProductoCaducidad == idProductoCaducidad;
  }

  @override
  int get hashCode => idProductoCaducidad.hashCode;
}
