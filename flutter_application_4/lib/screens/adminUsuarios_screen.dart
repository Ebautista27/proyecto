import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class AdminUsuariosScreen extends StatefulWidget {
  @override
  _AdminUsuariosState createState() => _AdminUsuariosState();
}

class _AdminUsuariosState extends State<AdminUsuariosScreen> {
  List usuarios = [];
  bool isLoading = true;
  String mensaje = "";
  String? token;
  int? editUserId;

  // Controladores
  TextEditingController nombreController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contrasenaController = TextEditingController();
  TextEditingController idRolController = TextEditingController();
  TextEditingController numCelController = TextEditingController();
  TextEditingController direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await obtenerToken();
    await fetchUsuarios();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> obtenerToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
    });
  }

  Future<void> fetchUsuarios() async {
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
        if (mounted) {
          setState(() {
            usuarios = json.decode(response.body);
            mensaje = "";
          });
        }
      } else {
        if (mounted) {
          setState(() => mensaje = "Error al cargar usuarios: ${response.statusCode}");
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => mensaje = "Error de conexión: $error");
      }
    }
  }

  Future<void> guardarUsuario() async {
    if (idRolController.text != "1" && idRolController.text != "2") {
      if (mounted) {
        setState(() => mensaje = "❌ El rol debe ser 1 (Usuario) o 2 (Administrador)");
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        mensaje = "";
      });
    }

    String url = editUserId == null 
        ? "http://127.0.0.1:5000/usuarios" 
        : "http://127.0.0.1:5000/usuarios/$editUserId";

    try {
      final response = await (editUserId == null
          ? http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode({
                "nombre": nombreController.text,
                "email": emailController.text,
                "contrasena": contrasenaController.text,
                "id_rol": int.parse(idRolController.text),
                "num_cel": numCelController.text,
                "direccion": direccionController.text,
              }),
            )
          : http.put(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode({
                "nombre": nombreController.text,
                "email": emailController.text,
                "id_rol": int.parse(idRolController.text),
                "num_cel": numCelController.text,
                "direccion": direccionController.text,
              }),
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            mensaje = editUserId == null ? "✅ Usuario creado" : "✅ Usuario actualizado";
            limpiarFormulario();
          });
        }
        await fetchUsuarios();
      } else {
        final errorData = json.decode(response.body);
        if (mounted) {
          setState(() => mensaje = "❌ Error: ${errorData['mensaje'] ?? response.body}");
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => mensaje = "Error: ${error.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void editarUsuario(Map usuario) {
    if (!mounted) return;
    setState(() {
      editUserId = usuario["id"];
      nombreController.text = usuario["nombre"];
      emailController.text = usuario["email"];
      idRolController.text = usuario["id_rol"].toString();
      numCelController.text = usuario["num_cel"] ?? '';
      direccionController.text = usuario["direccion"] ?? '';
    });
  }

  Future<void> eliminarUsuario(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmar"),
        content: Text("¿Estás seguro de eliminar este usuario?"),
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
        Uri.parse("http://127.0.0.1:5000/usuarios/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() => mensaje = "✅ Usuario eliminado");
        }
        await fetchUsuarios();
      } else {
        if (mounted) {
          setState(() => mensaje = "❌ Error al eliminar");
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => mensaje = "Error: $error");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void limpiarFormulario() {
    if (!mounted) return;
    setState(() {
      nombreController.clear();
      emailController.clear();
      contrasenaController.clear();
      idRolController.clear();
      numCelController.clear();
      direccionController.clear();
      editUserId = null;
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
              editUserId == null ? "Crear Usuario" : "Editar Usuario",
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
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            if (editUserId == null)
              TextField(
                controller: contrasenaController,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            if (editUserId == null) SizedBox(height: 12),
            TextField(
              controller: idRolController,
              decoration: InputDecoration(
                labelText: "Rol (1: Usuario, 2: Administrador)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: numCelController,
              decoration: InputDecoration(
                labelText: "Teléfono",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              controller: direccionController,
              decoration: InputDecoration(
                labelText: "Dirección",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isLoading ? null : guardarUsuario,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(editUserId == null ? "Crear" : "Actualizar"),
            ),
            if (editUserId != null) ...[
              SizedBox(height: 10),
              OutlinedButton(
                onPressed: limpiarFormulario,
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

  Widget _buildUsuarioItem(Map usuario) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          usuario["nombre"] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${usuario["email"] ?? 'Sin email'}"),
            Text("Rol: ${usuario["id_rol"] == 1 ? 'Usuario' : 'Administrador'}"),
            if (usuario["num_cel"] != null && usuario["num_cel"].toString().isNotEmpty)
              Text("Teléfono: ${usuario["num_cel"]}"),
            if (usuario["direccion"] != null && usuario["direccion"].toString().isNotEmpty)
              Text("Dirección: ${usuario["direccion"]}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => editarUsuario(usuario),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => eliminarUsuario(usuario["id"]),
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
        title: Text("Gestión de Usuarios"),
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
                    if (usuarios.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No hay usuarios disponibles"),
                      )
                    else
                      ...usuarios.map((usuario) => _buildUsuarioItem(usuario)).toList(),
                  ],
                ),
              ),
            ),
    );
  }
}