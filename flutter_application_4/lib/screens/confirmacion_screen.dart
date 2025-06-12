// confirmacion_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConfirmacionScreen extends StatelessWidget {
  final Map<String, dynamic> compraData;

  const ConfirmacionScreen({Key? key, required this.compraData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(compraData['fecha'] ?? DateTime.now().toString());
    final fechaFormateada = DateFormat('EEEE, d MMMM y - HH:mm', 'es_ES').format(fecha);
    
    final productos = compraData['productos'] as List<dynamic>? ?? [];
    final total = compraData['total'] as double? ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmación de Compra'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Icono de éxito
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            
            // Título
            Text(
              '¡Compra realizada con éxito! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            
            // Subtítulo
            Text(
              'Tu pedido ha sido confirmado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            
            // Detalles de la compra
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de la compra
                    _buildInfoItem('Fecha:', fechaFormateada),
                    _buildInfoItem('Barrio de entrega:', compraData['barrio'] ?? ''),
                    _buildInfoItem('Método de pago:', compraData['metodoPago'] ?? ''),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Productos comprados
            Text(
              'Productos comprados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            // Lista de productos
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: productos.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final producto = productos[index];
                return ListTile(
                  leading: Image.network(
                    producto['imagen_url'] ?? 'https://via.placeholder.com/300x300?text=Imagen+no+disponible',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Image.network('https://via.placeholder.com/300x300?text=Imagen+no+disponible', width: 60, height: 60),
                  ),
                  title: Text(producto['nombre'] ?? 'Producto'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Talla: ${producto['talla'] ?? ''}'),
                      Text('Cantidad: ${producto['cantidad'] ?? ''}'),
                    ],
                  ),
                  trailing: Text(
                    '\$${(producto['precio_unitario'] * producto['cantidad']).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            
            // Total
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Mensaje final
            Text(
              'Hemos recibido tu pedido correctamente y lo estamos procesando.\n\n'
              'Recibirás una confirmación adicional por correo electrónico con los detalles de seguimiento.\n\n'
              '¡Gracias por confiar en nosotros!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            
            // Botón para volver al inicio
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false),
                child: Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}