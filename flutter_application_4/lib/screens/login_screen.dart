import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String _mensaje = '';
  bool _isLoading = false;

  Future<void> _iniciarSesion() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _mensaje = 'Email y contraseña son obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);

        // Redirección directa basada en el email (para super admin)
        if (_emailController.text == 'superadmin@example.com') {
          Navigator.pushReplacementNamed(context, AppRoutes.admin);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        setState(
          () =>
              _mensaje = responseData['mensaje'] ?? 'Credenciales incorrectas',
        );
      }
    } catch (error) {
      setState(() => _mensaje = 'Error de conexión: ${error.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5E1DA),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Inicia Sesión',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed:
                      () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: _isLoading ? null : _iniciarSesion,
              child:
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Iniciar Sesión'),
            ),

            if (_mensaje.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  _mensaje,
                  style: TextStyle(
                    color:
                        _mensaje.contains('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],

            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.registro),
              child: Text('¿No tienes cuenta? Regístrate'),
            ),

            SizedBox(height: 20),

            IconButton(
              icon: Icon(Icons.home, size: 40, color: Colors.black87),
              onPressed:
                  () => Navigator.pushReplacementNamed(context, AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
