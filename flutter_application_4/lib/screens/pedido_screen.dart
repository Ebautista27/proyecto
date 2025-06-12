import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PedidoScreen extends StatefulWidget {
  @override
  _PedidoScreenState createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  List<dynamic> pedidos = [];
  bool loading = true;
  String? error;
  String? expandedPedido;
  
  // Mapeo de estados
  final Map<String, Map<String, dynamic>> estadoConfig = {
    'pendiente': {
      'texto': 'Pendiente de confirmación',
      'icono': '⏳',
      'color': Color(0xFFFFC107),
      'bgColor': Color(0xFFFFF3CD),
    },
    'confirmado': {
      'texto': 'Pedido confirmado',
      'icono': '✅',
      'color': Color(0xFF17A2B8),
      'bgColor': Color(0xFFD1ECF1),
    },
    'preparando': {
      'texto': 'En preparación',
      'icono': '👨‍🍳',
      'color': Color(0xFF007BFF),
      'bgColor': Color(0xFFCCE5FF),
    },
    'enviado': {
      'texto': 'En camino',
      'icono': '🚚',
      'color': Color(0xFF28A745),
      'bgColor': Color(0xFFD4EDDA),
    },
    'entregado': {
      'texto': 'Entregado',
      'icono': '📦',
      'color': Color(0xFF6C757D),
      'bgColor': Color(0xFFE2E3E5),
    },
    'cancelado': {
      'texto': 'Cancelado',
      'icono': '❌',
      'color': Color(0xFFDC3545),
      'bgColor': Color(0xFFF8D7DA),
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchPedidos();
  }

  Future<void> _fetchPedidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/mis-compras'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al obtener los pedidos');
      }

      final data = json.decode(response.body);
      setState(() {
        pedidos = data['compras'] ?? [];
        loading = false;
      });
    } catch (err) {
      setState(() {
        error = err.toString();
        loading = false;
      });
    }
  }

  String _formatFecha(String fecha) {
    final date = DateTime.parse(fecha);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calcularTiempoEstimado(String estado, String fecha) {
    final fechaPedido = DateTime.parse(fecha);
    final ahora = DateTime.now();
    final diffHoras = ahora.difference(fechaPedido).inHours.toDouble();
    
    switch (estado) {
      case 'pendiente': return 'Confirmación pendiente';
      case 'confirmado': return 'En preparación (${diffHoras.floor()}h)';
      case 'preparando': return 'Listo para envío en ~${24 - diffHoras.floor()}h';
      case 'enviado': return 'Entrega estimada: ${fechaPedido.add(Duration(days: 2)).day}/${fechaPedido.add(Duration(days: 2)).month}';
      case 'entregado': return 'Entregado el ${_formatFecha(fecha)}';
      case 'cancelado': return 'Pedido cancelado';
      default: return 'Tiempo estimado no disponible';
    }
  }

  void _toggleExpandPedido(String id) {
    setState(() {
      expandedPedido = expandedPedido == id ? null : id;
    });
  }

  Widget _buildProgressBar(Map<String, dynamic> pedido) {
    final estado = pedido['estado'].toString().toLowerCase();
    return Column(
      children: [
        SizedBox(height: 30),
        Stack(
          children: [
            Container(
              height: 4,
              color: Colors.grey[300],
              margin: EdgeInsets.only(top: 15, left: 20, right: 20),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressStep(1, 'Confirmado', 
                    ['confirmado', 'preparando', 'enviado', 'entregado'].contains(estado)),
                _buildProgressStep(2, 'Preparando', 
                    ['preparando', 'enviado', 'entregado'].contains(estado)),
                _buildProgressStep(3, 'Enviado', 
                    ['enviado', 'entregado'].contains(estado)),
                _buildProgressStep(4, 'Entregado', 
                    estado == 'entregado'),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          '⏱️ ${_calcularTiempoEstimado(estado, pedido['fecha'])}',
          style: TextStyle(color: Colors.blue),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProgressStep(int step, String text, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Cargando tus pedidos...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(error!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchPedidos,
              child: Text('Intentar de nuevo'),
            ),
          ],
        ),
      );
    }

    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No tienes pedidos realizados', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Cuando hagas un pedido, aparecerá aquí con su estado actual.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/'),
              child: Text('Explorar productos'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Seguimiento de tus Pedidos'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revisa el estado de tus compras y los detalles de envío',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                final estado = pedido['estado'].toString().toLowerCase();
                final config = estadoConfig[estado] ?? {};
                
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Pedido #${pedido['id']}'),
                        subtitle: Text(_formatFecha(pedido['fecha'])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: config['bgColor'],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(config['icono'] ?? '📦'),
                                  SizedBox(width: 5),
                                  Text(config['texto'] ?? pedido['estado']),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '\$${pedido['total'].toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(expandedPedido == pedido['id'] 
                                  ? Icons.expand_less 
                                  : Icons.expand_more),
                              onPressed: () => _toggleExpandPedido(pedido['id']),
                            ),
                          ],
                        ),
                      ),
                      if (expandedPedido == pedido['id']) ...[
                        Divider(),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildProgressBar(pedido),
                              _buildShippingInfo(pedido),
                              SizedBox(height: 20),
                              Text('🛒 Productos en este pedido', 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ..._buildProductList(pedido['productos']),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo(Map<String, dynamic> pedido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📦 Información de envío', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text('Dirección: ${pedido['barrio'] ?? 'No especificado'}'),
        if (pedido['observaciones'] != null) 
          Text('Instrucciones: ${pedido['observaciones']}'),
        Text('Método de pago: ${pedido['metodo_pago'] ?? 'No especificado'}'),
        SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildProductList(List<dynamic> productos) {
    return productos.map<Widget>((producto) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                producto['imagen'] ?? 'https://via.placeholder.com/70',
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/product-placeholder.jpg',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto['nombre'], 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Talla: ${producto['talla']}'),
                      SizedBox(width: 16),
                      Text('Cantidad: ${producto['cantidad']}'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${producto['precio'].toStringAsFixed(2)} c/u'),
                SizedBox(height: 4),
                Text(
                  'Subtotal: \$${producto['subtotal'].toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}