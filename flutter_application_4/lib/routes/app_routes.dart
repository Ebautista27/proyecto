import 'package:flutter/material.dart';

// Importaciones con alias para resolver conflictos
import '../screens/login_screen.dart' as login_screen;
import '../screens/carrito_screen.dart' as carrito_screen;

// Otras importaciones
import '../screens/home_screen.dart';
import '../screens/registro_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/adminUsuarios_screen.dart';
import '../screens/adminProductos_screen.dart';
import '../screens/adminPedidos_screen.dart';
import '../screens/confirmacion_screen.dart';
import '../screens/adminResenas_screen.dart';
import '../screens/comprar_screen.dart';
import '../screens/catgoriash_screen.dart';
import '../screens/categoriasm_screen.dart';
import '../screens/producto/detalle_producto_screen.dart';

class AppRoutes {
  // Nombres de rutas estáticas
  static const String home = '/home';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String admin = '/admin';
  static const String adminUsuarios = '/admin/usuarios';
  static const String adminProductos = '/admin/productos';
  static const String adminPedidos = '/admin/pedidos';
  static const String adminResenas = '/admin/resenas';
  static const String carrito = '/carrito';
  static const String comprar = '/carrito/comprar';
  static const String confirmacion = '/confirmacion';
  static const String categoriash = '/categorias/hombres';
  static const String categoriasm = '/categorias/mujeres';
  static const String detalleProducto = '/producto';

  // Mapa de rutas principales
  static Map<String, WidgetBuilder> get routes => {
        home: (context) => HomeScreen(),
        login: (context) => login_screen.LoginScreen(),
        registro: (context) => RegistroScreen(),
        admin: (context) => AdministradorScreen(),
        adminUsuarios: (context) => AdminUsuariosScreen(),
        adminProductos: (context) => AdminProductosScreen(),
        adminPedidos: (context) => AdminComprasScreen(),
        adminResenas: (context) => AdminResenasScreen(),
        carrito: (context) => carrito_screen.CarritoScreen(),
        comprar: (context) => ComprarScreen(),
        categoriash: (context) => CategoriashScreen(),
        categoriasm: (context) => CategoriasmScreen(),
      };

  // Generador de rutas para rutas dinámicas
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Manejo de ruta de detalle de producto
    if (settings.name!.startsWith(detalleProducto)) {
      final uri = Uri.parse(settings.name!);
      if (uri.pathSegments.length == 2) {
        final productId = uri.pathSegments[1];
        return MaterialPageRoute(
          builder: (context) => DetalleProductoScreen(idProducto: productId),
          settings: settings,
        );
      }
    }

    // Manejo de ruta de confirmación con argumentos
    if (settings.name == confirmacion) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      return MaterialPageRoute(
        builder: (context) => ConfirmacionScreen(compraData: args['compraData']),
        settings: settings,
      );
    }

    // Ruta no encontrada
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Ruta no encontrada: ${settings.name}'),
        ),
      ),
    );
  }

  // Métodos estáticos para navegación con parámetros
  static void goToProductDetail(BuildContext context, String productId) {
    Navigator.pushNamed(
      context,
      '$detalleProducto/$productId',
    );
  }

  static void goToConfirmation(BuildContext context, Map<String, dynamic> compraData) {
    Navigator.pushNamed(
      context,
      confirmacion,
      arguments: {'compraData': compraData},
    );
  }
}