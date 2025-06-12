import 'package:flutter/material.dart';
import '../models/producto.dart'; // Importa el modelo

class ProductoCard extends StatelessWidget {
  final Producto producto;

  const ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/producto',
            arguments: {
              'id': producto.id,
              'nombre': producto.nombre,
              'precio': producto.precio.toString(),
              'descripcion': producto.descripcion,
            },
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                producto.imagenUrl ?? 'https://via.placeholder.com/300?text=Imagen+no+disponible',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  'https://via.placeholder.com/300?text=Imagen+no+disponible',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('\$${producto.precio.toStringAsFixed(2)} COP'),
                  Chip(
                    label: Text(
                      producto.disponible ? 'Disponible' : 'Agotado',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: producto.disponible ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
