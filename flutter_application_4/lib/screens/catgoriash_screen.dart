import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/buscador.dart'; // Asegúrate de tener este componente

class CategoriashScreen extends StatefulWidget {
  @override
  _CategoriashScreenState createState() => _CategoriashScreenState();
}

class _CategoriashScreenState extends State<CategoriashScreen> {
  List<dynamic> productos = [];
  bool loading = true;
  String? error;

  // Función para verificar disponibilidad
  bool verificarDisponibilidad(dynamic producto) {
    return producto['estado'] != "Agotado" && producto['estado'] != "No disponible";
  }

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/productos'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        final productosHombres = data
          .where((producto) => producto['id_genero'] == 1)
          .map((producto) => {
                ...producto,
                'imagen_url': producto['imagen_url'] ?? 'https://via.placeholder.com/300?text=Imagen+no+disponible',
                'disponible': verificarDisponibilidad(producto),
              })
          .toList();

        setState(() {
          productos = productosHombres;
          loading = false;
        });
      } else {
        throw Exception('Error al obtener productos');
      }
    } catch (err) {
      setState(() {
        error = "Error al cargar los productos. Intenta recargar la página.";
        loading = false;
      });
      print("Error al obtener productos: $err");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando productos...'),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            error = null;
                          });
                          cargarProductos();
                        },
                        child: Text('Recargar página'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Buscador
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: BuscadorProductos(),
                      ),

                      // Título
                      Text(
                        'Prendas para Hombres',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Lista de productos
                      productos.isEmpty
                          ? Center(
                              child: Text(
                                'No hay productos disponibles en esta categoría',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: productos.length,
                              itemBuilder: (context, index) {
                                final producto = productos[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/productos/${producto['id']}',
                                    );
                                  },
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Imagen del producto
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(10)),
                                            child: CachedNetworkImage(
                                              imageUrl: producto['imagen_url'],
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Center(
                                                  child: CircularProgressIndicator()),
                                              errorWidget: (context, url, error) =>
                                                  Image.network(
                                                'https://via.placeholder.com/300?text=Imagen+no+disponible',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Info del producto
                                        Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                producto['nombre'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                '\$${producto['precio']?.toStringAsFixed(2) ?? '0'} COP',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: producto['disponible']
                                                      ? Colors.green[100]
                                                      : Colors.red[100],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  producto['disponible']
                                                      ? 'Disponible'
                                                      : 'Agotado',
                                                  style: TextStyle(
                                                    color: producto['disponible']
                                                        ? Colors.green[800]
                                                        : Colors.red[800],
                                                    fontSize: 12,
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
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}