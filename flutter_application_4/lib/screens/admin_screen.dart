import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../routes/app_routes.dart';

class AdministradorScreen extends StatefulWidget {
  @override
  _AdministradorScreenState createState() => _AdministradorScreenState();
}

class _AdministradorScreenState extends State<AdministradorScreen> {
  String nombre = "Administrador";
  String email = "";
  String mensaje = "";
  File? _image;
  bool _isLoading = true;
  String? _imagePath; // Para manejar la ruta en web

  @override
  void initState() {
    super.initState();
    verificarAdmin();
  }

  Future<void> verificarAdmin() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      if (mounted) {
        setState(() {
          mensaje = "No tienes acceso. Inicia sesión.";
          _isLoading = false;
        });
      }
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/superadmin"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            nombre = data["nombre"] ?? "Administrador";
            email = data["email"] ?? "";
            mensaje = "";
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            mensaje = "Error al cargar datos";
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          mensaje = "";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Future<void> seleccionarImagen() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        setState(() {
          _image = File(image.path);
          _imagePath = image.path; // Guardamos la ruta para web
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => mensaje = "Error al seleccionar imagen");
      }
    }
  }

  ImageProvider? _getImageProvider() {
    if (_image == null) return null;
    
    if (kIsWeb) {
      // Para web usamos NetworkImage con la ruta directa
      return NetworkImage(_imagePath!);
    } else {
      // Para móvil/desktop usamos FileImage
      return FileImage(_image!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5E1DA),
      appBar: AppBar(
        title: Text("Panel de Administrador"),
        backgroundColor: Color(0xFFE5E1DA),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.black),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Imagen del administrador
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _getImageProvider(),
                          child: _image == null 
                              ? Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              onPressed: seleccionarImagen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Información del Administrador
                  Text(
                    "Bienvenido, $nombre",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  SizedBox(height: 20),

                  // Botones de gestión
                  Expanded(
                    child: ListView(
                      physics: BouncingScrollPhysics(),
                      children: [
                        _buildMenuButton(
                          "Gestión de Usuarios", 
                          Icons.people, 
                          AppRoutes.adminUsuarios
                        ),
                        _buildMenuButton(
                          "Gestión de Productos", 
                          Icons.shopping_bag, 
                          AppRoutes.adminProductos
                        ),
                        _buildMenuButton(
                          "Gestión de Compras", 
                          Icons.shopping_cart, 
                          AppRoutes.adminPedidos
                        ),
                        _buildMenuButton(
                          "Gestión de Reseñas", 
                          Icons.star, 
                          AppRoutes.adminResenas
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      "© ${DateTime.now().year} Stay in Style",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, String route) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, route),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }
}