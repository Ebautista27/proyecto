// detalle_producto_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DetalleProductoScreen extends StatefulWidget {
  final String idProducto;
  const DetalleProductoScreen({super.key, required this.idProducto});

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  Map<String, dynamic>? producto;
  List<dynamic> resenas = [];
  List<dynamic> tallasDisponibles = [];
  List<dynamic> tallasAgotadas = [];
  Map<String, dynamic>? tallaSeleccionada;
  int cantidad = 1;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String getImageUrl(String? imagenUrl) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      return 'https://via.placeholder.com/400';
    } else if (imagenUrl.contains("res.cloudinary.com")) {
      return imagenUrl;
    } else if (!imagenUrl.startsWith("http")) {
      return 'https://res.cloudinary.com/dodecmh9s/image/upload/$imagenUrl';
    }
    return imagenUrl;
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final resProducto = await http.get(Uri.parse('http://localhost:5000/productos/${widget.idProducto}'));
      final resResenas = await http.get(Uri.parse('http://localhost:5000/productos/${widget.idProducto}/reseñas'));
      final resTallas = await http.get(Uri.parse('http://localhost:5000/api/productos/${widget.idProducto}/tallas-disponibles'));

      if (resProducto.statusCode == 200 && resTallas.statusCode == 200) {
        final prodData = json.decode(resProducto.body);
        final tallas = json.decode(resTallas.body)['tallas'];
        final disponibles = tallas.where((t) => t['disponible']).toList();
        final agotadas = tallas.where((t) => !t['disponible']).toList();

        setState(() {
          producto = {
            ...prodData,
            'imagen_url': getImageUrl(prodData['imagen_url']),
            'precio': double.tryParse(prodData['precio'].toString()) ?? 0.0,
          };
          resenas = resResenas.statusCode == 200 ? json.decode(resResenas.body) : [];
          tallasDisponibles = disponibles;
          tallasAgotadas = agotadas;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Producto no encontrado o sin tallas disponibles";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "No se pudo cargar el producto";
        isLoading = false;
      });
    }
  }

 Future<void> agregarAlCarrito() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  // 🚨 Validación del token
  if (token == null) {
    print("❌ No hay token");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Debes iniciar sesión")),
    );
    return;
  }

  // 🚨 Validación de selección de talla
  if (tallaSeleccionada == null) {
    print("❌ No se ha seleccionado ninguna talla");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selecciona una talla primero")),
    );
    return;
  }

  // 🚨 Validación de stock
  if (cantidad > (tallaSeleccionada!['stock'] ?? 0)) {
    print("❌ Cantidad supera stock disponible");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Solo hay ${tallaSeleccionada!['stock']} unidades disponibles")),
    );
    return;
  }

  // 🧪 DEPURACIÓN AVANZADA
  print("🧪 BOTÓN PRESIONADO");
  print("🔍 Producto: $producto");
  print("🔍 Talla seleccionada: $tallaSeleccionada");

  final payload = {
    'id_producto': producto?['id'],
    'id_talla': tallaSeleccionada?['id_talla'], // ⚠️ Confirma el nombre real si es 'id' o algo distinto
    'cantidad': cantidad,
  };

  print("👉 Enviando a: /api/carritos/productos");
  print("📦 Body: $payload");
  print("🛡️ Token: $token");

  final res = await http.post(
    Uri.parse("http://localhost:5000/api/carritos/productos"),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(payload),
  );

  print("🔁 RESPONSE STATUS: ${res.statusCode}");
  print("🔁 RESPONSE BODY: ${res.body}");

  if (res.statusCode == 200 || res.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Producto añadido al carrito ✅")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al agregar al carrito ❌: ${res.body}")),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || producto == null) {
      return Scaffold(
        body: Center(
          child: Text(error ?? 'Producto no disponible'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(producto!['nombre'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(producto!['imagen_url']),
            const SizedBox(height: 10),
            Text('Precio: \$${producto!['precio'].toStringAsFixed(2)} COP',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              hint: const Text("Selecciona una talla"),
              value: tallaSeleccionada,
              onChanged: (value) {
                setState(() => tallaSeleccionada = value);
              },
              items: tallasDisponibles.map<DropdownMenuItem<Map<String, dynamic>>>((talla) {
                return DropdownMenuItem(
                  value: talla,
                  child: Text('${talla['talla']} - Stock: ${talla['stock']}'),
                );
              }).toList(),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => cantidad = cantidad > 1 ? cantidad - 1 : 1),
                  icon: const Icon(Icons.remove),
                ),
                Text('$cantidad'),
                IconButton(
                  onPressed: () => setState(() => cantidad += 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: agregarAlCarrito,
              child: const Text("Agregar al carrito"),
            ),
            const SizedBox(height: 20),
            const Text("Descripción", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(producto!['descripcion'] ?? "Sin descripción"),
            const SizedBox(height: 20),
            const Text("Opiniones de clientes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...resenas.map((r) => ListTile(
              title: Text(r['usuario']?['nombre'] ?? 'Anónimo'),
              subtitle: Text(r['comentario']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < (r['calificacion'] ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                )),
              ),
            ))
          ],
        ),
      ),
    );
  }
}
