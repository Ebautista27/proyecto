import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminComprasScreen extends StatefulWidget {
  @override
  _AdminComprasScreenState createState() => _AdminComprasScreenState();
}

class _AdminComprasScreenState extends State<AdminComprasScreen> {
  List<dynamic> compras = [];
  List<dynamic> metodosPago = [];
  List<dynamic> usuarios = [];
  List<dynamic> productos = [];
  String mensaje = "";
  bool isLoading = true;

  final List<String> estadosCompra = [
    "Procesado",
    "Enviado",
    "Entregado",
    "Cancelado",
  ];

  Map<String, dynamic> formData = {
    "barrio": "",
    "observaciones": "",
    "usuario_id": "",
    "metodo_pago_id": "",
    "estado_pedido": "Procesado",
    "productos": [], // Lista de productos con cantidad y precio
  };

  Map<String, dynamic>? editData;
  TextEditingController _barrioController = TextEditingController();
  TextEditingController _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _barrioController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchCompras(),
      fetchMetodosPago(),
      fetchUsuarios(),
      fetchProductos()
    ]);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchCompras() async {
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() => mensaje = "❌ No autenticado");
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/compras/todas"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            compras = json.decode(response.body);
            mensaje = "";
          });
        }
      } else {
        if (mounted) {
          setState(() => mensaje = "Error al cargar compras: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => mensaje = "Error de conexión: $e");
      }
    }
  }

  Future<void> fetchMetodosPago() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/metodos_pago"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() => metodosPago = json.decode(response.body));
      }
    } catch (e) {
      print("Error fetching métodos pago: $e");
    }
  }

  Future<void> fetchUsuarios() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/usuarios"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() => usuarios = json.decode(response.body));
      }
    } catch (e) {
      print("Error fetching usuarios: $e");
    }
  }

  Future<void> fetchProductos() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/productos"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() => productos = json.decode(response.body));
      }
    } catch (e) {
      print("Error fetching productos: $e");
    }
  }

  Future<void> handleSubmit() async {
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() => mensaje = "❌ No autenticado");
      }
      return;
    }

    // Validación de campos requeridos
    if (formData['barrio'].isEmpty || 
        formData['usuario_id'].isEmpty || 
        formData['metodo_pago_id'].isEmpty) {
      if (mounted) {
        setState(() => mensaje = "❌ Barrio, usuario y método de pago son obligatorios");
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        mensaje = "";
      });
    }

    try {
      final url = editData != null
          ? "http://127.0.0.1:5000/compras/${editData!['id']}"
          : "http://127.0.0.1:5000/Crearcompras";

      final response = editData != null
          ? await http.put(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: json.encode(formData),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: json.encode(formData),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            mensaje = editData != null ? "✅ Compra actualizada" : "✅ Compra creada";
            _resetForm();
          });
        }
        await fetchCompras();
      } else {
        final errorData = json.decode(response.body);
        if (mounted) {
          setState(() => mensaje = "❌ Error: ${errorData['mensaje'] ?? response.body}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => mensaje = "Error: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> handleDelete(int id) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Confirmar"),
      content: Text("¿Estás seguro de eliminar esta compra?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Eliminar", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  if (mounted) {
    setState(() {
      isLoading = true;
      mensaje = "";
    });
  }

  try {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("http://127.0.0.1:5000/compras/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    // Cambiamos la condición para aceptar tanto 200 como 204
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (mounted) {
        setState(() {
          compras.removeWhere((compra) => compra['id'] == id);
          mensaje = "✅ Compra eliminada";
        });
      }
    } else {
      if (mounted) {
        setState(() => mensaje = "❌ Error al eliminar: ${response.statusCode}");
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => mensaje = "Error: $e");
    }
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  void handleEdit(Map<String, dynamic> compra) {
    if (!mounted) return;
    setState(() {
      editData = compra;
      formData = {
        "barrio": compra['barrio'] ?? '',
        "observaciones": compra['observaciones'] ?? '',
        "usuario_id": compra['usuario_id']?.toString() ?? '',
        "metodo_pago_id": compra['metodo_pago_id']?.toString() ?? '',
        "estado_pedido": compra['estado_pedido'] ?? 'Procesado',
      };
      _barrioController.text = formData['barrio'];
      _observacionesController.text = formData['observaciones'];
    });
  }

  void _resetForm() {
    if (!mounted) return;
    setState(() {
      editData = null;
      formData = {
        "barrio": "",
        "observaciones": "",
        "usuario_id": "",
        "metodo_pago_id": "",
        "estado_pedido": "Procesado",
      };
      _barrioController.clear();
      _observacionesController.clear();
    });
  }

  Widget _buildForm() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editData != null ? "Editar Compra" : "Crear Compra",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _barrioController,
              decoration: InputDecoration(
                labelText: "Barrio",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => formData['barrio'] = v,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _observacionesController,
              decoration: InputDecoration(
                labelText: "Observaciones (opcional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (v) => formData['observaciones'] = v,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: formData['estado_pedido'],
              decoration: InputDecoration(
                labelText: "Estado de la compra",
                border: OutlineInputBorder(),
              ),
              items: estadosCompra.map((estado) {
                return DropdownMenuItem<String>(
                  value: estado,
                  child: Text(estado),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null && mounted) {
                  setState(() => formData['estado_pedido'] = v);
                }
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField(
              value: formData['metodo_pago_id']?.toString().isEmpty ?? true
                  ? null
                  : formData['metodo_pago_id'].toString(),
              decoration: InputDecoration(
                labelText: "Método de Pago",
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  child: Text("Seleccione método"),
                  value: null,
                ),
                ...metodosPago.map((metodo) {
                  return DropdownMenuItem(
                    value: metodo['id'].toString(),
                    child: Text("${metodo['id']} - ${metodo['tipo']}"),
                  );
                }).toList(),
              ],
              onChanged: (v) {
                if (mounted) {
                  setState(() => formData['metodo_pago_id'] = v);
                }
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField(
              value: formData['usuario_id']?.toString().isEmpty ?? true
                  ? null
                  : formData['usuario_id'].toString(),
              decoration: InputDecoration(
                labelText: "Usuario",
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  child: Text("Seleccione usuario"),
                  value: null,
                ),
                ...usuarios.map((user) {
                  return DropdownMenuItem(
                    value: user['id'].toString(),
                    child: Text("${user['id']} - ${user['nombre']} ${user['apellido'] ?? ''}"),
                  );
                }).toList(),
              ],
              onChanged: (v) {
                if (mounted) {
                  setState(() => formData['usuario_id'] = v);
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isLoading ? null : handleSubmit,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(editData != null ? "Actualizar" : "Crear"),
            ),
            if (editData != null) ...[
              SizedBox(height: 10),
              OutlinedButton(
                onPressed: _resetForm,
                child: Text("Cancelar"),
              ),
            ],
            if (mensaje.isNotEmpty) ...[
              SizedBox(height: 10),
              Text(
                mensaje,
                style: TextStyle(
                  color: mensaje.contains("✅") ? Colors.green : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompraItem(dynamic compra) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text("Compra #${compra['id']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Barrio: ${compra['barrio'] ?? 'No especificado'}"),
            Text("Estado: ${compra['estado_pedido'] ?? 'Desconocido'}"),
            if (compra['observaciones'] != null && compra['observaciones'].isNotEmpty)
              Text(
                "Observaciones: ${compra['observaciones']}",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            Text("Usuario ID: ${compra['usuario_id']}"),
            Text("Método Pago ID: ${compra['metodo_pago_id']}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => handleEdit(compra),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => handleDelete(compra['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestión de Compras"),
        backgroundColor: Color(0xFFE5E1DA),
      ),
      backgroundColor: Color(0xFFE5E1DA),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildForm(),
                    SizedBox(height: 16),
                    if (compras.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No hay compras disponibles"),
                      )
                    else
                      ...compras.map((compra) => _buildCompraItem(compra)).toList(),
                  ],
                ),
              ),
            ),
    );
  }
}