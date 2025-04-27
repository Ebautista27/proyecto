from marshmallow_sqlalchemy import SQLAlchemyAutoSchema
from marshmallow import fields
from marshmallow_sqlalchemy import SQLAlchemyAutoSchema, auto_field
from .modelo import (
    Rol, Usuario, Carrito, CarritoProducto, Producto, Categoria, Talla,
    Pedido, MetodoPago, Factura, Reseña, DetalleFactura, Compra
)

class RolSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Rol
        include_relationships = True
        load_instance = True

class UsuarioSchema(SQLAlchemyAutoSchema):
    rol = fields.Nested(RolSchema)  # Serializar la relación con Rol usando RolSchema
    
    class Meta:
        model = Usuario
        include_relationships = True  # Incluir relaciones como 'rol'
        load_instance = True  # Habilitar carga de instancias SQLAlchemy
        exclude = ("contrasena_hash",)  # Excluir campos sensibles como contraseñas

usuario_schema = UsuarioSchema()
usuarios_schema = UsuarioSchema(many=True)  

# Resto de los esquemas (CarritoSchema, CarritoProductoSchema, etc.) permanecen igual
class CarritoSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Carrito
        include_relationships = True
        load_instance = True

class CarritoProductoSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = CarritoProducto
        include_relationships = True
        load_instance = True

class ProductoSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Producto
        include_relationships = True
        load_instance = True

class CategoriaSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Categoria
        include_relationships = True
        load_instance = True

class TallaSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Talla
        include_relationships = True
        load_instance = True

class PedidoSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Pedido
        include_relationships = True
        load_instance = True

class MetodoPagoSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = MetodoPago
        include_relationships = True
        load_instance = True

class FacturaSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Factura
        include_relationships = True
        load_instance = True

class ReseñaSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Reseña
        include_relationships = True
        load_instance = True

    id_producto = auto_field()
    id_usuario = auto_field()
    producto = fields.Nested("ProductoSchema", only=["id", "nombre"])
    usuario = fields.Nested("UsuarioSchema", only=["id", "nombre"])
   


class DetalleFacturaSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = DetalleFactura
        include_relationships = True
        load_instance = True

class CompraSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Compra
        include_fk = True
        load_instance = True
        include_relationships = True

    # Relación con Usuario y MetodoPago
    usuario = fields.Nested("UsuarioSchema", only=("id", "nombre"))
    metodo_pago = fields.Nested("MetodoPagoSchema", only=("id", "tipo"))

    # Relación con productos (muchos a muchos)
    productos = fields.Method("obtener_productos")
    
    def obtener_productos(self, obj):
        """Método para obtener los productos asociados a la compra"""
        productos_data = []
        for producto_compra in obj.productos_compras:
            producto_data = {
                'id': producto_compra.id,  # Id del producto
                'nombre': producto_compra.nombre,  # Nombre del producto
                'precio_unitario': float(producto_compra.precio_unitario),
                'cantidad': producto_compra.cantidad,
                'subtotal': float(producto_compra.precio_unitario * producto_compra.cantidad)
            }
            productos_data.append(producto_data)
        return productos_data

# Instancias del esquema
compra_schema = CompraSchema()
compras_schema = CompraSchema(many=True)
