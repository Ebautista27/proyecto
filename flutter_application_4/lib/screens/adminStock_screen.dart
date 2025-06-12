import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class AdminStockScreen extends StatefulWidget {
  const AdminStockScreen({Key? key}) : super(key: key);

  @override
  _AdminStockScreenState createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends State<AdminStockScreen> {
  final _storage = const FlutterSecureStorage();
  
  List<dynamic> inventory = [];
  List<dynamic> products = [];
  List<dynamic> sizes = [];
  List<dynamic> history = [];
  
  bool showHistory = false;
  bool showGeneralHistory = false;
  bool loading = true;
  String? error;
  String? successMsg;
  
  // Form data
  String? selectedProductId;
  String? selectedSizeId;
  int stock = 0;
  String reason = '';
  String? editId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => loading = true);
    try {
      final token = await _storage.read(key: 'token');
      
      final responses = await Future.wait([
        http.get(
          Uri.parse('http://localhost:5000/productos'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('http://localhost:5000/api/tallas'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          products = json.decode(responses[0].body);
          // Manejo flexible de tallas
          final sizesData = json.decode(responses[1].body);
          sizes = sizesData['tallas'] ?? sizesData;
        });
      } else {
        throw Exception('Error al cargar datos iniciales');
      }
    } catch (e) {
      setState(() => error = 'Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadInventory() async {
    if (selectedProductId == null) return;
    
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/productos/$selectedProductId/inventario'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => inventory = json.decode(response.body));
      } else {
        throw Exception('Error al cargar inventario');
      }
    } catch (e) {
      setState(() => error = 'Error al cargar inventario: $e');
    }
  }

  Future<void> _loadProductHistory() async {
    if (selectedProductId == null) return;
    
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/historial-stock/producto/$selectedProductId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => history = json.decode(response.body));
      } else {
        throw Exception('Error al cargar historial');
      }
    } catch (e) {
      setState(() => error = 'Error al cargar historial: $e');
    }
  }

  Future<void> _loadGeneralHistory() async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/historial-stock'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => history = json.decode(response.body));
      } else {
        throw Exception('Error al cargar historial general');
      }
    } catch (e) {
      setState(() => error = 'Error al cargar historial general: $e');
    }
  }

  Future<void> _saveStock() async {
    try {
      setState(() {
        error = null;
        successMsg = null;
      });

      // Validaciones
      if (selectedProductId == null || selectedSizeId == null) {
        throw Exception('Debes seleccionar un producto y una talla');
      }
      if (stock < 0) {
        throw Exception('El stock debe ser un número positivo');
      }

      final token = await _storage.read(key: 'token');
      final url = editId != null
          ? 'http://localhost:5000/api/inventario/$editId'
          : 'http://localhost:5000/api/productos/$selectedProductId/inventario';
      
      final method = editId != null ? 'PUT' : 'POST';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(editId != null
            ? {'stock': stock}
            : {
                'id_talla': int.parse(selectedSizeId!),
                'stock': stock,
              }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['mensaje'] ?? 'Error en la operación');
      }

      // Registrar en historial si es edición
      if (editId != null) {
        await _registerHistoryChange(
          editId!,
          inventory.firstWhere((item) => item['id'].toString() == editId)['stock'],
          stock,
          reason.isNotEmpty ? reason : 'Actualización manual',
        );
      }

      setState(() {
        successMsg = editId != null ? '¡Inventario actualizado!' : '¡Nuevo stock agregado!';
      });

      // Refrescar datos
      await _loadInventory();
      if (showHistory) await _loadProductHistory();
      if (showGeneralHistory) await _loadGeneralHistory();
      _resetForm();
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _registerHistoryChange(String inventoryId, int oldStock, int newStock, String reason) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/historial-stock/crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_inventario': int.parse(inventoryId),
          'stock_anterior': oldStock,
          'stock_nuevo': newStock,
          'motivo': reason,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al registrar en historial');
      }
    } catch (e) {
      print('Error al registrar en historial: $e');
      rethrow;
    }
  }

  Future<void> _deleteInventoryItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este registro de inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final item = inventory.firstWhere((item) => item['id'].toString() == id);
      final token = await _storage.read(key: 'token');
      
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/inventario/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar');
      }

      // Registrar en historial
      await _registerHistoryChange(
        id,
        item['stock'],
        0,
        'Eliminación de registro',
      );

      setState(() {
        successMsg = '¡Registro de inventario eliminado!';
        inventory.removeWhere((item) => item['id'].toString() == id);
      });

      if (showHistory) await _loadProductHistory();
      if (showGeneralHistory) await _loadGeneralHistory();
    } catch (e) {
      setState(() => error = 'Error al eliminar: $e');
    }
  }

  void _editInventoryItem(Map<String, dynamic> item) {
    setState(() {
      selectedProductId = item['id_producto'].toString();
      selectedSizeId = item['id_talla'].toString();
      stock = item['stock'];
      editId = item['id'].toString();
    });
    _loadInventory();
  }

  void _resetForm() {
    setState(() {
      if (editId == null) {
        selectedSizeId = null;
        stock = 0;
      }
      reason = '';
      editId = null;
    });
  }

  String _getProductName(int productId) {
    return products.firstWhere(
      (product) => product['id'] == productId,
      orElse: () => {'nombre': 'N/A'},
    )['nombre'];
  }

  String _getProductImage(int productId) {
    return products.firstWhere(
      (product) => product['id'] == productId,
      orElse: () => {'imagen_url': 'https://via.placeholder.com/50'},
    )['imagen_url'];
  }

  String _getSizeName(int sizeId) {
    return sizes.firstWhere(
      (size) => size['id'] == sizeId,
      orElse: () => {'nombre': 'N/A'},
    )['nombre'];
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Stock'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mensajes de error/éxito
            if (error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: Colors.red, width: 4),
                  ),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            if (successMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: Colors.green, width: 4),
                  ),
                ),
                child: Text(
                  successMsg!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),

            // Formulario
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      editId != null ? 'Editar Registro' : 'Agregar Stock',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedProductId,
                      items: products.map<DropdownMenuItem<String>>((product) {
                        return DropdownMenuItem(
                          value: product['id'].toString(),
                          child: Text(product['nombre']),
                        );
                      }).toList(),
                      onChanged: editId == null
                          ? (value) {
                              setState(() => selectedProductId = value);
                              _loadInventory();
                            }
                          : null,
                      validator: (value) =>
                          value == null ? 'Selecciona un producto' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Talla',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedSizeId,
                      items: sizes.map<DropdownMenuItem<String>>((size) {
                        return DropdownMenuItem(
                          value: size['id'].toString(),
                          child: Text(size['nombre']),
                        );
                      }).toList(),
                      onChanged: selectedProductId != null
                          ? (value) => setState(() => selectedSizeId = value)
                          : null,
                      validator: (value) =>
                          value == null ? 'Selecciona una talla' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: stock.toString(),
                      onChanged: (value) =>
                          stock = int.tryParse(value) ?? 0,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa una cantidad';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 0) {
                          return 'Debe ser un número positivo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    if (editId != null)
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Motivo del cambio (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => reason = value,
                      ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveStock,
                            child: Text(editId != null ? 'Actualizar' : 'Agregar'),
                          ),
                        ),
                        if (editId != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetForm,
                              child: const Text('Cancelar'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sección de inventario/historial
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inventario Actual',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        Row(
                          children: [
                            if (selectedProductId != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      showHistory = !showHistory;
                                      showGeneralHistory = false;
                                    });
                                    if (showHistory) _loadProductHistory();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: showHistory ? Colors.blue[100] : null,
                                    onPrimary: showHistory ? Colors.blue : null,
                                  ),
                                  child: Text(showHistory ? 'Ocultar Historial' : 'Historial del Producto'),
                                ),
                              ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  showGeneralHistory = !showGeneralHistory;
                                  showHistory = false;
                                });
                                if (showGeneralHistory) _loadGeneralHistory();
                              },
                              style: ElevatedButton.styleFrom(
                                primary: showGeneralHistory ? Colors.blue[100] : null,
                                onPrimary: showGeneralHistory ? Colors.blue : null,
                              ),
                              child: Text(showGeneralHistory ? 'Ocultar Historial General' : 'Historial General'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (showHistory || showGeneralHistory)
                      _buildHistoryTable()
                    else if (selectedProductId != null)
                      inventory.isNotEmpty
                          ? _buildInventoryTable()
                          : const Center(child: Text('No hay registros de inventario para este producto'))
                    else
                      const Center(child: Text('Selecciona un producto para ver su inventario')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Imagen')),
          DataColumn(label: Text('Talla')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: inventory.map<DataRow>((item) {
          return DataRow(cells: [
            DataCell(Text(_getProductName(item['id_producto']))),
            DataCell(
              Image.network(
                _getProductImage(item['id_producto']),
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const Icon(Icons.error),
              ),
            ),
            DataCell(Text(_getSizeName(item['id_talla']))),
            DataCell(
              Text(
                item['stock'].toString(),
                style: TextStyle(
                  color: item['stock'] > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editInventoryItem(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteInventoryItem(item['id'].toString()),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Talla')),
          DataColumn(label: Text('Stock Anterior')),
          DataColumn(label: Text('Stock Nuevo')),
          DataColumn(label: Text('Cambio')),
          DataColumn(label: Text('Motivo')),
        ],
        rows: history.map<DataRow>((item) {
          final difference = (item['stock_nuevo'] ?? 0) - (item['stock_anterior'] ?? 0);
          return DataRow(cells: [
            DataCell(Text(_formatDate(item['fecha_cambio']))),
            DataCell(
              Row(
                children: [
                  Image.network(
                    item['producto_imagen'] ?? 'https://via.placeholder.com/50',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error),
                  ),
                  const SizedBox(width: 8),
                  Text(item['producto_nombre'] ?? 'N/A'),
                ],
              ),
            ),
            DataCell(Text(item['talla_nombre'] ?? 'N/A')),
            DataCell(Text((item['stock_anterior'] ?? 0).toString())),
            DataCell(Text((item['stock_nuevo'] ?? 0).toString())),
            DataCell(
              Text(
                difference > 0 ? '+$difference' : difference.toString(),
                style: TextStyle(
                  color: difference > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(Text(item['motivo'] ?? '')),
          ]);
        }).toList(),
      ),
    );
  }
}