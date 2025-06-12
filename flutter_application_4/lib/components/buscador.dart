import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:debounce_throttle/debounce_throttle.dart';

class BuscadorProductos extends StatefulWidget {
  @override
  _BuscadorProductosState createState() => _BuscadorProductosState();
}

class _BuscadorProductosState extends State<BuscadorProductos> {
  List<dynamic> productos = [];
  String searchTerm = '';
  String categoria = '';
  List<dynamic> categorias = [];
  bool loading = false;

  late Debouncer<void> _debouncer;

  String getImageUrl(String? imagenUrl) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
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

  Future<void> fetchCategorias() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/categorias'));
      if (response.statusCode == 200) {
        setState(() {
          categorias = json.decode(response.body);
        });
      }
    } catch (error) {
      print('Error fetching categorías: $error');
    }
  }

  Future<void> fetchProductos() async {
    setState(() => loading = true);
    try {
      final params = {
        if (searchTerm.isNotEmpty) 'search': searchTerm,
        if (categoria.isNotEmpty) 'categoria': categoria,
      };
      final uri = Uri.parse('http://localhost:5000/productos').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          productos = data.map((producto) {
            return {
              'id': producto['id'],
              'nombre': producto['nombre'],
              'precio': producto['precio'],
              'estado': producto['estado'],
              'imagen_url': getImageUrl(producto['imagen_url']),
            };
          }).toList();
        });
      }
    } catch (error) {
      print('Error fetching productos: $error');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategorias();

    _debouncer = Debouncer<void>(
      Duration(milliseconds: 500),
      initialValue: null,
      onChanged: (_) {
        if (searchTerm.isNotEmpty || categoria.isNotEmpty) {
          fetchProductos();
        } else {
          setState(() => productos = []);
        }
      },
    );
  }

  void handleClickProducto(String idProducto) {
    Navigator.pushNamed(context, '/productos/$idProducto');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Encuentra lo que buscas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchTerm = value);
                _debouncer.setValue(null);
              },
            ),
            SizedBox(height: 16),
            if (loading)
              Center(child: CircularProgressIndicator())
            else if (productos.isEmpty && (searchTerm.isNotEmpty || categoria.isNotEmpty))
              Column(
                children: [
                  Text('No se encontraron productos'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        searchTerm = '';
                        categoria = '';
                      });
                      _debouncer.setValue(null);
                    },
                    child: Text('Limpiar búsqueda'),
                  ),
                ],
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    return GestureDetector(
                      onTap: () => handleClickProducto(producto['id'].toString()),
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                producto['imagen_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.network(
                                  'https://res.cloudinary.com/dodecmh9s/image/upload/v1620000000/default.jpg',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto['nombre'],
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('\$${producto['precio']?.toString() ?? '0'} COP'),
                                  Chip(
                                    label: Text(producto['estado'] ?? 'Disponible'),
                                    backgroundColor: _getStatusColor(producto['estado']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? estado) {
    final status = estado?.toLowerCase() ?? 'disponible';
    switch (status) {
      case 'agotado':
        return Colors.red[100]!;
      case 'en oferta':
        return Colors.green[100]!;
      default:
        return Colors.blue[100]!;
    }
  }
}
