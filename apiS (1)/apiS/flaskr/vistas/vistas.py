from datetime import datetime, timedelta
import secrets
import logging

from flask import request, jsonify
from flask_restful import Resource, reqparse
from flask_restful import Resource
from flask_jwt_extended import jwt_required, create_access_token, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.exceptions import BadRequest
from flask_mail import Message
from sqlalchemy import or_, func
from sqlalchemy.exc import IntegrityError
from ..extensiones import mail
from flaskr.modelos import CompraSchema

compra_schema = CompraSchema()
compras_schema = CompraSchema(many=True)
from flaskr.utils.email import enviar_correo
from flaskr.modelos import (
    db, Rol, Usuario, Carrito, CarritoProducto, Producto, Categoria, Talla,
    Pedido, MetodoPago, Factura, Reseña, DetalleFactura,
    UsuarioSchema, ProductoSchema, PedidoSchema, FacturaSchema, ReseñaSchema,
    MetodoPagoSchema, CarritoSchema, CarritoProductoSchema, CategoriaSchema,
    TallaSchema, DetalleFacturaSchema,  Compra, RolSchema, CompraSchema,

)

import logging


# Serializadores
usuario_schema = UsuarioSchema()
usuarios_schema = UsuarioSchema(many=True)
producto_schema = ProductoSchema()
productos_schema = ProductoSchema(many=True)
pedido_schema = PedidoSchema()
pedidos_schema = PedidoSchema(many=True)
reseña_schema = ReseñaSchema()
reseñas_schema = ReseñaSchema(many=True)

# ==================== Vistas Generales ==================== #

class VistaUsuarios(Resource):
    @jwt_required()
    def get(self):
        try:
            # Obtener el ID del usuario actual desde el token
            usuario_actual_id = get_jwt_identity()
            if not isinstance(usuario_actual_id, (str, int)):
                raise ValueError("El ID del usuario no es un formato válido.")

            logging.info(f"Usuario autenticado con ID: {usuario_actual_id}")

            # Consultar todos los usuarios en la base de datos
            usuarios = Usuario.query.all()

            if not usuarios:
                logging.info("No hay usuarios registrados en la base de datos.")
                return {"mensaje": "No hay usuarios registrados."}, 200

            logging.info(f"Usuarios encontrados: {len(usuarios)}")
            return usuarios_schema.dump(usuarios), 200
        except ValueError as ve:
            logging.error(f"Error en validación del token: {str(ve)}")
            return {"mensaje": str(ve)}, 422
        except Exception as e:
            logging.error(f"Error en VistaUsuarios.get: {str(e)}")
            return {"mensaje": "Error interno del servidor."}, 500

    @jwt_required()
    def post(self):
        try:
            # Crear un nuevo usuario con los datos proporcionados
            nuevo_usuario = Usuario(
                nombre=request.json['nombre'],
                email=request.json['email'],
                num_cel=request.json.get('num_cel', ''),
                direccion=request.json.get('direccion', ''),
                contrasena_hash=generate_password_hash(request.json['contrasena']),
                id_rol=request.json['id_rol'],
                estado=request.json.get('estado', 'Activo')
            )

            # Guardar el usuario en la base de datos
            db.session.add(nuevo_usuario)
            db.session.commit()

            logging.info(f"Usuario creado exitosamente: {nuevo_usuario.nombre}")
            return usuario_schema.dump(nuevo_usuario), 201
        except IntegrityError as e:
            db.session.rollback()
            logging.error(f"Error de integridad: {str(e)}")
            return {"mensaje": "Error al crear el usuario. Verifique los datos ingresados."}, 409
        except KeyError as e:
            logging.error(f"Falta el campo obligatorio: {str(e)}")
            return {"mensaje": f"Falta el campo obligatorio: {str(e)}."}, 400
        except Exception as e:
            logging.error(f"Error en VistaUsuarios.post: {str(e)}")
            return {"mensaje": "Error interno del servidor."}, 500




