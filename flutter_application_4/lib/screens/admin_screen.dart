import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String nombre = '';
  String email = '';
  String? foto;
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    verificarSuperAdmin();
  }

  Future<void> verificarSuperAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      setState(() => mensaje = "No tienes acceso. Inicia sesión.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));

    if (payload["email"] != "superadmin@example.com") {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://localhost:5000/superadmin'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          nombre = data['nombre'];
          email = data['email'];
          foto = data['foto'];
        });
      } else {
        setState(() => mensaje = "Error al cargar los datos del administrador.");
      }
    } catch (e) {
      setState(() => mensaje = "Error inesperado: $e");
    }
  }

  void navegarA(String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administrador"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (mensaje.isNotEmpty) Text(mensaje, style: const TextStyle(color: Colors.red)),

            CircleAvatar(
              radius: 60,
              backgroundImage: foto != null ? NetworkImage(foto!) : null,
              child: foto == null ? const Icon(Icons.person, size: 60) : null,
            ),
            const SizedBox(height: 10),
            Text("Bienvenido, $nombre", style: const TextStyle(fontSize: 20)),
            Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  botonGestion("Gestión de Usuarios", '/admin/usuarios'),
                  botonGestion("Gestión de Productos", '/admin/productos'),
                  botonGestion("Gestión de Pedidos", '/admin/pedidos'),
                  botonGestion("Gestión de Reseñas", '/admin/resenas'),
                  botonGestion("Gestión de Stock", '/admin/stock'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget botonGestion(String titulo, String ruta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () => navegarA(ruta),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFFB17457),
        ),
        child: Text(titulo, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
