import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  String? nombreUsuario;
  int? userRol;
  bool isLoggedIn = false;
  bool isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getString('token') != null;
      nombreUsuario = prefs.getString('nombre_usuario');
      userRol = prefs.getInt('userRole');
      isSuperAdmin = prefs.getBool('isSuperAdmin') ?? false;
    });
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Navegar a la pantalla de login y limpiar el stack de navegación
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/login', 
      (Route<dynamic> route) => false
    );
    
    // Recargar para asegurar que todo el estado se reinicie
    if (mounted) {
      setState(() {
        isLoggedIn = false;
        nombreUsuario = null;
        userRol = null;
        isSuperAdmin = false;
      });
    }
  }

  Widget _buildLogoutButton() {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.red),
              SizedBox(width: 8),
              Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          _cerrarSesion();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSuperAdmin) {
      return _buildSuperAdminNav();
    } else if (isLoggedIn && userRol == 1) {
      return _buildAdminNav();
    } else if (isLoggedIn) {
      return _buildUserNav();
    } else {
      return _buildGuestNav();
    }
  }

  Widget _buildSuperAdminNav() {
    return BottomAppBar(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/'),
            ),
            Text(
              'Hola: $nombreUsuario',
              style: const TextStyle(color: Colors.white),
            ),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminNav() {
    return BottomAppBar(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/'),
            ),
            IconButton(
              icon: const Icon(Icons.dashboard, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
            ),
            Text(
              'Admin: $nombreUsuario',
              style: const TextStyle(color: Colors.white),
            ),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: 'Compras',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Pedido',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Carrito',
        ),
        BottomNavigationBarItem(
          icon: PopupMenuButton(
            icon: const Icon(Icons.person),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _cerrarSesion();
              }
            },
          ),
          label: nombreUsuario ?? 'Cuenta',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/');
            break;
          case 1:
            Navigator.pushNamed(context, '/compras');
            break;
          case 2:
            Navigator.pushNamed(context, '/pedido');
            break;
          case 3:
            Navigator.pushNamed(context, '/carrito');
            break;
          // El caso 4 (cuenta) ahora maneja el logout a través del PopupMenuButton
        }
      },
    );
  }

  Widget _buildGuestNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.login),
          label: 'Login',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_add),
          label: 'Registro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Carrito',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/');
            break;
          case 1:
            Navigator.pushNamed(context, '/login');
            break;
          case 2:
            Navigator.pushNamed(context, '/registro');
            break;
          case 3:
            Navigator.pushNamed(context, '/carrito');
            break;
        }
      },
    );
  }
}