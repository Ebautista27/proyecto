import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/producto.dart'; 
import '../components/custom_bottom_nav_bar.dart'; 

import '../routes/app_routes.dart'; // Importación añadida para AppRoutes

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Producto> productos = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final List<int> productosIds = [1, 2, 3];
      List<Producto> productosCargados = [];

      for (var id in productosIds) {
        final response = await http.get(
          Uri.parse('http://127.0.0.1:5000/productos/$id'),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          productosCargados.add(Producto.fromJson(data));
        }
      }

      setState(() {
        productos = productosCargados;
        loading = false;
      });
    } catch (err) {
      setState(() {
        error = "Error al cargar los productos. Intenta recargar.";
        loading = false;
      });
    }
  }

  String _getImageUrl(String? imagenUrl) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      return 'https://via.placeholder.com/300?text=Imagen+no+disponible';
    }
    if (imagenUrl.startsWith('http')) {
      return imagenUrl;
    }
    return 'https://res.cloudinary.com/dodecmh9s/image/upload/$imagenUrl';
  }

  void _navigateToProductDetail(int productId) {
    Navigator.pushNamed(
      context,
      '${AppRoutes.detalleProducto}/$productId',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E1DA),
      appBar: AppBar(
  title: const Text(
    'Stay in Style',
    style: TextStyle(color: Colors.white),
  ),
  backgroundColor: Colors.black,
  centerTitle: true,
  iconTheme: const IconThemeData(color: Colors.white),  // Aquí defines el color de la flecha
),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Estado de carga/error
            if (loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _cargarProductos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Recargar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              )
            else
              ...productos.map((producto) => _buildProductoCard(producto)).toList(),

            // Sección de categorías
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCategoryButton(
                        icon: Icons.male,
                        label: 'Hombres',
                        onTap: () => Navigator.pushNamed(context, '/categoriash'),
                      ),
                      const SizedBox(width: 30),
                      _buildCategoryButton(
                        icon: Icons.female,
                        label: 'Mujeres',
                        onTap: () => Navigator.pushNamed(context, '/categoriasm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  Widget _buildProductoCard(Producto producto) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToProductDetail(producto.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _getImageUrl(producto.imagenUrl),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                producto.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('\$${producto.precio.toStringAsFixed(2)} COP'),
              Chip(
                label: Text(
                  producto.disponible ? 'Disponible' : 'Agotado',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: producto.disponible ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.black,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}