class Categoria {
  final int? idCategoria;
  final String nombre;
  final String? descripcion;

  Categoria({
    this.idCategoria,
    required this.nombre,
    this.descripcion,
  });

  Map<String, dynamic> toJson() {
    return {
      if (idCategoria != null) 'idCategoria': idCategoria,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['idCategoria'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }

  Categoria copyWith({
    int? idCategoria,
    String? nombre,
    String? descripcion,
  }) {
    return Categoria(
      idCategoria: idCategoria ?? this.idCategoria,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  @override
  String toString() {
    return 'Categoria(id: $idCategoria, nombre: $nombre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.idCategoria == idCategoria;
  }

  @override
  int get hashCode => idCategoria.hashCode;
}
