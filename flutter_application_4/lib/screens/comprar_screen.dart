import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ComprarScreen extends StatefulWidget {
  @override
  _ComprarScreenState createState() => _ComprarScreenState();
}

class _ComprarScreenState extends State<ComprarScreen> {
  List<dynamic> metodosPago = [];
  String? metodoSeleccionado;
  String barrio = '';
  String observaciones = '';
  String error = '';
  String successMessage = '';
  bool isLoading = false;
  List<dynamic> carrito = [];
  bool isLoadingCarrito = true;
  String nombreUsuario = '';
  String? token;
  String? correoUsuario;
  String? usuarioActualId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      correoUsuario = prefs.getString('email_usuario');
      usuarioActualId = prefs.getString('id_usuario');
    });

    if (token != null) {
      await _fetchDatosUsuario();
      await _fetchMetodosPago();
    } else {
      setState(() {
        error = 'Debes iniciar sesión para realizar una compra';
        isLoadingCarrito = false;
      });
      _mostrarError();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _fetchDatosUsuario() async {
    try {
      final carritoResponse = await http.get(
        Uri.parse('http://localhost:5000/api/carritos/productos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final usuarioResponse = await http.get(
        Uri.parse('http://localhost:5000/usuarios/$usuarioActualId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (carritoResponse.statusCode == 200) {
        final carritoData = json.decode(carritoResponse.body);
        if (carritoData['carrito'] != null) {
          setState(() {
            carrito = (carritoData['carrito']['productos'] as List).map((item) {
              return {
                'id_producto': item['id_producto'],
                'id_talla': item['id_talla'],
                'talla': item['talla'],
                'nombre': item['nombre'],
                'precio_unitario': item['precio_unitario'],
                'cantidad': item['cantidad'],
                'imagen_url': item['imagen_url'],
              };
            }).toList();
            error = '';
          });
        } else {
          setState(() {
            carrito = [];
          });
        }
      }

      if (usuarioResponse.statusCode == 200) {
        final usuarioData = json.decode(usuarioResponse.body);
        setState(() {
          nombreUsuario = usuarioData['nombre'];
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error al cargar datos del usuario: $e';
        carrito = [];
      });
      _mostrarError();
    } finally {
      setState(() {
        isLoadingCarrito = false;
      });
    }
  }

  Future<void> _fetchMetodosPago() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/metodos_pago'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          metodosPago = json.decode(response.body);
          error = '';
        });
      } else {
        setState(() {
          error = 'No se pudieron cargar los métodos de pago';
        });
        _mostrarError();
      }
    } catch (e) {
      setState(() {
        error = 'Error al cargar métodos de pago: $e';
      });
      _mostrarError();
    }
  }

  void _mostrarError() {
    if (error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      error = '';
      successMessage = '';
      isLoading = true;
    });

    if (barrio.isEmpty || metodoSeleccionado == null || carrito.isEmpty) {
      setState(() {
        error = 'Por favor complete todos los campos requeridos y asegúrese de tener productos en el carrito';
        isLoading = false;
      });
      _mostrarError();
      return;
    }

    try {
      final productosCompra = carrito.map((item) => {
        'id_producto': item['id_producto'],
        'id_talla': item['id_talla'],
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio_unitario'],
      }).toList();

      final response = await http.post(
        Uri.parse('http://localhost:5000/Crearcompras'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'barrio': barrio,
          'observaciones': observaciones.isNotEmpty ? observaciones : null,
          'metodo_pago_id': int.parse(metodoSeleccionado!),
          'productos': productosCompra,
        }),
      );

      if (response.statusCode == 200) {
        final resultado = json.decode(response.body);
        _mostrarExito('¡Compra realizada con éxito!');

        if (correoUsuario != null) {
          try {
            final metodoPago = metodosPago.firstWhere(
              (m) => m['id'] == int.parse(metodoSeleccionado!),
              orElse: () => {'tipo': ''},
            )['tipo'] ?? '';

            final detalleProductos = carrito.map((item) =>
              '✔ ${item['nombre']} (Talla: ${item['talla']}) - ${item['cantidad']} x \$${item['precio_unitario']}'
            ).join('\n');

            await http.post(
              Uri.parse('http://localhost:5000/notificaciones'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'asunto': '¡Compra exitosa!',
                'mensaje': 'Detalles de tu compra:\n\n$detalleProductos\n\nTotal: \$${resultado['total']}',
                'destinatarios': [correoUsuario],
              }),
            );
          } catch (e) {
            print('Error al enviar notificación: $e');
          }
        }

        await http.delete(
          Uri.parse('http://localhost:5000/api/carritos/productos'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'producto_id': 'all'}),
        );

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushNamed(
            context,
            '/confirmacion',
            arguments: {
              'compraId': resultado['compra_id'],
              'total': resultado['total'],
            },
          );
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          error = errorData['mensaje'] ?? 'Error al procesar la compra';
        });
        _mostrarError();
      }
    } catch (e) {
      setState(() {
        error = 'Error al procesar compra: $e';
      });
      _mostrarError();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAuthErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error de autenticación'),
        content: Text('Tu sesión ha expirado. Serás redirigido al login.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  double _calcularTotal() {
    return carrito.fold(0, (total, item) => total + (item['precio_unitario'] * item['cantidad']));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingCarrito) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando tu carrito...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Finalizar Compra'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (carrito.isEmpty)
              Column(
                children: [
                  Text('No tienes productos en tu carrito'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/inicio'),
                    child: Text('Volver a la tienda'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de tu pedido',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...carrito.map((producto) => Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Image.network(
                            producto['imagen_url'] ?? 'https://via.placeholder.com/100',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Image.network('https://via.placeholder.com/100', width: 80, height: 80),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto['nombre'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text('Talla: ${producto['talla']}'),
                                SizedBox(height: 4),
                                Text('Cantidad: ${producto['cantidad']}'),
                                SizedBox(height: 4),
                                Text(
                                  '\$${(producto['precio_unitario'] * producto['cantidad']).toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                  
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${_calcularTotal().toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  Text(
                    'Información de Entrega',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Barrio *',
                      hintText: 'Ej: Chapinero, Usaquén, etc.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => barrio = value),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      hintText: 'Instrucciones especiales para la entrega',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => setState(() => observaciones = value),
                  ),
                  SizedBox(height: 24),
                  
                  Text(
                    'Método de Pago *',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  if (metodosPago.isEmpty)
                    Text('No hay métodos de pago disponibles')
                  else
                    Column(
                      children: metodosPago.map((metodo) => Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: metodoSeleccionado == metodo['id'].toString() 
                            ? Colors.blue[50] 
                            : null,
                        child: InkWell(
                          onTap: () => setState(() => metodoSeleccionado = metodo['id'].toString()),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Radio(
                                  value: metodo['id'].toString(),
                                  groupValue: metodoSeleccionado,
                                  onChanged: (value) => setState(() => metodoSeleccionado = value.toString()),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        metodo['tipo'],
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if (metodo['detalle'] != null)
                                        Text(metodo['detalle']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                      ),
                      onPressed: isLoading ? null : _handleSubmit,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'CONFIRMAR COMPRA',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}