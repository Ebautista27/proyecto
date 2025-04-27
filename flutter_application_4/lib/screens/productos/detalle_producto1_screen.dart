import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class DetalleProducto1Screen extends StatefulWidget {
  final String id;
  final String nombre;
  final String precio ;
  final String descripcion;

  const DetalleProducto1Screen({
    super.key,
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
  });

  @override
  State<DetalleProducto1Screen> createState() => _DetalleProducto1ScreenState();
}

class _DetalleProducto1ScreenState extends State<DetalleProducto1Screen> {
  String _tallaSeleccionada = '';
  int _cantidad = 1;
  double _calificacionResena = 0;
  final TextEditingController _comentarioController = TextEditingController();
  bool _showZoom = false;
  Offset _zoomPosition = Offset.zero;

  final List<String> _tallas = ['XS', 'S', 'M', 'L', 'XL'];
  final List<Map<String, dynamic>> _resenas = [
    {
      'usuario': 'JuanP',
      'calificacion': 5,
      'comentario': '¡Increíble calidad!',
      'fecha': '10/05/2023',
    },
    {
      'usuario': 'AnaM',
      'calificacion': 4,
      'comentario': 'Buen producto, pero la talla viene grande',
      'fecha': '22/04/2023',
    },
  ];

  double _calcularPromedio() {
    if (_resenas.isEmpty) return 0;
    return _resenas
            .map((r) => r['calificacion'] as int)
            .reduce((a, b) => a + b) /
        _resenas.length;
  }

  @override
  Widget build(BuildContext context) {
    final promedio = _calcularPromedio();
    final totalResenas = _resenas.length;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E1DA),
      appBar: AppBar(
        title: Text(widget.nombre, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Sección de la imagen del producto
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTapDown: (details) => setState(() {
                      _showZoom = true;
                      _zoomPosition = details.localPosition;
                    }),
                    onTapUp: (_) => setState(() => _showZoom = false),
                    onPanUpdate: (details) =>
                        setState(() => _zoomPosition += details.delta),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Hero(
                          tag: 'producto-${widget.id}',
                          child: Image.asset(
                            'assets/imagenes/chaqueta_cargo_610.jpg', // Ruta específica de la imagen
                            height: 400,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (_showZoom)
                          Positioned(
                            left: _zoomPosition.dx - 50,
                            top: _zoomPosition.dy - 50,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                image: const DecorationImage(
                                  image: AssetImage('assets/imagenes/chaqueta_cargo_610.jpg'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Resto del código (información del producto, reseñas, etc.)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\$${widget.precio} COP',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Selector de tallas
                      const Text(
                        'Elige tu talla:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: _tallas.map((talla) => GestureDetector(
                          onTap: () => setState(() => _tallaSeleccionada = talla),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _tallaSeleccionada == talla ? Colors.black : const Color(0xFFA7A7A7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _tallaSeleccionada == talla ? Colors.black : const Color(0xFF615E5E),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                talla,
                                style: TextStyle(
                                  color: _tallaSeleccionada == talla ? Colors.white : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Selector de cantidad
                      Row(
                        children: [
                          const Text(
                            'Cantidad:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => setState(() => _cantidad = _cantidad > 1 ? _cantidad - 1 : 1),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Center(
                              child: Text(
                                '$_cantidad',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _cantidad++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botón añadir al carrito
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () {
                            if (_tallaSeleccionada.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Selecciona una talla'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            // Lógica para añadir al carrito
                          },
                          child: const Text(
                            'AÑADIR A LA CESTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Descripción
                      const Text(
                        'DESCRIPCIÓN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.descripcion,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección de reseñas
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFFF9F9F9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESEÑAS DEL PRODUCTO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Estadísticas de reseñas
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            promedio.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Muy bueno',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                '$totalResenas opiniones',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Distribución de estrellas
                      Column(
                        children: [5, 4, 3, 2, 1].map((stars) {
                          final count = _resenas.where((r) => r['calificacion'] == stars).length;
                          final percentage = totalResenas > 0 ? (count / totalResenas) * 100 : 0;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  '$stars estrellas',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$count',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),

                      // Formulario de reseña
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 5,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEJA TU RESEÑA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            RatingBar.builder(
                              initialRating: _calificacionResena,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemSize: 30,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                setState(() {
                                  _calificacionResena = rating;
                                });
                              },
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _comentarioController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Escribe tu reseña aquí...',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_calificacionResena == 0 || _comentarioController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Completa todos los campos'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _resenas.add({
                                      'usuario': 'Tú',
                                      'calificacion': _calificacionResena.round(),
                                      'comentario': _comentarioController.text,
                                      'fecha': 'Hoy',
                                    });
                                    _comentarioController.clear();
                                    _calificacionResena = 0;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'ENVIAR RESEÑA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Lista de reseñas
                      Column(
                        children: _resenas.map((review) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 5,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      review['usuario'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    RatingBarIndicator(
                                      rating: review['calificacion'].toDouble(),
                                      itemBuilder: (context, index) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 20,
                                      direction: Axis.horizontal,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  review['comentario'],
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  review['fecha'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}