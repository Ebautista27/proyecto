from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

# Inicialización de la base de datos
db = SQLAlchemy()

# Modelo de Roles
class Rol(db.Model):  # Nombre correcto de la tabla
    __tablename__ = 'roles'  # Asegúrate de que coincide con el nombre de la tabla en la base de datos
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(50), unique=True, nullable=False)


# Modelo de Usuarios
class Usuario(db.Model):
    __tablename__ = 'usuarios'

    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(50), nullable=False)
    email = db.Column(db.String(50), unique=True, nullable=False)
    num_cel = db.Column(db.String(50), nullable=True)
    direccion = db.Column(db.String(100), nullable=True)
    contrasena_hash = db.Column(db.String(255), nullable=False)
    id_rol = db.Column(db.Integer, db.ForeignKey('roles.id'), nullable=False)
    estado = db.Column(db.String(20), default="Activo")
    rol = db.relationship('Rol', backref='usuarios')

        # 💖 Campo para recuperación de contraseña
    reset_token = db.Column(db.String(100), nullable=True)
    # Propiedad para manejar contraseñas seguras
    @property
    def contrasena(self):
        raise AttributeError("La contraseña no es un atributo legible.")

    @contrasena.setter
    def contrasena(self, password):
        if not password:
            raise ValueError("La contraseña no puede estar vacía.")
        self.contrasena_hash = generate_password_hash(password)

    def verificar_contrasena(self, password):
        return check_password_hash(self.contrasena_hash, password)


# Modelo de Carrito
class Carrito(db.Model):
    __tablename__ = 'carritos'
    id = db.Column(db.Integer, primary_key=True)
    total = db.Column(db.Float, default=0.0)
    estado = db.Column(db.String(20), default="Abierto")
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id'))
    usuario = db.relationship('Usuario', backref='carritos')

# Modelo de CarritoProducto
class CarritoProducto(db.Model):
    __tablename__ = 'carrito_productos'
    id = db.Column(db.Integer, primary_key=True)
    id_carrito = db.Column(db.Integer, db.ForeignKey('carritos.id'))
    id_producto = db.Column(db.Integer, db.ForeignKey('productos.id'))
    cantidad = db.Column(db.Integer, nullable=False)
    subtotal = db.Column(db.Float, nullable=False)

    carrito = db.relationship('Carrito', backref='productos')
    producto = db.relationship('Producto', backref='en_carritos')

# Modelo de Producto
class Producto(db.Model):
    __tablename__ = 'productos'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    descripcion = db.Column(db.Text)
    precio = db.Column(db.Float, nullable=False)
    estado = db.Column(db.String(10), default="Disponible")
    imagen = db.Column(db.String(255))  # Aquí se guarda la ruta o nombre del archivo

    # Clave foránea a la tabla categorias
    id_categoria = db.Column(db.Integer, db.ForeignKey('categorias.id'))

# Modelo de Categoría
class Categoria(db.Model):
    __tablename__ = 'categorias'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)

    # Relación con Producto (uno a muchos)
    productos = db.relationship('Producto', backref='categoria', lazy=True)

# Modelo de Talla
class Talla(db.Model):
    __tablename__ = 'tallas'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(150), nullable=False)
    categoria_talla = db.Column(db.String(50))

# Modelo de Pedido
class Pedido(db.Model):
    __tablename__ = 'pedidos'
    id = db.Column(db.Integer, primary_key=True)
    fecha_pedido = db.Column(db.Date, default=db.func.current_date())
    estado_pedido = db.Column(db.String(50), default="Procesado")
    total_pedido = db.Column(db.Float, nullable=False)  # Cambio a Float
    direccion_envio = db.Column(db.String(100), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id'))
    id_metodo_pago = db.Column(db.Integer, db.ForeignKey('metodos_pago.id'))

    usuario = db.relationship('Usuario', backref='pedidos')
    metodo_pago = db.relationship('MetodoPago', backref='pedidos')

# Modelo de Método de Pago
class MetodoPago(db.Model):
    __tablename__ = 'metodos_pago'
    id = db.Column(db.Integer, primary_key=True)
    tipo = db.Column(db.String(50), nullable=False)
    detalle = db.Column(db.Text)

# Modelo de Factura
class Factura(db.Model):
    __tablename__ = 'facturas'
    id = db.Column(db.Integer, primary_key=True)
    id_pedido = db.Column(db.Integer, db.ForeignKey('pedidos.id'))
    monto_total = db.Column(db.Float, nullable=False)  # Cambio a Float)
    fecha_emision = db.Column(db.DateTime, default=db.func.current_timestamp())
    estado = db.Column(db.String(20), default="Pagado")

    pedido = db.relationship('Pedido', backref='factura')

# Modelo de Reseña
class Reseña(db.Model):
    __tablename__ = 'reseñas'
    id = db.Column(db.Integer, primary_key=True)
    comentario = db.Column(db.String(150), nullable=False)
    calificacion = db.Column(db.Integer, nullable=False)
    id_producto = db.Column(db.Integer, db.ForeignKey('productos.id'))
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id'))
    
    # Relaciones
    producto = db.relationship('Producto', backref='reseñas')
    usuario = db.relationship('Usuario', backref='reseñas')


# Modelo de DetalleFactura
class DetalleFactura(db.Model):
    __tablename__ = 'detalle_facturas'
    id = db.Column(db.Integer, primary_key=True)
    id_factura = db.Column(db.Integer, db.ForeignKey('facturas.id'))
    id_producto = db.Column(db.Integer, db.ForeignKey('productos.id'))
    cantidad = db.Column(db.Integer, nullable=False)

    factura = db.relationship('Factura', backref='detalles')
    producto = db.relationship('Producto', backref='detalles_factura')


class Compra(db.Model):
    __tablename__ = 'compras'

    id = db.Column(db.Integer, primary_key=True)
    barrio = db.Column(db.String(100), nullable=False)
    observaciones = db.Column(db.Text, nullable=True)
    fecha_compra = db.Column(db.DateTime, default=datetime.utcnow)

    # Relación con Usuario
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    usuario = db.relationship('Usuario', backref=db.backref('compras', lazy=True))

    # Relación con Método de Pago
    metodo_pago_id = db.Column(db.Integer, db.ForeignKey('metodos_pago.id'), nullable=False)
    metodo_pago = db.relationship('MetodoPago', backref=db.backref('compras', lazy=True))

    # Estado de la compra
    estado_pedido = db.Column(db.String(50), default="Procesado")

    # Relación con productos a través de una tabla intermedia
    productos_compras = db.relationship('Producto', secondary='compra_producto', backref='compras')

# Tabla intermedia para la relación muchos a muchos entre Compra y Producto
compra_producto = db.Table('compra_producto',
    db.Column('compra_id', db.Integer, db.ForeignKey('compras.id'), primary_key=True),
    db.Column('producto_id', db.Integer, db.ForeignKey('productos.id'), primary_key=True),
    db.Column('precio_unitario', db.Float, nullable=False),
    db.Column('cantidad', db.Integer, nullable=False)
)
