class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String estado;
  final int idCategoria;
  final int idGenero;
  final String? imagenUrl;

  // Getter para saber si el producto está disponible
  bool get disponible => estado.toLowerCase() == 'disponible';

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.estado,
    required this.idCategoria,
    required this.idGenero,
    this.imagenUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'Desconocido',
      idCategoria: json['id_categoria'] ?? 0,
      idGenero: json['id_genero'] ?? 0,
      imagenUrl: json['imagen_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'estado': estado,
      'id_categoria': idCategoria,
      'id_genero': idGenero,
      'imagen_url': imagenUrl,
    };
  }
}
