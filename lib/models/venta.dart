import 'detalle_venta.dart';

class Venta {
  final int? idVenta;
  final DateTime fecha;
  final double total;
  final List<DetalleVenta>? detalles;

  Venta({
    this.idVenta,
    required this.fecha,
    required this.total,
    this.detalles,
  });

  Map<String, dynamic> toJson() {
    return {
      if (idVenta != null) 'idVenta': idVenta,
      'fecha': fecha.toIso8601String(), // Fecha completa con hora para la API
      'total': total,
      if (detalles != null) 'detallesVenta': detalles!.map((d) => d.toJson()).toList(),
    };
  }

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      idVenta: json['idVenta'],
      fecha: DateTime.parse(json['fecha']),
      total: json['total']?.toDouble() ?? 0.0,
      detalles: json['detallesVenta'] != null 
        ? (json['detallesVenta'] as List).map((d) => DetalleVenta.fromJson(d)).toList()
        : json['detalles'] != null 
          ? (json['detalles'] as List).map((d) => DetalleVenta.fromJson(d)).toList()
          : null,
    );
  }

  Venta copyWith({
    int? idVenta,
    DateTime? fecha,
    double? total,
    List<DetalleVenta>? detalles,
  }) {
    return Venta(
      idVenta: idVenta ?? this.idVenta,
      fecha: fecha ?? this.fecha,
      total: total ?? this.total,
      detalles: detalles ?? this.detalles,
    );
  }

  @override
  String toString() {
    return 'Venta(id: $idVenta, fecha: $fecha, total: \$${total.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Venta && other.idVenta == idVenta;
  }

  @override
  int get hashCode => idVenta.hashCode;
}
