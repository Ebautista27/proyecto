import 'dart:convert'; // Asegúrate de tener este import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminResenasScreen extends StatefulWidget {
  @override
  _AdminResenasScreenState createState() => _AdminResenasScreenState();
}

class _AdminResenasScreenState extends State<AdminResenasScreen> {
  List<dynamic> resenas = [];
  List<dynamic> productos = [];
  List<dynamic> usuarios = [];
  String mensaje = "";
  bool isLoading = true;

  Map<String, dynamic> formData = {
    "comentario": "",
    "calificacion": 5,
    "id_producto": "",
    "id_usuario": "",
  };

  Map<String, dynamic>? editData;
  TextEditingController _comentarioController = TextEditingController();
  TextEditingController _calificacionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadFormData(); // Añade esta línea
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _calificacionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([fetchResenas(), fetchProductos(), fetchUsuarios()]);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // Añade al inicio de la clase
  final String _formDataKey = 'reseña_form_data';

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formDataKey, json.encode(formData));
  }

  Future<void> _loadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_formDataKey);
    if (savedData != null && mounted) {
      setState(() {
        formData = Map<String, dynamic>.from(json.decode(savedData));
        _comentarioController.text = formData['comentario'] ?? '';
        _calificacionController.text =
            formData['calificacion']?.toString() ?? '5';
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchResenas() async {
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() => mensaje = "No autenticado");
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/reseñas"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            resenas = json.decode(response.body);
            mensaje = "";
          });
        }
      } else {
        if (mounted) {
          setState(
            () => mensaje = "Error al cargar reseñas: ${response.statusCode}",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => mensaje = "Error de conexión: $e");
      }
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

  Future<void> fetchUsuarios() async {
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() => mensaje = "❌ No autenticado");
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/usuarios"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Debug: Verifica los datos recibidos
        print("Usuarios recibidos: $data");

        if (mounted) {
          setState(() {
            usuarios = data;
            // Verifica que los usuarios tengan los campos correctos
            if (usuarios.isNotEmpty) {
              print("Primer usuario: ${usuarios.first}");
            }
          });
        }
      } else {
        if (mounted) {
          setState(
            () => mensaje = "Error al cargar usuarios: ${response.statusCode}",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => mensaje = "Error de conexión: $e");
      }
      print("Error en fetchUsuarios: $e");
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

    // Validación reforzada
    if (formData['comentario'].toString().trim().isEmpty) {
      if (mounted) {
        setState(() => mensaje = "❌ El comentario es obligatorio");
      }
      return;
    }

    if (formData['id_producto'].toString().isEmpty) {
      if (mounted) {
        setState(() => mensaje = "❌ Debes seleccionar un producto");
      }
      return;
    }

    if (formData['id_usuario'].toString().isEmpty) {
      if (mounted) {
        setState(() => mensaje = "❌ Debes seleccionar un usuario");
      }
      return;
    }

    final calificacion = int.tryParse(formData['calificacion'].toString()) ?? 0;
    if (calificacion < 1 || calificacion > 5) {
      if (mounted) {
        setState(() => mensaje = "❌ La calificación debe ser entre 1 y 5");
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
      // Obtener nombres para guardar localmente
      final productoSeleccionado = productos.firstWhere(
        (p) => p['id'].toString() == formData['id_producto'].toString(),
        orElse: () => {'nombre': 'Producto seleccionado'},
      );

      final usuarioSeleccionado = usuarios.firstWhere(
        (u) => u['id'].toString() == formData['id_usuario'].toString(),
        orElse: () => {'nombre': 'Usuario seleccionado'},
      );

      final url =
          editData != null
              ? "http://127.0.0.1:5000/reseñas/${editData!['id']}"
              : "http://127.0.0.1:5000/productos/${formData['id_producto']}/reseñas";

      final response =
          editData != null
              ? await http.put(
                Uri.parse(url),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token",
                },
                body: json.encode({
                  "comentario": formData['comentario'],
                  "calificacion": calificacion,
                  "id_usuario": formData['id_usuario'],
                }),
              )
              : await http.post(
                Uri.parse(url),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token",
                },
                body: json.encode({
                  "comentario": formData['comentario'],
                  "calificacion": calificacion,
                  "id_usuario": formData['id_usuario'],
                }),
              );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Crear objeto completo para mostrar
        final nuevaResena = {
          'id': editData != null ? editData!['id'] : responseData['id'],
          'comentario': formData['comentario'],
          'calificacion': calificacion,
          'producto': {
            'id': formData['id_producto'],
            'nombre': productoSeleccionado['nombre'],
          },
          'usuario': {
            'id': formData['id_usuario'],
            'nombre': usuarioSeleccionado['nombre'],
          },
        };

        // Guardar datos localmente
        await _saveFormData();

        if (mounted) {
          setState(() {
            mensaje =
                editData != null ? "✅ Reseña actualizada" : "✅ Reseña creada";
            if (editData != null) {
              // Actualizar existente
              final index = resenas.indexWhere(
                (r) => r['id'] == editData!['id'],
              );
              if (index != -1) resenas[index] = nuevaResena;
            } else {
              // Agregar nueva
              resenas.insert(0, nuevaResena);
            }
            _resetForm();
          });
        }
      } else {
        final errorData = json.decode(response.body);
        if (mounted) {
          setState(
            () => mensaje = "❌ Error: ${errorData['mensaje'] ?? response.body}",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => mensaje = "Error: ${e.toString()}");
      }
      print("Error en handleSubmit: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> handleDelete(int id) async {
    final token = await _getToken();
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Confirmar"),
            content: Text("¿Estás seguro de eliminar esta reseña?"),
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
      final response = await http.delete(
        Uri.parse("http://127.0.0.1:5000/reseñas/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() => mensaje = "✅ Reseña eliminada");
        }
        await fetchResenas();
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

  void handleEdit(Map<String, dynamic> resena) {
    if (!mounted) return;

    setState(() {
      editData = resena;
      formData = {
        "comentario": resena['comentario']?.toString() ?? '',
        "calificacion": resena['calificacion'] ?? 5,
        "id_producto": resena['id_producto']?.toString() ?? '',
        "id_usuario": resena['id_usuario']?.toString() ?? '',
      };
      _comentarioController.text = formData['comentario'];
      _calificacionController.text = formData['calificacion'].toString();
    });
  }

  void _resetForm() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_formDataKey); // Añade esta línea

    setState(() {
      editData = null;
      formData = {
        "comentario": "",
        "calificacion": 5,
        "id_producto": "",
        "id_usuario": "",
      };
      _comentarioController.clear();
      _calificacionController.text = '5';
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
              editData != null ? "Editar Reseña" : "Crear Reseña",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _comentarioController,
              decoration: InputDecoration(
                labelText: "Comentario",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (v) => formData['comentario'] = v,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _calificacionController,
              decoration: InputDecoration(
                labelText: "Calificación (1-5)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => formData['calificacion'] = v,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField(
              value:
                  formData['id_producto']?.toString().isEmpty ?? true
                      ? null
                      : formData['id_producto'].toString(),
              decoration: InputDecoration(
                labelText: "Producto",
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  child: Text("Seleccione producto"),
                  value: null,
                ),
                ...productos.map((producto) {
                  return DropdownMenuItem(
                    value: producto['id'].toString(),
                    child: Text(producto['nombre'] ?? 'Sin nombre'),
                  );
                }).toList(),
              ],
              onChanged:
                  editData == null
                      ? (v) {
                        if (mounted) {
                          setState(() => formData['id_producto'] = v);
                        }
                      }
                      : null,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value:
                  formData['id_usuario']?.toString().isEmpty ?? true
                      ? null
                      : formData['id_usuario'].toString(),
              decoration: InputDecoration(
                labelText: "Usuario*",
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  child: Text("Seleccione usuario"),
                  value: null,
                ),
                ...usuarios
                    .where(
                      (u) => u is Map && u['id'] != null && u['nombre'] != null,
                    )
                    .map((usuario) {
                      return DropdownMenuItem<String>(
                        value: usuario['id'].toString(),
                        child: Text(usuario['nombre'].toString()),
                      );
                    })
                    .toList(),
              ],
              onChanged: (String? newValue) {
                if (mounted) {
                  setState(() {
                    formData['id_usuario'] = newValue;
                  });
                }
              },
              validator:
                  (value) => value == null ? 'Seleccione un usuario' : null,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isLoading ? null : handleSubmit,
              child:
                  isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(editData != null ? "Actualizar" : "Crear"),
            ),
            if (editData != null) ...[
              SizedBox(height: 10),
              OutlinedButton(onPressed: _resetForm, child: Text("Cancelar")),
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

  Widget _buildResenaItem(dynamic item) {
    try {
      // 1. Conversión segura del item a Map<String, dynamic>
      final Map<String, dynamic> resena =
          (item is Map) ? Map<String, dynamic>.from(item) : <String, dynamic>{};

      // 2. Extracción segura de datos del producto
      final Map<String, dynamic> productoData =
          (resena['producto'] is Map)
              ? Map<String, dynamic>.from(resena['producto'])
              : <String, dynamic>{};

      // 3. Extracción segura de datos del usuario
      final Map<String, dynamic> usuarioData =
          (resena['usuario'] is Map)
              ? Map<String, dynamic>.from(resena['usuario'])
              : <String, dynamic>{};

      // 4. Obtener nombres con múltiples fallbacks
      String getProductoNombre() {
        // Primero intenta con los datos directos de la reseña
        if (productoData['nombre'] != null)
          return productoData['nombre'].toString();

        // Si no hay, busca en la lista de productos
        try {
          final producto = productos.firstWhere(
            (p) => p['id']?.toString() == resena['id_producto']?.toString(),
            orElse: () => null,
          );
          if (producto != null && producto['nombre'] != null) {
            return producto['nombre'].toString();
          }
        } catch (e) {
          print('Error buscando producto: $e');
        }

        // Último fallback
        return 'Desconocido';
      }

      String getUsuarioNombre() {
        // Primero intenta con los datos directos de la reseña
        if (usuarioData['nombre'] != null)
          return usuarioData['nombre'].toString();

        // Si no hay, busca en la lista de usuarios
        try {
          final usuario = usuarios.firstWhere(
            (u) => u['id']?.toString() == resena['id_usuario']?.toString(),
            orElse: () => null,
          );
          if (usuario != null && usuario['nombre'] != null) {
            return usuario['nombre'].toString();
          }
        } catch (e) {
          print('Error buscando usuario: $e');
        }

        // Último fallback
        return 'Desconocido';
      }

      // 5. Validación de ID para acciones
      final bool tieneIdValido =
          resena['id'] != null && resena['id'].toString().isNotEmpty;

      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(
            "Usuario: ${getUsuarioNombre()}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Producto: ${getProductoNombre()}"),
              Text(
                "⭐ Calificación: ${resena['calificacion']?.toString() ?? '0'}",
              ),
              SizedBox(height: 4),
              Text(
                resena['comentario']?.toString() ?? 'Sin comentario',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          trailing:
              tieneIdValido
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar reseña',
                        onPressed:
                            () => handleEdit({
                              'id': resena['id'],
                              'comentario': resena['comentario'],
                              'calificacion': resena['calificacion'],
                              'id_producto':
                                  productoData['id'] ?? resena['id_producto'],
                              'id_usuario':
                                  usuarioData['id'] ?? resena['id_usuario'],
                              'producto': productoData,
                              'usuario': usuarioData,
                            }),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Eliminar reseña',
                        onPressed: () => handleDelete(resena['id']),
                      ),
                    ],
                  )
                  : null,
        ),
      );
    } catch (e) {
      print('Error construyendo ítem de reseña: $e');
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text("Error mostrando reseña"),
          subtitle: Text("Por favor, recarga la página"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestión de Reseñas"),
        backgroundColor: Color(0xFFE5E1DA),
      ),
      backgroundColor: Color(0xFFE5E1DA),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildForm(),
                      SizedBox(height: 16),
                      if (resenas.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("No hay reseñas disponibles"),
                        )
                      else
                        ...resenas
                            .map((resena) => _buildResenaItem(resena))
                            .toList(),
                    ],
                  ),
                ),
              ),
    );
  }
}