class VistaUsuario(Resource):
    @jwt_required()
    def get(self, id_usuario):
        try:
            usuario_actual_id = get_jwt_identity()
            if not usuario_actual_id:
                return {"mensaje": "Token inválido o no proporcionado."}, 401

            usuario = Usuario.query.get_or_404(id_usuario)
            return usuario_schema.dump(usuario), 200
        except Exception as e:
            logging.error(f"Error en VistaUsuario.get: {str(e)}")
            return {"mensaje": "Error interno del servidor."}, 500

    @jwt_required()
    def put(self, id_usuario):
        try:
            usuario_actual_id = get_jwt_identity()
            if not usuario_actual_id:
                return {"mensaje": "Token inválido o no proporcionado."}, 401

            usuario = Usuario.query.get_or_404(id_usuario)
            usuario.nombre = request.json.get("nombre", usuario.nombre)
            usuario.email = request.json.get("email", usuario.email)
            usuario.direccion = request.json.get("direccion", usuario.direccion)
            usuario.estado = request.json.get("estado", usuario.estado)
            db.session.commit()
            return usuario_schema.dump(usuario), 200
        except Exception as e:
            logging.error(f"Error en VistaUsuario.put: {str(e)}")
            return {"mensaje": "Error interno del servidor."}, 500

    @jwt_required()
    def delete(self, id_usuario):
        try:
            usuario_actual_id = get_jwt_identity()
            if not usuario_actual_id:
                return {"mensaje": "Token inválido o no proporcionado."}, 401

            usuario = Usuario.query.get_or_404(id_usuario)
            db.session.delete(usuario)
            db.session.commit()
            return '', 204
        except Exception as e:
            logging.error(f"Error en VistaUsuario.delete: {str(e)}")
            return {"mensaje": "Error interno del servidor."}, 500
        


class VistaProductos(Resource):
    def get(self):  
        search = request.args.get('search', '').lower().strip()
        categoria_nombre = request.args.get('categoria', '').lower().strip()

        query = Producto.query.join(Categoria)

        if search:
            query = query.filter(
                or_(
                    func.lower(Producto.nombre).contains(search),
                    func.lower(Producto.descripcion).contains(search),
                    func.lower(Categoria.nombre).contains(search)
                )
            )

        if categoria_nombre:
            query = query.filter(func.lower(Categoria.nombre).contains(categoria_nombre))

        productos = query.all()
        return productos_schema.dump(productos), 200

class VistaProducto(Resource):
    @jwt_required()
    def get(self, id_producto):
        producto = Producto.query.get(id_producto)
        if not producto:
            return {"error": "Producto no encontrado"}, 404
        return producto_schema.dump(producto), 200

    @jwt_required()
    def put(self, id_producto):
        data = request.json
        producto = Producto.query.get(id_producto)
        
        if not producto:
            return {"error": "Producto no encontrado"}, 404

        producto.nombre = data.get("nombre", producto.nombre)
        producto.descripcion = data.get("descripcion", producto.descripcion)
        producto.precio = data.get("precio", producto.precio)
        producto.estado = data.get("estado", producto.estado)
        producto.id_categoria = data.get("id_categoria", producto.id_categoria)

        try:
            db.session.commit()
            return producto_schema.dump(producto), 200
        except Exception as e:
            db.session.rollback()
            return {"error": str(e)}, 500

    @jwt_required()
    def delete(self, id_producto):
        producto = Producto.query.get(id_producto)

        if not producto:
            return {"error": "Producto no encontrado"}, 404

        try:
            db.session.delete(producto)
            db.session.commit()
            return {"mensaje": "Producto eliminado"}, 200
        except Exception as e:
            db.session.rollback()
            return {"error": str(e)}, 500

class VistaPedidos(Resource):
    @jwt_required()
    def get(self):
        pedidos = Pedido.query.all()
        return pedidos_schema.dump(pedidos), 200
