import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProductosScreen extends StatefulWidget {
  @override
  _AdminProductosScreenState createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  List<dynamic> productos = [];
  bool isLoading = true;
  String mensaje = "";
  String estado = "Disponible";
  int? editProductoId;

  // Controladores
  TextEditingController nombreController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  TextEditingController precioController = TextEditingController();
  TextEditingController idCategoriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await fetchProductos();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> fetchProductos() async {
    String? token = await getToken();
    if (token == null) {
      if (mounted) {
        setState(() => mensaje = "❌ No autenticado");
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/productos"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            productos = json.decode(response.body);
            mensaje = "";
          });
        }
      } else {
        if (mounted) {
          setState(() => mensaje = "Error al cargar productos: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => mensaje = "Error de conexión: $e");
      }
    }
  }

  Future<void> guardarProducto() async {
    if (nombreController.text.isEmpty ||
        descripcionController.text.isEmpty ||
        precioController.text.isEmpty ||
        idCategoriaController.text.isEmpty) {
      if (mounted) {
        setState(() => mensaje = "❌ Todos los campos son obligatorios");
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        mensaje = "";
      });
    }

    String? token = await getToken();
    String url = editProductoId == null
        ? "http://127.0.0.1:5000/productos/nuevo"
        : "http://127.0.0.1:5000/productos/$editProductoId";

    try {
      final response = await (editProductoId == null
          ? http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: json.encode({
                "nombre": nombreController.text,
                "descripcion": descripcionController.text,
                "precio": precioController.text,
                "estado": estado,
                "id_categoria": idCategoriaController.text,
              }),
            )
          : http.put(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: json.encode({
                "nombre": nombreController.text,
                "descripcion": descripcionController.text,
                "precio": precioController.text,
                "estado": estado,
                "id_categoria": idCategoriaController.text,
              }),
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            mensaje = editProductoId == null ? "✅ Producto creado" : "✅ Producto actualizado";
            _resetForm();
          });
        }
        await fetchProductos();
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

  void editarProducto(Map<String, dynamic> producto) {
    if (!mounted) return;
    setState(() {
      editProductoId = producto['id'];
      nombreController.text = producto['nombre'];
      descripcionController.text = producto['descripcion'];
      precioController.text = producto['precio'].toString();
      estado = producto['estado'];
      idCategoriaController.text = producto['id_categoria'].toString();
    });
  }

  Future<void> eliminarProducto(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmar"),
        content: Text("¿Estás seguro de eliminar este producto?"),
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
      setState(() => isLoading = true);
    }

    try {
      String? token = await getToken();
      final response = await http.delete(
        Uri.parse("http://127.0.0.1:5000/productos/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() => mensaje = "✅ Producto eliminado");
        }
        await fetchProductos();
      } else {
        if (mounted) {
          setState(() => mensaje = "❌ Error al eliminar");
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

  void _resetForm() {
    if (!mounted) return;
    setState(() {
      nombreController.clear();
      descripcionController.clear();
      precioController.clear();
      idCategoriaController.clear();
      estado = "Disponible";
      editProductoId = null;
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
              editProductoId == null ? "Crear Producto" : "Editar Producto",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              decoration: InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            TextField(
              controller: precioController,
              decoration: InputDecoration(
                labelText: "Precio",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: estado,
              decoration: InputDecoration(
                labelText: "Estado",
                border: OutlineInputBorder(),
              ),
              items: ["Disponible", "No Disponible"]
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null && mounted) {
                  setState(() => estado = newValue);
                }
              },
            ),
            SizedBox(height: 12),
            TextField(
              controller: idCategoriaController,
              decoration: InputDecoration(
                labelText: "ID Categoría",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isLoading ? null : guardarProducto,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(editProductoId == null ? "Crear" : "Actualizar"),
            ),
            if (editProductoId != null) ...[
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

  Widget _buildProductoItem(dynamic producto) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          producto['nombre'] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Precio: \$${producto['precio']?.toString() ?? '0'}"),
            Text("Estado: ${producto['estado'] ?? 'Desconocido'}"),
            SizedBox(height: 4),
            Text(
              producto['descripcion']?.toString() ?? 'Sin descripción',
              style: TextStyle(fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => editarProducto(producto),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => eliminarProducto(producto['id']),
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
        title: Text("Gestión de Productos"),
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
                    if (productos.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No hay productos disponibles"),
                      )
                    else
                      ...productos
                          .map((producto) => _buildProductoItem(producto))
                          .toList(),
                  ],
                ),
              ),
            ),
    );
  }
}