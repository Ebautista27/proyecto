import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class HistorialComprasScreen extends StatefulWidget {
  const HistorialComprasScreen({Key? key}) : super(key: key);

  @override
  _HistorialComprasScreenState createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  final _storage = const FlutterSecureStorage();
  
  List<dynamic> compras = [];
  bool loading = true;
  String? error;
  String? expandedCompraId;

  @override
  void initState() {
    super.initState();
    _fetchCompras();
  }

  Future<void> _fetchCompras() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      Get.offAllNamed('/login');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/mis-compras'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          compras = data['compras'] ?? [];
        });
      } else {
        throw Exception('Error al obtener el historial');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _toggleExpandCompra(String id) {
    setState(() {
      expandedCompraId = expandedCompraId == id ? null : id;
    });
  }

  String _formatFecha(String fecha) {
    try {
      return DateFormat('d MMMM y HH:mm', 'es_ES').format(DateTime.parse(fecha));
    } catch (e) {
      return fecha;
    }
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
              SizedBox(height: 20),
              Text('Cargando tu historial de compras...'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(error!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchCompras,
                child: const Text('Intentar de nuevo'),
              ),
            ],
          ),
        ),
      );
    }

    if (compras.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Aún no has realizado compras',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuando hagas una compra, aparecerá aquí.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.offAllNamed('/'),
                child: const Text('Explorar productos'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial de Compras'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ...compras.map((compra) => _buildCompraCard(compra)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompraCard(Map<String, dynamic> compra) {
    final isExpanded = expandedCompraId == compra['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Encabezado de la compra
          InkWell(
            onTap: () => _toggleExpandCompra(compra['id']),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: Radius.circular(isExpanded ? 0 : 10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Productos Comprados',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatFecha(compra['fecha']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '\$${compra['total'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Detalles expandidos
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de pago
                  const Text(
                    'Información de pago',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Método de pago: ${compra['metodo_pago'] ?? 'No especificado'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Barrio: ${compra['barrio'] ?? 'No especificado'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (compra['observaciones'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Observaciones: ${compra['observaciones']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Lista de productos
                  const Text(
                    'Productos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildProductosList(compra['productos'] ?? []),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildProductosList(List<dynamic> productos) {
    return productos.map<Widget>((producto) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                producto['imagen'] ?? 'https://via.placeholder.com/100',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 16),
            
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Talla: ${producto['talla'] ?? ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Cantidad: ${producto['cantidad'] ?? ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // Precio
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${producto['precio']?.toStringAsFixed(2) ?? '0.00'} c/u',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: \$${producto['subtotal']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}