# terminar mañana
class VistaPedido(Resource):
    @jwt_required()
    def get(self):
        pedidos = Pedido.query.all()
        resultado = []
        for pedido in pedidos:
            pedido_data = {
                "id": pedido.id,
                "fecha_pedido": pedido.fecha_pedido.strftime('%Y-%m-%d'),
                "total_pedido": float(pedido.total_pedido),  # Convertir a float para seguridad
                "direccion_envio": pedido.direccion_envio,
                "estado_pedido": pedido.estado_pedido,
                "id_usuario": pedido.id_usuario,  # Asegurar que envías el ID
                "id_metodo_pago": pedido.id_metodo_pago,  # Asegurar que envías el ID
                # Campos adicionales por si los necesitas
                "usuario_nombre": pedido.usuario.nombre if pedido.usuario else None,
                "metodo_pago_tipo": pedido.metodo_pago.tipo if pedido.metodo_pago else None
            }
            resultado.append(pedido_data)
        return resultado, 200

    @jwt_required()
    def put(self, id_pedido):
        pedido = Pedido.query.get_or_404(id_pedido)
        pedido.total_pedido = request.json.get("total_pedido", pedido.total_pedido)
        pedido.direccion_envio = request.json.get("direccion_envio", pedido.direccion_envio)
        pedido.estado_pedido = request.json.get("estado_pedido", pedido.estado_pedido)
        db.session.commit()
        return pedido_schema.dump(pedido), 200

    @jwt_required()
    def delete(self, id_pedido):
        pedido = Pedido.query.get_or_404(id_pedido)
        db.session.delete(pedido)
        db.session.commit()
        return '', 204

class VistaReseñas(Resource):
    def get(self):
        reseñas = Reseña.query.all()
        return reseñas_schema.dump(reseñas), 200
    



class VistaReseña(Resource):
    @jwt_required()
    def get(self, id_resena):
        """Obtener detalles de una reseña específica"""
        reseña = Reseña.query.get(id_resena)
        
        if not reseña:
            return {"error": "Reseña no encontrada"}, 404
        
        return reseña_schema.dump(reseña), 200

    @jwt_required()
    def put(self, id_resena):
        """Actualizar una reseña existente"""
        data = request.json
        reseña = Reseña.query.get(id_resena)

        if not reseña:
            return {"error": "Reseña no encontrada"}, 404
        
        # Actualizar los campos de la reseña
        reseña.comentario = data.get("comentario", reseña.comentario)
        reseña.calificacion = data.get("calificacion", reseña.calificacion)

        try:
            db.session.commit()
            return reseña_schema.dump(reseña), 200
        except Exception as e:
            db.session.rollback()
            return {"error": str(e)}, 500

    @jwt_required()
    def delete(self, id_resena):
        """Eliminar una reseña"""
        reseña = Reseña.query.get(id_resena)

        if not reseña:
            return {"error": "Reseña no encontrada"}, 404

        try:
            db.session.delete(reseña)
            db.session.commit()
            return {"mensaje": "Reseña eliminada correctamente"}, 200
        except Exception as e:
            db.session.rollback()
            return {"error": str(e)}, 500


# ==================== Vistas de Autenticación ==================== #
    
