class Proveedor {
  final int? idProveedor;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? diaRecarga;

  Proveedor({
    this.idProveedor,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.diaRecarga,
  });

  Map<String, dynamic> toJson() {
    return {
      if (idProveedor != null) 'idProveedor': idProveedor,
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (direccion != null) 'direccion': direccion,
      if (diaRecarga != null) 'diaRecarga': diaRecarga,
    };
  }

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      idProveedor: json['idProveedor'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      direccion: json['direccion'],
      diaRecarga: json['diaRecarga'],
    );
  }

  Proveedor copyWith({
    int? idProveedor,
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    String? diaRecarga,
  }) {
    return Proveedor(
      idProveedor: idProveedor ?? this.idProveedor,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      diaRecarga: diaRecarga ?? this.diaRecarga,
    );
  }

  @override
  String toString() {
    return 'Proveedor(id: $idProveedor, nombre: $nombre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proveedor && other.idProveedor == idProveedor;
  }

  @override
  int get hashCode => idProveedor.hashCode;
}
