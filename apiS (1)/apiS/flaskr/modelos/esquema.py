from marshmallow_sqlalchemy import SQLAlchemyAutoSchema
from marshmallow import fields
from datetime import datetime
from marshmallow_sqlalchemy import SQLAlchemyAutoSchema, auto_field
from marshmallow import Schema, fields, validate
from flaskr.modelos import db
from flask_marshmallow import Marshmallow
from .modelo import (
    Rol, Usuario, Carrito, CarritoProducto, Producto, Categoria, Talla,
     MetodoPago,  Reseña, Compra, compra_producto,  db, Inventario, Genero,HistorialStock
)

class RolSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Rol
        include_relationships = True
        load_instance = True

# Estas líneas son cruciales - deben estar al final del archivo
rol_schema = RolSchema()
roles_schema = RolSchema(many=True)  # <-- Esta es la que te falta

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
        include_fk = True  # Incluye las claves foráneas
    
    # Opcional: Si quieres anidar los datos de la categoría
    categoria = fields.Nested("CategoriaSchema", only=("id", "nombre"))

# schemas.py
class CategoriaSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Categoria
        load_instance = True  # Para poder convertir directamente a objetos
        include_fk = True  # Incluir claves foráneas

# Instancias del esquema
categoria_schema = CategoriaSchema()
categorias_schema = CategoriaSchema(many=True)

class TallaSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Talla
        include_relationships = True
        load_instance = True



class MetodoPagoSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = MetodoPago
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
   


		
class CompraSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = Compra
        include_fk = True
        load_instance = True
        include_relationships = True

    usuario = fields.Nested("UsuarioSchema", only=("id", "nombre"))
    metodo_pago = fields.Nested("MetodoPagoSchema", only=("id", "tipo"))
    productos = fields.Method("obtener_productos")  # ← Campo que usa el método

    # ¡Método DEBE estar indentado dentro de la clase!
    def obtener_productos(self, obj):
        """Método para obtener los productos asociados a la compra con sus detalles"""
        productos_data = []
        
        for producto in obj.productos_compras:
            asociacion = db.session.query(compra_producto).filter_by(
                compra_id=obj.id,
                producto_id=producto.id
            ).first()
            
            if producto and asociacion:
                productos_data.append({
                    'id': producto.id,
                    'nombre': producto.nombre,
                    'precio_unitario': float(asociacion.precio_unitario),
                    'cantidad': asociacion.cantidad,
                    'subtotal': float(asociacion.precio_unitario * asociacion.cantidad),
                    'precio_actual': float(producto.precio)
                })
        return productos_data

class InventarioSchema(Schema):
    id = fields.Int(dump_only=True)
    id_producto = fields.Int(required=True)
    talla = fields.Str(
        required=True,
        validate=validate.OneOf(['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Única'])  # Ajusta según tus necesidades
    )
    stock = fields.Int(
        required=True,
        validate=validate.Range(min=0, error="El stock no puede ser negativo")
    )
    
    # Para incluir datos del producto al serializar
    producto_nombre = fields.Str(dump_only=True)
    producto_precio = fields.Float(dump_only=True)

class GeneroSchema(Schema):
    class Meta:
        model = Genero  # Relacionamos el schema con el modelo Genero
        fields = ("id", "nombre")  # Campos que se incluirán en el schema

ma = Marshmallow()

class HistorialStockSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = HistorialStock
        include_fk = True
    
    # Campos calculados
    producto_nombre = ma.String(attribute="inventario_relacion.producto.nombre", dump_only=True)
    talla_nombre = ma.String(attribute="inventario_relacion.talla.nombre", dump_only=True)
    usuario_nombre = ma.String(attribute="usuario_relacion.nombre", dump_only=True)
    producto_imagen = ma.String(attribute="inventario_relacion.producto.imagen_url", dump_only=True)

# Inicialización de los schemas
historial_stock_schema = HistorialStockSchema()
historial_stocks_schema = HistorialStockSchema(many=True)