class VistaCrearUsuario(Resource):
    def post(self):
        data = request.json
        if not data:
            return {"mensaje": "El cuerpo de la solicitud está vacío o mal formado"}, 400

        nombre = data.get("nombre")
        email = data.get("email")
        contrasena = data.get("password")
        num_cel = data.get("num_cel")
        direccion = data.get("direccion")
        id_rol = data.get("id_rol", 2)
        estado = "Activo"

        if not nombre or not email or not contrasena or not num_cel:
            return {"mensaje": "Nombre, email, contraseña y número de celular son obligatorios."}, 400

        if Usuario.query.filter_by(email=email).first():
            return {"mensaje": "El email ya está registrado."}, 409

        rol = Rol.query.filter_by(id=id_rol).first()
        if not rol:
            return {"mensaje": f"El rol con ID {id_rol} no existe."}, 404

        nuevo_usuario = Usuario(
            nombre=nombre,
            email=email,
            num_cel=num_cel,
            contrasena_hash=generate_password_hash(contrasena),
            direccion=direccion,
            id_rol=id_rol,
            estado=estado
        )

        try:
            db.session.add(nuevo_usuario)
            db.session.commit()
            return {"mensaje": "Usuario registrado exitosamente."}, 201
        except IntegrityError as e:
            db.session.rollback()
            logging.error(f"Error de integridad: {str(e)}")
            return {"mensaje": "Error al registrar el usuario. Intenta nuevamente."}, 500





class VistaRegistroUsuarios(Resource):
    def post(self):
        data = request.json
        if not data:
            return {"mensaje": "El cuerpo de la solicitud está vacío o mal formado"}, 400

        return VistaCrearUsuario().post()






class VistaInicioSesion(Resource):
    def post(self):
        email = request.json.get("email")
        contrasena = request.json.get("password")

        usuario = Usuario.query.filter_by(email=email).first()

        if usuario and usuario.verificar_contrasena(contrasena):
            token = create_access_token(identity=str(usuario.id))
            mensaje = "Inicio de sesión exitoso"
            if usuario.id_rol == 1:
                mensaje += " como administrador"

            return {
                "mensaje": mensaje,
                "token": token,
                "usuario": {
                    "id": usuario.id,
                    "nombre": usuario.nombre,
                    "email": usuario.email,
                    "direccion": usuario.direccion
                }
            }, 200

        return {"mensaje": "Email o contraseña incorrectos"}, 401

    

from flask_cors import cross_origin

from flask_cors import cross_origin

class VistaCrearProducto(Resource):
    @cross_origin()
    def options(self):
        """Maneja las solicitudes OPTIONS para evitar errores CORS."""
        return {}, 200

    @jwt_required()  # Asegúrate de tener el token JWT al hacer la solicitud
    @cross_origin()
    def post(self):
        data = request.json

        # Verificar si los datos están presentes
        if not data:
            return {"error": "No se enviaron datos"}, 400

        # Validar campos obligatorios
        campos_requeridos = ["nombre", "precio", "id_categoria"]
        for campo in campos_requeridos:
            if campo not in data:
                return {"error": f"El campo '{campo}' es obligatorio"}, 400

        # Crear el nuevo producto
        nuevo_producto = Producto(
            nombre=data["nombre"],
            descripcion=data.get("descripcion", ""),  # Opcional
            precio=data["precio"],
            estado=data.get("estado", "Disponible"),
            id_categoria=data["id_categoria"],
        )

        try:
            db.session.add(nuevo_producto)
            db.session.commit()
            return producto_schema.dump(nuevo_producto), 201
        except Exception as e:
            db.session.rollback()
            return {"error": str(e)}, 500
        


        

    ## VISTA METODO DE PAGO##

class VistaMetodosPago(Resource):
    def get(self):
        metodos = MetodoPago.query.all()
        return jsonify([{"id": metodo.id, "tipo": metodo.tipo, "detalle": metodo.detalle} for metodo in metodos])
    

