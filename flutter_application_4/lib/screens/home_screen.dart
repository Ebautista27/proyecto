import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class Producto {
  final int id;
  final String nombre;
  final String precio;
  final String imagen;
  final String ruta;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagen,
    required this.ruta,
  });
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Producto> productos = [
    Producto(
      id: 1,
      nombre: "Chaqueta cargo 610",
      precio: "110.000 mil pesos",
      imagen: 'assets/imagenes/chaqueta_cargo_610.jpg',
      ruta: '/detalleProducto1',
    ),
    Producto(
      id: 2,
      nombre: "Chaqueta Polo",
      precio: "105.000 mil pesos",
      imagen: 'assets/imagenes/chaqueta_ovejera_blanca.jpeg',
      ruta: '/Productos/detalle_producto2',
    ),
    Producto(
      id: 3,
      nombre: "Camiseta Choize",
      precio: "90.000 mil pesos",
      imagen: 'assets/imagenes/camiseta choize.jpeg',
      ruta: '/Productos/detalle_producto3',
    ),
    Producto(
      id: 4,
      nombre: "Camisa boxy fit",
      precio: "100.000 mil pesos",
      imagen: 'assets/imagenes/camiseta bbs.jpeg',
      ruta: '/Productos/detalle_producto4',
    ),
  ];

  final List<String> imagenesVideo = [
    'assets/imagenes/prenda_video.jpeg',
    'assets/imagenes/chaqueta negra carrusel.jpeg',
    'assets/imagenes/camiseta carrusel.jpeg',
  ];

  final List<Map<String, dynamic>> categorias = [
    {
      'imagen': 'assets/imagenes/categoria hombres.jpeg',
      'nombre': 'Hombres',
      'ruta': '/Categorias/Categoriash',
    },
    {
      'imagen': 'assets/imagenes/categorias mujer.jpeg',
      'nombre': 'Mujeres',
      'ruta': '/Categorias/Categoriasm',
    },
  ];

  TextEditingController _searchController = TextEditingController();
  List<Producto> _filteredProductos = [];
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _filteredProductos = productos;
  }

  void _filterProductos() {
    setState(() {
      _filteredProductos =
          productos
              .where(
                (producto) => producto.nombre.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Cerrar sesión'),
            content: Text('¿Estás seguro que quieres salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Salir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 375;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E1DA),
      body: CustomScrollView(
        slivers: [
          // SliverAppBar (mantén tu versión actual aquí)
          SliverAppBar(
            backgroundColor: Colors.black,
            pinned: true,
            expandedHeight: 80, // Reducimos un poco la altura
            floating: true, // Para que aparezca rápido al hacer scroll up
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                left: 10,
                bottom: 10,
              ), // Menos padding
              centerTitle: false, // Alineado a la izquierda
              title: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Espacio optimizado
                children: [
                  // Logo y título más compactos
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Ocupa solo el espacio necesario
                      children: [
                        Container(
                          width: 40, // Logo más pequeño
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            image: DecorationImage(
                              image: AssetImage('assets/imagenes/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 8), // Espacio reducido
                        Text(
                          'STAY IN STYLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Texto un poco más pequeño
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Iconos más pegados al título
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.white, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _showSearch = !_showSearch;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          Navigator.pushNamed(context, '/carrito');
                        },
                      ),
                      // Botón Login más compacto
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            ),
                        child: Text(
                          'Login',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            bottom:
                _showSearch
                    ? PreferredSize(
                      preferredSize: Size.fromHeight(60),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ), // Padding reducido
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => _filterProductos(),
                          decoration: InputDecoration(
                            hintText: 'Buscar...', // Texto más corto
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 20,
                              ), // Icono más pequeño
                              onPressed: () {
                                setState(() {
                                  _showSearch = false;
                                  _searchController.clear();
                                  _filterProductos();
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    )
                    : null,
          ),

          // ... (tu código existente del SliverAppBar) ...
          SliverPadding(
            padding: EdgeInsets.all(15),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final producto = _filteredProductos[index];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, producto.ruta),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.asset(
                              producto.imagen,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 5),
                              Text(
                                producto.precio,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  minimumSize: Size(double.infinity, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('Añadir al carrito'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _filteredProductos.length),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagenesVideo[index],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.grey[200],
                          height: 250,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  ),
                ),
              );
            }, childCount: imagenesVideo.length),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final categoria = categorias[index];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, categoria['ruta']),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          categoria['imagen'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Text(
                          categoria['nombre'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: categorias.length),
            ),
          ),
        ],
      ),
    );
  }
}
