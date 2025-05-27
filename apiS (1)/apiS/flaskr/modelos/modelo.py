from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

# Inicialización de la base de datos
db = SQLAlchemy()

# Modelo de Roles
class Rol(db.Model):  # Nombre correcto de la tablaf
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
    # AÑADE ESTA NUEVA RELACIÓN (es necesaria)
    historiales_stock = db.relationship('HistorialStock', back_populates='usuario_relacion')

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


class Carrito(db.Model):
    __tablename__ = 'carritos'
    id = db.Column(db.Integer, primary_key=True)
    total = db.Column(db.Float, default=0.0)
    estado = db.Column(db.String(20), default="Abierto")
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id'))
    fecha_creacion = db.Column(db.DateTime, server_default=db.func.now())
    fecha_actualizacion = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())
    usuario = db.relationship('Usuario', backref='carritos')

# Modelo de CarritoProducto
class CarritoProducto(db.Model):
    __tablename__ = 'carrito_productos'
    
    id = db.Column(db.Integer, primary_key=True)
    id_carrito = db.Column(db.Integer, db.ForeignKey('carritos.id'))
    id_producto = db.Column(db.Integer, db.ForeignKey('productos.id'))
    id_talla = db.Column(db.Integer, db.ForeignKey('tallas.id'), nullable=False)
    cantidad = db.Column(db.Integer, nullable=False)
    subtotal = db.Column(db.Float, nullable=False)

    carrito = db.relationship('Carrito', backref='productos')
    producto = db.relationship('Producto', backref='en_carritos')
    talla = db.relationship('Talla', backref='en_carritos')


# Modelo de Producto
class Producto(db.Model):
    __tablename__ = 'productos'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    descripcion = db.Column(db.Text)
    precio = db.Column(db.Float, nullable=False)
    estado = db.Column(db.String(10), default="Disponible")
    imagen_url = db.Column(db.String(500), nullable=True)
    
    id_categoria = db.Column(db.Integer, db.ForeignKey('categorias.id'))
    id_genero = db.Column(db.Integer, db.ForeignKey('genero.id'))  # Nueva FK a Genero

    genero = db.relationship('Genero', backref='productos')  # Relación con Genero

    @property
    def stock_total(self):
        return sum(inv.stock for inv in self.inventarios)

    def tiene_stock(self, id_talla, cantidad=1):
        inventario = next(
            (inv for inv in self.inventarios if inv.id_talla == id_talla), 
            None
        )
        return inventario and inventario.stock >= cantidad
    @property
    def disponible(self):
        """Determina si el producto está disponible (alguna talla tiene stock)"""
        return any(inv.stock > 0 for inv in self.inventarios)

    def actualizar_estado(self):
        """Actualiza el estado del producto basado en el stock"""
        if not self.disponible:
            self.estado = "Agotado"
        else:
            self.estado = "Disponible"
        db.session.commit()


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

    def __repr__(self):
        return f'<Talla {self.nombre}>'




# Modelo de Método de Pago
class MetodoPago(db.Model):
    __tablename__ = 'metodos_pago'
    id = db.Column(db.Integer, primary_key=True)
    tipo = db.Column(db.String(50), nullable=False)
    detalle = db.Column(db.Text)



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
    db.Column('cantidad', db.Integer, nullable=False),
    db.Column('id_talla', db.Integer)  # ✅ Aquí la agregas
)


# VAMOS A CREAR LA TABLA DE STOCK 


class Inventario(db.Model):
    __tablename__ = 'inventario'
    
    id = db.Column(db.Integer, primary_key=True)
    id_producto = db.Column(db.Integer, db.ForeignKey('productos.id'), nullable=False)
    id_talla = db.Column(db.Integer, db.ForeignKey('tallas.id'), nullable=False)
    stock = db.Column(db.Integer, default=0, nullable=False)

    producto = db.relationship('Producto', backref='inventarios')
    talla = db.relationship('Talla', backref='inventarios')
        # AÑADE ESTA NUEVA RELACIÓN (es necesaria)
    historiales = db.relationship('HistorialStock', back_populates='inventario_relacion')
    
    def __repr__(self):
        return f'<Inventario {self.id_producto} - TallaID: {self.id_talla} - Stock: {self.stock}>'


class Genero(db.Model):
        __tablename__ = 'genero'  # Nombre de la tabla en la base de datos
        
        id = db.Column(db.Integer, primary_key=True)  # ID autoincremental
        nombre = db.Column(db.String(100), nullable=False, unique=True)  # Nombre del género (único)

        def __repr__(self):
            return f'<Genero {self.nombre}>'


class HistorialStock(db.Model):
    __tablename__ = 'historial_stock'
    
    id = db.Column(db.Integer, primary_key=True)
    id_inventario = db.Column(db.Integer, db.ForeignKey('inventario.id'), nullable=False)
    id_producto = db.Column(db.Integer, db.ForeignKey('productos.id'), nullable=False)
    id_talla = db.Column(db.Integer, db.ForeignKey('tallas.id'), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    stock_anterior = db.Column(db.Integer, nullable=False)
    stock_nuevo = db.Column(db.Integer, nullable=False)
    diferencia = db.Column(db.Integer, nullable=False)
    fecha_cambio = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    motivo = db.Column(db.String(100))
    
    # Relaciones
    inventario_relacion = db.relationship('Inventario', back_populates='historiales')
    producto_relacion = db.relationship('Producto')
    talla_relacion = db.relationship('Talla')
    usuario_relacion = db.relationship('Usuario', back_populates='historiales_stock')
    
    def __init__(self, **kwargs):
        super(HistorialStock, self).__init__(**kwargs)
        self.diferencia = self.stock_nuevo - self.stock_anterior
        
        # Obtener id_producto e id_talla del inventario si no se proporcionan
        if not hasattr(self, 'id_producto') and self.inventario_relacion:
            self.id_producto = self.inventario_relacion.id_producto
        if not hasattr(self, 'id_talla') and self.inventario_relacion:
            self.id_talla = self.inventario_relacion.id_talla