class VistaCrearPedido(Resource):
    @jwt_required()
    def post(self):
        data = request.json
        if not data:
            return {"mensaje": "El cuerpo de la solicitud está vacío o mal formado"}, 400

        # Campos obligatorios
        total_pedido = data.get("total_pedido")
        direccion_envio = data.get("direccion_envio")
        id_usuario = data.get("id_usuario")
        id_metodo_pago = data.get("id_metodo_pago")

        # Validación de campos obligatorios
        if None in [total_pedido, direccion_envio, id_usuario, id_metodo_pago]:
            return {"mensaje": "Total, dirección, usuario y método de pago son obligatorios"}, 400

        # Validar que el usuario existe
        if not Usuario.query.get(id_usuario):
            return {"mensaje": f"El usuario con ID {id_usuario} no existe"}, 404

        # Validar que el método de pago existe
        if not MetodoPago.query.get(id_metodo_pago):
            return {"mensaje": f"El método de pago con ID {id_metodo_pago} no existe"}, 404

        try:
            # Crear el nuevo pedido
            nuevo_pedido = Pedido(
                total_pedido=float(total_pedido),  # Convertir a float explícitamente
                direccion_envio=direccion_envio,
                id_usuario=id_usuario,
                id_metodo_pago=id_metodo_pago,
                estado_pedido=data.get("estado_pedido", "Procesado")
            )

            db.session.add(nuevo_pedido)
            db.session.commit()

            return {
                "mensaje": "Pedido creado exitosamente",
                "pedido": pedido_schema.dump(nuevo_pedido)  # Ahora está definido
            }, 201

        except ValueError as e:
            db.session.rollback()
            logging.error(f"Error de valor: {str(e)}")
            return {"mensaje": f"Error en los datos proporcionados: {str(e)}"}, 400

        except BadRequest as e:
            db.session.rollback()
            logging.error(f"Error en la solicitud: {str(e)}")
            return {"mensaje": "Los datos de la solicitud son inválidos"}, 400

        except Exception as e:
            db.session.rollback()
            logging.error(f"Error inesperado: {str(e)}")
            return {"mensaje": "Error al crear el pedido. Intenta nuevamente."}, 500
        

# RESEÑAS 
class VistaCrearReseña(Resource):
    def post(self, id_producto):
        """
        Crea una nueva reseña para un producto específico
        Parámetros:
        - id_producto: ID del producto a reseñar (en la URL)
        - Body JSON: { "comentario": string, "calificacion": int (1-5), "id_usuario": int }
        """
        try:
            # Verificar que el producto exista
            producto = Producto.query.get_or_404(id_producto)
            
            # Obtener datos del request
            datos = request.get_json()
            
            # Validación básica
            if not datos.get('comentario') or not datos.get('calificacion') or not datos.get('id_usuario'):
                return {"mensaje": "Comentario, calificación e ID de usuario son requeridos"}, 400
            
            if not 1 <= datos['calificacion'] <= 5:
                return {"mensaje": "La calificación debe ser entre 1 y 5"}, 400

            # Crear la reseña
            nueva_reseña = Reseña(
                comentario=datos['comentario'],
                calificacion=datos['calificacion'],
                id_producto=id_producto,
                id_usuario=datos['id_usuario']
            )
            
            db.session.add(nueva_reseña)
            db.session.commit()
            
            return {
                "mensaje": "Reseña creada exitosamente",
                "reseña": {
                    "id": nueva_reseña.id,
                    "producto": producto.nombre,
                    "calificacion": nueva_reseña.calificacion,
                    "comentario": nueva_reseña.comentario
                }
            }, 201
            
        except Exception as e:
            db.session.rollback()
            print("Error al crear reseña:", str(e))
            return {
                "mensaje": "Error al crear la reseña",
                "error": str(e)
            }, 500


class VistaReseñasProducto(Resource):
    def get(self, id_producto):
        # Verificar si el producto existe
        if not Producto.query.get(id_producto):
            return {"mensaje": "Producto no encontrado"}, 404
            
        # Obtener reseñas filtradas por id_producto
        reseñas = Reseña.query.filter_by(id_producto=id_producto).all()
        
        return reseñas_schema.dump(reseñas), 200




        

