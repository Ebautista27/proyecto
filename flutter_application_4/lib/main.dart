import 'package:flutter/material.dart';
import 'routes/app_routes.dart'; // Importa la clase de rutas

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stay in Style',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login, // Empieza en el login
      routes: AppRoutes.routes, // Usa el mapa de rutas centralizado
    );
  }
}

