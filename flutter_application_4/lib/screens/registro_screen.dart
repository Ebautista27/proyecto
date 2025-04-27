import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../routes/app_routes.dart';

class RegistroScreen extends StatefulWidget {
  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _direccionController = TextEditingController();
  final _celularController = TextEditingController();

  bool _isLoading = false;
  String _mensaje = '';
  bool _showPassword = false;

  Future<void> _registrar() async {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _mensaje = 'Nombre, email y contraseña son obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/registro'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nombreController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'direccion': _direccionController.text,
          'num_cel': _celularController.text,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() => _mensaje = '¡Registro exitoso!');
        await Future.delayed(Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        setState(
          () => _mensaje = responseData['mensaje'] ?? 'Error en el registro',
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
      appBar: AppBar(title: Text('Registro'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre',
              icon: Icons.person,
            ),
            SizedBox(height: 15),
            _buildTextField(
              controller: _emailController,
              label: 'Correo Electrónico',
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email,
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
            SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _showPassword,
                  onChanged: (value) => setState(() => _showPassword = value!),
                ),
                Text('Mostrar contraseña'),
              ],
            ),
            SizedBox(height: 15),
            _buildTextField(
              controller: _direccionController,
              label: 'Dirección',
              icon: Icons.home,
            ),
            SizedBox(height: 15),
            _buildTextField(
              controller: _celularController,
              label: 'Número de Celular',
              keyboardType: TextInputType.phone,
              icon: Icons.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _registrar,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child:
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Registrarse'),
            ),
            SizedBox(height: 10),
            if (_mensaje.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _mensaje,
                  style: TextStyle(
                    color:
                        _mensaje.contains('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            TextButton(
              onPressed:
                  () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
              child: Text.rich(
                TextSpan(
                  text: '¿Ya tienes cuenta? ',
                  children: [
                    TextSpan(
                      text: 'Inicia Sesión',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // BOTÓN DE CASA
            IconButton(
              icon: Icon(
                Icons.home,
                size: 40,
                color: Colors.black87,
              ), // Ícono de casa
              onPressed:
                  () => Navigator.pushReplacementNamed(context, AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _direccionController.dispose();
    _celularController.dispose();
    super.dispose();
  }
}