# 💌 Recuperación de contraseña
class VistaForgotPassword(Resource):
    def post(self):
        email = request.json.get('email')
        usuario = Usuario.query.filter_by(email=email).first()
        if not usuario:
            return {'mensaje': 'El correo no está registrado.'}, 404

        token = secrets.token_urlsafe(32)
        usuario.reset_token = token
        usuario.reset_token_expiration = datetime.utcnow() + timedelta(hours=1)
        db.session.commit()

        enlace = f"http://localhost:5173/ResetPasswordPage/{token}"
        mensaje = Message('Recuperación de contraseña',
                          recipients=[email])
        mensaje.body = f"""🎮 ¡Hola {usuario.nombre}!

¿Olvidaste tu contraseña? No hay problema 👗✨

Hemos recibido una solicitud para restablecer tu contraseña en Stay In Style.

Aquí tienes tu enlace seguro para crear una nueva contraseña:
{enlace}

Este enlace estará activo durante 1 hora.

Gracias por seguir marcando tendencia con nosotros.
— Con estilo, el equipo de Stay In Style 💫
"""


        mail.send(mensaje)
        return {'mensaje': 'Correo de recuperación enviado.'}, 200
class VistaResetPassword(Resource):
    def post(self, token):
        nueva_contrasena = request.json.get('contrasena')
        usuario = Usuario.query.filter_by(reset_token=token).first()
        if not usuario:
            return {'mensaje': 'Token inválido o expirado'}, 400

        usuario.contrasena = nueva_contrasena
        usuario.reset_token = None
        usuario.reset_token_expiration = None
        db.session.commit()
        return {'mensaje': 'Contraseña actualizada con éxito.'}, 200
     
# 🧍‍♂️ Enviar a un solo destinatario (requiere campo 'destinatario')
class VistaNotificarAdmin(Resource):
    def post(self):
        data = request.get_json()
        asunto = data.get("asunto", "Notificación desde Pixel Store")
        mensaje = data.get("mensaje", "Este es un mensaje predeterminado para los usuarios.")
        destinatario = data.get("destinatario", None)

        if not destinatario:
            return {"error": "Debes proporcionar un destinatario."}, 400

        try:
            enviar_correo(destinatario, asunto, mensaje)
            return {"mensaje": "Correo enviado correctamente a un usuario."}, 200
        except Exception as e:
            return {"error": str(e)}, 500


# 👥 Enviar a todos los usuarios
class VistaNotificarTodos(Resource):
    def post(self):
        data = request.get_json()
        asunto = data.get("asunto", "Notificación para todos desde Pixel Store")
        mensaje = data.get("mensaje", "Este es un mensaje general para todos los usuarios.")

        try:
            usuarios = Usuario.query.with_entities(Usuario.email).all()
            enviados = 0
            for usuario in usuarios:
                if usuario.email:
                    enviar_correo(usuario.email, asunto, mensaje)
                    enviados += 1
            return {"mensaje": f"Correos enviados a {enviados} usuarios."}, 200
        except Exception as e:
            return {"error": str(e)}, 500
        


