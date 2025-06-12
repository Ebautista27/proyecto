import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:io';

class AdminProductosScreen extends StatefulWidget {
  @override
  _AdminProductosScreenState createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  List<dynamic> productos = [];
  List<dynamic> categorias = [];
  List<dynamic> generos = [];
  File? _imageFile;
  String? _imageUrl;
  String? token;

  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'nombre': '',
    'descripcion': '',
    'precio': '',
    'estado': 'Disponible',
    'id_categoria': '',
    'id_genero': '',
  };

  dynamic _editData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _fetchData();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
    });

    try {
      final endpoints = [
        {'url': 'http://localhost:5000/productos', 'key': 'productos'},
        {'url': 'http://localhost:5000/categorias', 'key': 'categorias'},
        {'url': 'http://localhost:5000/api/generos', 'key': 'generos'},
      ];

      final responses = await Future.wait(
        endpoints.map((endpoint) => http.get(
          Uri.parse(endpoint['url']!),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        )),
      );

      final productosData = json.decode(responses[0].body);
      final categoriasData = json.decode(responses[1].body);
      final generosData = json.decode(responses[2].body);

      // Procesamiento de géneros
      List<dynamic> generosProcesados = [];
      if (generosData is List) {
        generosProcesados = generosData;
      } else if (generosData['generos'] is List) {
        generosProcesados = generosData['generos'];
      } else if (generosData['data'] is List) {
        generosProcesados = generosData['data'];
      }

      setState(() {
        productos = productosData is List ? productosData : [];
        categorias = categoriasData is List ? categoriasData : [];
        generos = generosProcesados;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
      });
      EasyLoading.showError('Error al cargar datos: ${error.toString()}');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      EasyLoading.showError('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_formData['id_categoria'] == '') {
      EasyLoading.showError('Debes seleccionar una categoría');
      return;
    }

    if (_formData['id_genero'] == '') {
      EasyLoading.showError('Debes seleccionar un género');
      return;
    }

    if (_imageFile == null && _editData == null) {
      EasyLoading.showError('Debes seleccionar una imagen');
      return;
    }

    EasyLoading.show(status: 'Procesando...');

    try {
      final url = _editData != null
          ? 'http://localhost:5000/productos/${_editData['id']}'
          : 'http://localhost:5000/productos/nuevo';

      final request = http.MultipartRequest(
        _editData != null ? 'PUT' : 'POST',
        Uri.parse(url),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['nombre'] = _formData['nombre'];
      request.fields['descripcion'] = _formData['descripcion'];
      request.fields['precio'] = _formData['precio'];
      request.fields['estado'] = _formData['estado'];
      request.fields['id_categoria'] = _formData['id_categoria'];
      request.fields['id_genero'] = _formData['id_genero'];

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'imagen',
            _imageFile!.path,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        EasyLoading.showSuccess(
          _editData != null 
            ? 'Producto actualizado con éxito' 
            : 'Producto creado con éxito'
        );
        _resetForm();
        await _fetchData();
      } else {
        throw Exception(decodedResponse['message'] ?? decodedResponse['error'] ?? 'Error en la operación');
      }
    } catch (error) {
      EasyLoading.showError('Error: ${error.toString()}');
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _formData.updateAll((key, value) => '');
      _formData['estado'] = 'Disponible';
      _formData['id_categoria'] = '';
      _formData['id_genero'] = '';
      _imageFile = null;
      _imageUrl = null;
      _editData = null;
    });
  }

  void _editProduct(dynamic producto) {
    setState(() {
      _editData = producto;
      _formData['nombre'] = producto['nombre'] ?? '';
      _formData['descripcion'] = producto['descripcion'] ?? '';
      _formData['precio'] = (producto['precio']?.toString() ?? '0.0');
      _formData['estado'] = producto['estado'] ?? 'Disponible';
      _formData['id_categoria'] = (producto['id_categoria']?.toString() ?? '');
      _formData['id_genero'] = (producto['id_genero']?.toString() ?? '');
      _imageUrl = producto['imagen_url'];
      _imageFile = null;
    });
  }

  Future<void> _deleteProduct(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    EasyLoading.show(status: 'Eliminando...');

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/productos/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Producto eliminado con éxito');
        await _fetchData();
      } else {
        throw Exception(json.decode(response.body)['message'] ?? json.decode(response.body)['error'] ?? 'Error al eliminar');
      }
    } catch (error) {
      EasyLoading.showError('Error: ${error.toString()}');
    }
  }

  String _getNombreCategoria(int idCategoria) {
    try {
      final categoria = categorias.firstWhere(
        (cat) => cat['id'] == idCategoria,
      );
      return categoria['nombre'] ?? 'ID: $idCategoria';
    } catch (e) {
      return 'ID: $idCategoria';
    }
  }

  String _getNombreGenero(int idGenero) {
    try {
      final genero = generos.firstWhere(
        (gen) => gen['id'] == idGenero,
      );
      return genero['nombre'] ?? 'ID: $idGenero';
    } catch (e) {
      return 'ID: $idGenero';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Productos'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editData != null ? 'Editar Producto' : 'Crear Producto',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _formData['nombre'],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un nombre';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _formData['nombre'] = value;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    initialValue: _formData['descripcion'],
                    onChanged: (value) {
                      _formData['descripcion'] = value;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    initialValue: _formData['precio'],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un precio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Por favor ingresa un número válido';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _formData['precio'] = value;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    value: _formData['estado'],
                    items: ['Disponible', 'Agotado', 'No disponible']
                        .map((estado) => DropdownMenuItem(
                              value: estado,
                              child: Text(estado),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _formData['estado'] = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    value: _formData['id_categoria'].isEmpty ? null : _formData['id_categoria'],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona una categoría';
                      }
                      return null;
                    },
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text('Seleccione una categoría'),
                      ),
                      ...categorias.map((categoria) => DropdownMenuItem(
                            value: categoria['id'].toString(),
                            child: Text(categoria['nombre'] ?? 'Sin nombre'),
                          ))
                    ],
                    onChanged: (value) {
                      setState(() {
                        _formData['id_categoria'] = value ?? '';
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Género',
                      border: OutlineInputBorder(),
                    ),
                    value: _formData['id_genero'].isEmpty ? null : _formData['id_genero'],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona un género';
                      }
                      return null;
                    },
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text('Seleccione un género'),
                      ),
                      ...generos.map((genero) => DropdownMenuItem(
                            value: genero['id'].toString(),
                            child: Text(genero['nombre'] ?? 'Sin nombre'),
                          ))
                    ],
                    onChanged: (value) {
                      setState(() {
                        _formData['id_genero'] = value ?? '';
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Imagen del Producto'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text('Seleccionar Imagen'),
                      ),
                      SizedBox(height: 8),
                      if (_imageFile != null)
                        Image.file(
                          _imageFile!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                      else if (_imageUrl != null)
                        Image.network(
                          _imageUrl!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Icon(Icons.broken_image, size: 100),
                        ),
                      if (_imageFile == null && _imageUrl == null)
                        Text('Ninguna imagen seleccionada'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _editData != null 
                              ? 'Guardar Cambios' 
                              : 'Crear Producto',
                          ),
                        ),
                      ),
                      if (_editData != null) ...[
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _resetForm,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.grey,
                            ),
                            child: Text('Cancelar'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Lista de Productos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (productos.isEmpty)
              Center(child: Text('No hay productos registrados'))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Precio')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Género')),
                    DataColumn(label: Text('Imagen')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: productos.map((producto) {
                    return DataRow(cells: [
                      DataCell(Text(producto['nombre'] ?? 'Sin nombre')),
                      DataCell(Text('\$${(producto['precio'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(producto['estado']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            producto['estado'] ?? 'Desconocido',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(_getNombreCategoria(producto['id_categoria'] as int? ?? 0))),
                      DataCell(Text(_getNombreGenero(producto['id_genero'] as int? ?? 0))),
                      DataCell(
                        producto['imagen_url'] != null
                            ? Image.network(
                                producto['imagen_url']!,
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) => 
                                    Icon(Icons.broken_image),
                              )
                            : Icon(Icons.image_not_supported),
                      ),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editProduct(producto),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(producto['id'] as int),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'disponible':
        return Colors.green;
      case 'agotado':
        return Colors.red;
      case 'no disponible':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}