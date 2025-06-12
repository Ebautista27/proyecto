import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CarritoProvider with ChangeNotifier {
  Map<String, dynamic>? _carrito;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get carrito => _carrito;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> obtenerCarrito() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _error = 'No autenticado';
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/carritos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _carrito = json.decode(response.body);
        _error = null;
      } else if (response.statusCode == 404) {
        _carrito = {'productos': []};
        _error = null;
      } else {
        _error = 'Error al obtener el carrito: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error de conexión: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> agregarProducto({
    required String productoId,
    required int tallaId,
    required int cantidad,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/carritos/productos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_producto': productoId,
          'id_talla': tallaId,
          'cantidad': cantidad,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await obtenerCarrito();
      } else {
        throw Exception('Error al agregar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> eliminarProducto(String productoId) async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/carritos/producto/$productoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await obtenerCarrito();
      } else {
        throw Exception('Error al eliminar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarCantidad(String productoId, int nuevaCantidad) async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('http://localhost:5000/api/carritos/producto/$productoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'cantidad': nuevaCantidad}),
      );

      if (response.statusCode == 200) {
        await obtenerCarrito();
      } else {
        throw Exception('Error al actualizar cantidad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> vaciarCarrito() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/carritos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _carrito = {'productos': []};
        _error = null;
      } else {
        throw Exception('Error al vaciar carrito: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}