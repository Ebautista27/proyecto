class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const checkout = '/checkout';
}

class ApiEndpoints {
  static const baseUrl = 'http://localhost:5000';
  static const carrito = '$baseUrl/api/carritos';
  static const carritoProductos = '$carrito/productos';
}

class Carrito {
  final List<ProductoCarrito> productos;
  final double total;

  Carrito({required this.productos, required this.total});
  
  factory Carrito.fromJson(Map<String, dynamic> json) {
    return Carrito(
      productos: (json['productos'] as List)
          .map((e) => ProductoCarrito.fromJson(e))
          .toList(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class ProductoCarrito {
  final String idProducto;
  final String idTalla;
  final String nombre;
  final String? imagenUrl;
  final String talla;
  final double precioUnitario;
  final int stockDisponible;
  final int cantidad;
  final double subtotal;
  final bool puedeAumentar;

  ProductoCarrito({
    required this.idProducto,
    required this.idTalla,
    required this.nombre,
    this.imagenUrl,
    required this.talla,
    required this.precioUnitario,
    required this.stockDisponible,
    required this.cantidad,
    required this.subtotal,
    required this.puedeAumentar,
  });
  
  factory ProductoCarrito.fromJson(Map<String, dynamic> json) {
    return ProductoCarrito(
      idProducto: json['id_producto'] as String,
      idTalla: json['id_talla'] as String,
      nombre: json['nombre'] as String,
      imagenUrl: json['imagen_url'] as String?,
      talla: json['talla'] as String,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      stockDisponible: json['stock_disponible'] as int,
      cantidad: json['cantidad'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      puedeAumentar: json['puede_aumentar'] ?? false,
    );
  }
}

class Utils {
  static String getImageUrl(String? imagenUrl) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      return 'https://placehold.co/300x300?text=Imagen+no+disponible';
    }
    if (imagenUrl.startsWith('http')) {
      return imagenUrl;
    }
    return 'https://res.cloudinary.com/dodecmh9s/image/upload/w_300,h_300,c_fill/$imagenUrl';
  }
}