class VistaCrearCompra(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument('barrio', type=str, required=True, help='El campo barrio es obligatorio')
        parser.add_argument('observaciones', type=str)
        parser.add_argument('usuario_id', type=int, required=True, help='El campo usuario_id es obligatorio')
        parser.add_argument('metodo_pago_id', type=int, required=True, help='El campo metodo_pago_id es obligatorio')

        datos = parser.parse_args()

        # Verificamos que el usuario y el método de pago existan
        usuario = Usuario.query.get(datos['usuario_id'])
        metodo_pago = MetodoPago.query.get(datos['metodo_pago_id'])

        if not usuario:
            return {'mensaje': 'Usuario no encontrado'}, 404

        if not metodo_pago:
            return {'mensaje': 'Método de pago no encontrado'}, 404

        nueva_compra = Compra(
            barrio=datos['barrio'],
            observaciones=datos.get('observaciones'),
            usuario_id=datos['usuario_id'],
            metodo_pago_id=datos['metodo_pago_id']
        )

        db.session.add(nueva_compra)
        db.session.commit()

        return {
            'mensaje': 'Compra registrada exitosamente',
            'id': nueva_compra.id
        }, 201

class VistaCompras(Resource):
    def get(self):
        """Obtiene todas las compras con filtros opcionales"""
        usuario_id = request.args.get('usuario_id')
        estado = request.args.get('estado')
        barrio = request.args.get('barrio')
        
        query = Compra.query
        
        if usuario_id:
            query = query.filter_by(usuario_id=usuario_id)
        if estado:
            query = query.filter_by(estado_pedido=estado)
        if barrio:
            query = query.filter(Compra.barrio.ilike(f'%{barrio}%'))
            
        compras = query.order_by(Compra.fecha_compra.desc()).all()
        return compras_schema.dump(compras), 200


class VistaCompra(Resource):
    def post(self):
        """Crea una nueva compra"""
        data = request.get_json()
        
        if not data:
            return {'mensaje': 'No se proporcionaron datos'}, 400

        campos_requeridos = ['barrio', 'usuario_id', 'metodo_pago_id']
        faltantes = [campo for campo in campos_requeridos if campo not in data]

        if faltantes:
            return {'mensaje': f'Faltan campos obligatorios: {", ".join(faltantes)}'}, 400

        if not Usuario.query.get(data['usuario_id']):
            return {'mensaje': 'Usuario no encontrado'}, 404
        if not MetodoPago.query.get(data['metodo_pago_id']):
            return {'mensaje': 'Método de pago no encontrado'}, 404

        try:
            nueva_compra = Compra(
                barrio=data['barrio'],
                observaciones=data.get('observaciones'),
                usuario_id=data['usuario_id'],
                metodo_pago_id=data['metodo_pago_id'],
                estado_pedido=data.get('estado_pedido', 'Procesado')
            )
            db.session.add(nueva_compra)
            db.session.commit()
            return compra_schema.dump(nueva_compra), 201
        except Exception as e:
            db.session.rollback()
            return {'mensaje': f'Error al crear la compra: {str(e)}'}, 500

    def get(self, id_compra):
        """Obtiene una compra específica por ID"""
        compra = Compra.query.get_or_404(id_compra)
        return compra_schema.dump(compra), 200

    def put(self, id_compra):
        """Actualiza una compra existente"""
        compra = Compra.query.get_or_404(id_compra)
        data = request.get_json()
        
        if not data:
            return {'mensaje': 'No se proporcionaron datos para actualizar'}, 400

        campos_actualizables = ['barrio', 'observaciones', 'estado_pedido']
        for campo in campos_actualizables:
            if campo in data:
                setattr(compra, campo, data[campo])
        
        if 'usuario_id' in data:
            if not Usuario.query.get(data['usuario_id']):
                return {'mensaje': 'Usuario no encontrado'}, 404
            compra.usuario_id = data['usuario_id']
            
        if 'metodo_pago_id' in data:
            if not MetodoPago.query.get(data['metodo_pago_id']):
                return {'mensaje': 'Método de pago no encontrado'}, 404
            compra.metodo_pago_id = data['metodo_pago_id']

        try:
            db.session.commit()
            return compra_schema.dump(compra), 200
        except Exception as e:
            db.session.rollback()
            return {'mensaje': f'Error al actualizar la compra: {str(e)}'}, 500

    def delete(self, id_compra):
        """Elimina una compra"""
        compra = Compra.query.get_or_404(id_compra)
        try:
            db.session.delete(compra)
            db.session.commit()
            return {'mensaje': 'Compra eliminada exitosamente'}, 204
        except Exception as e:
            db.session.rollback()
            return {'mensaje': f'Error al eliminar la compra: {str(e)}'}, 500


class VistaComprasUsuario(Resource):
    def get(self, id_usuario):
        """Obtiene todas las compras de un usuario específico"""
        compras = Compra.query.filter_by(usuario_id=id_usuario).all()
        return compras_schema.dump(compras), 200
