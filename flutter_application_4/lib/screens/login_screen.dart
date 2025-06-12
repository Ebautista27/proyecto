import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  String mensaje = "";

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => mensaje = "Por favor completa todos los campos");
      return;
    }

    setState(() {
      isLoading = true;
      mensaje = "";
    });

    try {
      final res = await http.post(
        Uri.parse("http://localhost:5000/login"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'];
        final usuario = data['usuario'];

        await prefs.setString("token", token);
        await prefs.setInt("id_usuario", usuario['id']);
        await prefs.setString("nombre_usuario", usuario['nombre']);
        await prefs.setString("email_usuario", usuario['email']);
        await prefs.setString("direccion_usuario", usuario['direccion'] ?? "");
        await prefs.setInt("userRole", usuario['id_rol']);

        // Superadmin por correo + clave exacta
        if (email == "superadmin@example.com" && password == "superadmin123") {
          await prefs.setBool("isSuperAdmin", true);
          setState(() => mensaje = "Inicio de sesión exitoso como SuperAdmin");
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, "/admin");
          });
        }
        // Admin
        else if (usuario['id_rol'] == 1) {
          setState(() => mensaje = "Inicio de sesión exitoso como administrador");
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, "/admin");
          });
        }
        // Cliente normal
        else {
          setState(() => mensaje = "Inicio de sesión exitoso");
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, "/home");
          });
        }
      } else {
        setState(() {
          mensaje = data['mensaje'] ?? "Error al iniciar sesión. Verifica tus credenciales.";
        });
      }
    } catch (e) {
      setState(() {
        mensaje = "Error de conexión al servidor";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE5E5E5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Inicia Sesión", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Correo Electrónico"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : handleLogin,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Iniciar Sesión"),
              ),
              const SizedBox(height: 10),
              if (mensaje.isNotEmpty)
                Text(
                  mensaje,
                  style: TextStyle(
                    color: mensaje.contains("exitoso") ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, "/forgot-password"),
                child: const Text("¿Olvidaste tu contraseña?"),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, "/registro"),
                child: const Text("¿No tienes cuenta? Regístrate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
