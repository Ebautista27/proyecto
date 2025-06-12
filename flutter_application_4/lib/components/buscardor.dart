import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Importamos Timer desde aquí
import '../models/producto.dart';

class BuscadorProductos extends StatefulWidget {
  @override
  _BuscadorProductosState createState() => _BuscadorProductosState();
}

class _BuscadorProductosState extends State<BuscadorProductos> {
  List<Producto> productos = [];
  String searchTerm = '';
  String? categoria;
  List<String> categorias = [];
  bool loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _getImageUrl(String? imagenUrl) {
    if (imagenUrl == null) {
      return 'https://res.cloudinary.com/dodecmh9s/image/upload/v1620000000/default.jpg';
    }
    if (imagenUrl.contains('res.cloudinary.com')) {
      return imagenUrl;
    }
    if (!imagenUrl.startsWith('http')) {
      return 'https://res.cloudinary.com/dodecmh9s/image/upload/$imagenUrl';
    }
    return imagenUrl;
  }

  Future<void> _fetchCategorias() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/categorias'));
      if (response.statusCode == 200) {
        setState(() {
          categorias = List<String>.from(json.decode(response.body));
        });
      }
    } catch (error) {
      print('Error fetching categorías: $error');
    }
  }

  Future<void> _fetchProductos() async {
    setState(() => loading = true);
    try {
      final params = {
        if (searchTerm.isNotEmpty) 'search': searchTerm,
        if (categoria != null) 'categoria': categoria!,
      };
      final uri = Uri.parse('http://localhost:5000/productos').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<Producto> productosProcesados = (json.decode(response.body) as List)
            .map((json) => Producto.fromJson(json))
            .toList();
        setState(() => productos = productosProcesados);
      }
    } catch (error) {
      print('Error fetching productos: $error');
    } finally {
      setState(() => loading = false);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => searchTerm = value);
      _fetchProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encuentra lo que buscas',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF2c3e50)
            ),
          ),
          const SizedBox(height: 20),
          
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12, 
                horizontal: 16
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          
          // Selector de categoría
          DropdownButtonFormField<String>(
            value: categoria,
            hint: const Text('Todas las categorías'),
            items: categorias.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => categoria = value);
              _fetchProductos();
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, 
                vertical: 12
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Resultados
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (productos.isEmpty && (searchTerm.isNotEmpty || categoria != null))
            Column(
              children: [
                const Text('No se encontraron productos'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      searchTerm = '';
                      categoria = null;
                    });
                    _fetchProductos();
                  },
                  child: const Text('Limpiar búsqueda'),
                ),
              ],
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final producto = productos[index];
                  return _ProductoCard(producto: producto);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;

  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, '/producto/${producto.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  producto.imagenUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Image.network(
                    'https://res.cloudinary.com/dodecmh9s/image/upload/v1620000000/default.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${producto.precio.toStringAsFixed(2)} COP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF27ae60),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: producto.disponible ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      producto.disponible ? 'Disponible' : 'Agotado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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