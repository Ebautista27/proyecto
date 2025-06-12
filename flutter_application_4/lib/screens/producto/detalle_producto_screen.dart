import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DetalleProductoScreen extends StatefulWidget {
  final String idProducto;

  const DetalleProductoScreen({Key? key, required this.idProducto}) : super(key: key);

  @override
  _DetalleProductoScreenState createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  dynamic producto;
  List<dynamic> reviews = [];
  dynamic tallaSeleccionada;
  int cantidad = 1;
  Map<String, dynamic> nuevaReview = {
    'comentario': '',
    'calificacion': 0,
  };
  bool loading = true;
  String? error;
  List<dynamic> tallasDisponibles = [];
  List<dynamic> tallasAgotadas = [];
  final _formKey = GlobalKey<FormState>();
  bool addingToCart = false;

  String getImageUrl(String? imagenUrl) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      return 'https://via.placeholder.com/400';
    }
    if (imagenUrl.contains('res.cloudinary.com')) {
      return imagenUrl;
    }
    if (!imagenUrl.startsWith('http')) {
      return 'https://res.cloudinary.com/dodecmh9s/image/upload/$imagenUrl';
    }
    return imagenUrl;
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final responses = await Future.wait([
        http.get(Uri.parse('http://localhost:5000/productos/${widget.idProducto}')),
        http.get(Uri.parse('http://localhost:5000/productos/${widget.idProducto}/reseñas')).catchError((_) => null),
        http.get(Uri.parse('http://localhost:5000/api/productos/${widget.idProducto}/tallas-disponibles')),
      ]);

      if (responses[0].statusCode != 200) {
        throw Exception('Producto no encontrado');
      }

      final productoData = json.decode(responses[0].body);
      final reviewsData = responses[1] != null ? json.decode(responses[1].body) : [];
      final tallasData = json.decode(responses[2].body)['tallas'] ?? [];

      final disponibles = tallasData.where((t) => t['disponible'] == true).toList();
      final agotadas = tallasData.where((t) => t['disponible'] == false).toList();

      setState(() {
        producto = {
          ...productoData,
          'imagen_url': getImageUrl(productoData['imagen_url']),
          'precio': double.parse(productoData['precio']?.toString() ?? '0').toStringAsFixed(2),
        };
        reviews = reviewsData;
        tallasDisponibles = disponibles;
        tallasAgotadas = agotadas;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar el producto';
        loading = false;
      });
      _showErrorDialog('Error', 'No se pudo cargar el producto');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Añadido al carrito!'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Image.network(
                producto['imagen_url'],
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.network(
                  'https://via.placeholder.com/400',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                producto['nombre'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Talla: ${tallaSeleccionada['talla']}'),
                  Text('Cantidad: $cantidad'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '\$${(double.parse(producto['precio']) * cantidad).toStringAsFixed(2)} COP',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('¡Entendido!'),
          ),
        ],
      ),
    );
  }

  Future<bool> _verificarAutenticacion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }

  Future<void> _agregarProductoAlCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/carritos/productos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_producto': widget.idProducto,
          'id_talla': tallaSeleccionada['id_talla'],
          'cantidad': cantidad,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        throw Exception('Error al agregar al carrito: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> handleAgregarAlCarrito() async {
    // Verificar si el usuario está autenticado
    final estaAutenticado = await _verificarAutenticacion();
    if (!estaAutenticado) {
      _showErrorDialog('Acceso requerido', 'Debes iniciar sesión para agregar productos al carrito');
      return;
    }

    if (tallaSeleccionada == null) {
      Fluttertoast.showToast(
        msg: 'Por favor selecciona una talla',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    if (cantidad > tallaSeleccionada['stock']) {
      Fluttertoast.showToast(
        msg: 'Solo quedan ${tallaSeleccionada['stock']} unidades disponibles',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      addingToCart = true;
    });

    try {
      await _agregarProductoAlCarrito();
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo agregar al carrito: ${e.toString()}');
    } finally {
      setState(() {
        addingToCart = false;
      });
    }
  }

  Future<void> enviarReview() async {
    if (nuevaReview['comentario']!.isEmpty || nuevaReview['calificacion'] == 0) {
      Fluttertoast.showToast(
        msg: 'Por favor completa todos los campos',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showErrorDialog('Error', 'Debes iniciar sesión para dejar una review');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/productos/${widget.idProducto}/crear-reseña'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'comentario': nuevaReview['comentario'],
          'calificacion': nuevaReview['calificacion'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          reviews.add(json.decode(response.body));
          nuevaReview = {'comentario': '', 'calificacion': 0};
        });
        Fluttertoast.showToast(
          msg: '¡Review publicada!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Future.delayed(const Duration(seconds: 2), () {
          fetchData();
        });
      } else {
        throw Exception('Error al enviar review');
      }
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo publicar la review');
    }
  }

  Widget renderEstrellas(int calificacion) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < calificacion ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando producto...'),
            ],
          ),
        ),
      );
    }

    if (error != null || producto == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¡Ups! Algo salió mal', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(error ?? 'El producto no existe o no está disponible'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                producto['imagen_url'],
                height: 300,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.network(
                  'https://via.placeholder.com/400',
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              producto['nombre'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${producto['precio']} COP',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Tallas disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tallasDisponibles.map((talla) {
                return ChoiceChip(
                  label: Text(talla['talla']),
                  selected: tallaSeleccionada?['id_talla'] == talla['id_talla'],
                  onSelected: (selected) {
                    setState(() {
                      tallaSeleccionada = selected ? talla : null;
                      if (selected) {
                        cantidad = 1;
                      }
                    });
                  },
                );
              }).toList(),
            ),

            if (tallasAgotadas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Tallas agotadas: ${tallasAgotadas.map((t) => t['talla']).join(', ')}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            const Text(
              'Cantidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      cantidad = cantidad > 1 ? cantidad - 1 : 1;
                    });
                  },
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    cantidad.toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: tallaSeleccionada == null
                      ? null
                      : () {
                          setState(() {
                            if (cantidad < tallaSeleccionada['stock']) {
                              cantidad++;
                            }
                          });
                        },
                ),
                if (tallaSeleccionada != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Stock: ${tallaSeleccionada['stock']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: addingToCart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.shopping_cart),
                label: addingToCart
                    ? const Text('Agregando...')
                    : const Text('Añadir al carrito'),
                onPressed: tallaSeleccionada == null || addingToCart ? null : handleAgregarAlCarrito,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              producto['descripcion'] ?? 'Este producto no tiene descripción.',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 32),

            const Text(
              'Opiniones de clientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deja tu review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < nuevaReview['calificacion']!
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              nuevaReview['calificacion'] = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu opinión sobre este producto...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          nuevaReview['comentario'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: enviarReview,
                        child: const Text('Enviar review'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (reviews.isEmpty)
              const Center(
                child: Text('Aún no hay reviews para este producto'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review['usuario']?['nombre'] ?? 'Anónimo',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              renderEstrellas(review['calificacion']),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review['comentario']),
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