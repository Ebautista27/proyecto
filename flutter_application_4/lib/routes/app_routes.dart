import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registro_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/adminUsuarios_screen.dart';
import '../screens/adminProductos_screen.dart';
import '../screens/adminPedidos_screen.dart';
import '../screens/adminResenas_screen.dart';
import '../screens/productos/detalle_producto1_screen.dart'; // ✅ Importación corregida

class AppRoutes {
  // Nombres de rutas
  static const String home = '/home';
  static const String login = '/';
  static const String registro = '/registro';
  static const String admin = '/admin';
  static const String adminUsuarios = '/adminUsuarios';
  static const String adminProductos = '/adminProductos';
  static const String adminPedidos = '/admincompras';
  static const String adminResenas = '/adminResenas';
  static const String detalleProducto1 = '/detalleProducto1';

  // Mapa de rutas
  static final Map<String, WidgetBuilder> routes = {
    login: (context) =>  LoginScreen(),
    registro: (context) =>  RegistroScreen(),
    home: (context) =>  HomeScreen(),
    admin: (context) =>  AdministradorScreen(),
    adminUsuarios: (context) =>  AdminUsuariosScreen(),
    adminProductos: (context) =>  AdminProductosScreen(),
    adminPedidos: (context) =>  AdminComprasScreen(),
    adminResenas: (context) =>  AdminResenasScreen(),
    detalleProducto1: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
          {}; // Manejo de null
      return DetalleProducto1Screen(
        id: args['id'] ?? '1', // Valores por defecto
        nombre: args['nombre'] ?? 'Producto',
        precio: args['precio'] ?? '0',
        descripcion: args['descripcion'] ?? 'Descripción no disponible',
      );
    },
  }; // ✅ Llave de cierre CORRECTA
}
