class DetalleVenta {
  final int? idDetalle;
  final int? idVenta;
  final int idProducto;
  final int cantidad;
  final double precioUnitario;
  final String? nombreProducto;
  final String? codigoBarras;

  DetalleVenta({
    this.idDetalle,
    this.idVenta,
    required this.idProducto,
    required this.cantidad,
    required this.precioUnitario,
    this.nombreProducto,
    this.codigoBarras,
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toJson() {
    return {
      if (idDetalle != null) 'idDetalle': idDetalle,
      if (idVenta != null) 'idVenta': idVenta,
      'idProducto': idProducto,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
    };
  }

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      idDetalle: json['idDetalle'],
      idVenta: json['idVenta'],
      idProducto: json['idProducto'],
      cantidad: json['cantidad'] ?? 0,
      precioUnitario: json['precioUnitario']?.toDouble() ?? 0.0,
      nombreProducto: json['nombreProducto'],
      codigoBarras: json['codigoBarras'],
    );
  }

  DetalleVenta copyWith({
    int? idDetalle,
    int? idVenta,
    int? idProducto,
    int? cantidad,
    double? precioUnitario,
    String? nombreProducto,
    String? codigoBarras,
  }) {
    return DetalleVenta(
      idDetalle: idDetalle ?? this.idDetalle,
      idVenta: idVenta ?? this.idVenta,
      idProducto: idProducto ?? this.idProducto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      codigoBarras: codigoBarras ?? this.codigoBarras,
    );
  }

  @override
  String toString() {
    return 'DetalleVenta(id: $idDetalle, producto: $idProducto, cantidad: $cantidad, precio: \$${precioUnitario.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetalleVenta && other.idDetalle == idDetalle;
  }

  @override
  int get hashCode => idDetalle.hashCode;
}
