// carrito_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  List<dynamic> productos = [];
  bool isLoading = true;
  String? error;
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    obtenerCarrito();
  }

  Future<void> obtenerCarrito() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("http://localhost:5000/api/carritos"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        productos = data['productos'];
        total = (data['total'] as num?)?.toDouble() ?? 0;
        isLoading = false;
      });
    } else {
      setState(() {
        error = "Error al cargar el carrito";
        isLoading = false;
      });
    }
  }

  Future<void> eliminarProducto(int idProducto, int idTalla) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.delete(
      Uri.parse("http://localhost:5000/api/carritos/productos"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "id_producto": idProducto,
        "id_talla": idTalla,
      }),
    );

    if (res.statusCode == 200) {
      obtenerCarrito();
    }
  }

  Future<void> vaciarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.delete(
      Uri.parse("http://localhost:5000/api/carritos/vaciar"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      obtenerCarrito();
    }
  }

  Future<void> actualizarCantidad(int idProducto, int idTalla, int cantidad) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.put(
      Uri.parse("http://localhost:5000/api/carritos/productos"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "id_producto": idProducto,
        "id_talla": idTalla,
        "cantidad": cantidad,
      }),
    );

    if (res.statusCode == 200) {
      obtenerCarrito();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              ElevatedButton(
                onPressed: obtenerCarrito,
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Carrito de Compras")),
      body: Column(
        children: [
          Expanded(
            child: productos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No hay productos en el carrito"),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed("/");
                          },
                          child: const Text("Seguir comprando"),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      return ListTile(
                        leading: Image.network(producto['imagen_url'] ?? 'https://placehold.co/300x300?text=Imagen+no+disponible'),
                        title: Text(producto['nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Talla: ${producto['talla']}",),
                            Text("Cantidad: ${producto['cantidad']}",),
                            Text("Subtotal: \$${producto['subtotal']}",),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => eliminarProducto(producto['id_producto'], producto['id_talla']),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Total: \$${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: vaciarCarrito,
                      child: const Text("Vaciar carrito"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed("/comprar"),
                      child: const Text("Proceder al pago"),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
