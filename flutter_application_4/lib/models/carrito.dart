class CarritoItem {
  final String productoId;
  final String tallaId;
  int cantidad;

  CarritoItem({
    required this.productoId,
    required this.tallaId,
    required this.cantidad,
  });
}

class Carrito {
  List<CarritoItem> productos = [];

  void eliminarProducto(String productoId, String tallaId) {
    productos.removeWhere((item) =>
        item.productoId == productoId && item.tallaId == tallaId);
  }

  void actualizarCantidad(String productoId, String tallaId, int nuevaCantidad) {
    final item = productos.firstWhere(
        (item) => item.productoId == productoId && item.tallaId == tallaId,
        orElse: () => throw Exception('Producto no encontrado'));
    item.cantidad = nuevaCantidad;
  }

  double calcularTotal() {
    // Supongamos que cada producto cuesta 10 (solo ejemplo)
    return productos.length * 10.0;
  }
}
