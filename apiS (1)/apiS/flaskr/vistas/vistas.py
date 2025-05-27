from datetime import datetime, timedelta
import secrets
import logging
from sqlalchemy.orm import joinedload

from flask import current_app  # Importa current_app
import cloudinary.uploader
from flask import request, jsonify
from flaskr.config import Config
from flask_restful import Resource, reqparse
from flask_restful import Resource
from flask_jwt_extended import jwt_required, create_access_token, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.exceptions import BadRequest
from flask_cors import cross_origin
from flask_mail import Message
from flask import current_app  # Para el logging

from sqlalchemy import or_, func
from sqlalchemy import extract 
from sqlalchemy.exc import IntegrityError
from ..extensiones import mail
from flaskr.modelos import CompraSchema
from flaskr.modelos.esquema import roles_schema
from flaskr.modelos.esquema import historial_stock_schema, historial_stocks_schema


compra_schema = CompraSchema()
compras_schema = CompraSchema(many=True)
from flaskr.utils.email import enviar_correo
from flaskr.modelos import (
    db, Rol, Usuario, Carrito, CarritoProducto, Producto, Categoria, Talla,Genero,
     MetodoPago,  Reseña,  compra_producto,Inventario,InventarioSchema,
    UsuarioSchema, ProductoSchema,   ReseñaSchema,
    MetodoPagoSchema, CarritoSchema, CarritoProductoSchema, CategoriaSchema,
    TallaSchema, Compra, RolSchema, CompraSchema,GeneroSchema,HistorialStock,HistorialStock

)

import logging

# Instancias de los esquemas
categoria_schema = CategoriaSchema()
categorias_schema = CategoriaSchema(many=True)

# Serializadores
usuario_schema = UsuarioSchema()
usuarios_schema = UsuarioSchema(many=True)
producto_schema = ProductoSchema()
productos_schema = ProductoSchema(many=True)
reseña_schema = ReseñaSchema()
reseñas_schema = ReseñaSchema(many=True)

# ==================== Vistas Generales ==================== #

# Configuración para guardar imágenes (agrega esto en tu configuración)
UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

class VistaUsuarios(Resource):
    @jwt_required()
    def get(self):
        try:
            # Obtener el ID del usuario actual desde el token
            usuario_actual_id = get_jwt_identity()
            if not isinstance(usuario_actual_id, (str, int)):
                raise ValueError("El ID del usuario no es un formato válido.")

            logging.info(f"Usuario autenticado con ID: {usuario_actual_id}")

            # Consultar todos los usuarios con join al rol
            usuarios = Usuario.query.options(db.joinedload(Usuario.rol)).all()

            if not usuarios:
                logging.info("No hay usuarios registrados en la base de datos.")
                return {"mensaje": "No hay usuarios registrados."}, 200

            # Serializar los datos manualmente para mayor control
            usuarios_data = []
            for usuario in usuarios:
                usuario_dict = {
                    "id": usuario.id,
                    "nombre": usuario.nombre,
                    "email": usuario.email,
                    "num_cel": usuario.num_cel,
                    "direccion": usuario.direccion,
                    "id_rol": usuario.id_rol,
                    "rol_nombre": usuario.rol.nombre if usuario.rol else "Sin rol",
                    "estado": usuario.estado,
                    "fecha_creacion": usuario.fecha_creacion.isoformat() if hasattr(usuario, 'fecha_creacion') else None
                }
                
                # Excluir campos sensibles
                if hasattr(usuario, 'contrasena_hash'):
                    usuario_dict["contrasena_hash"] = "[PROTEGIDO]"
                if hasattr(usuario, 'reset_token'):
                    usuario_dict["reset_token"] = "[PROTEGIDO]" if usuario.reset_token else None
                
                usuarios_data.append(usuario_dict)

            logging.info(f"Usuarios encontrados: {len(usuarios)}")
            return {
                "mensaje": "Usuarios obtenidos correctamente",
                "usuarios": usuarios_data,
                "total": len(usuarios)
            }, 200

        except ValueError as ve:
            logging.error(f"Error en validación del token: {str(ve)}")
            return {"mensaje": str(ve)}, 422
        except SQLAlchemyError as sae:
            db.session.rollback()
            logging.error(f"Error de base de datos: {str(sae)}")
            return {"mensaje": "Error al consultar los usuarios"}, 500
        except Exception as e:
            logging.error(f"Error inesperado: {str(e)}", exc_info=True)
            return {"mensaje": "Error interno del servidor"}, 500

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
            # Verificar autenticación
            usuario_actual_id = get_jwt_identity()
            if not usuario_actual_id:
                return {"mensaje": "Token inválido o no proporcionado"}, 401

            # Obtener usuario con información del rol
            usuario = Usuario.query.options(db.joinedload(Usuario.rol)).get_or_404(id_usuario)
            
            # Preparar respuesta con datos extendidos
            usuario_data = usuario_schema.dump(usuario)
            usuario_data['rol_nombre'] = usuario.rol.nombre if usuario.rol else None
            
            return usuario_data, 200
            
        except Exception as e:
            current_app.logger.error(f"Error en VistaUsuario.get: {str(e)}")
            return {"mensaje": "Error al obtener información del usuario"}, 500

    @jwt_required()
    def put(self, id_usuario):
        try:
            # 1. Verificar autenticación
            usuario_actual_id = get_jwt_identity()
            if not usuario_actual_id:
                return {"mensaje": "Token inválido o no proporcionado"}, 401

            # 2. Validar datos de entrada
            data = request.get_json()
            if not data:
                return {"mensaje": "No se proporcionaron datos para actualizar"}, 400

            # 3. Obtener usuario a actualizar con su rol
            usuario = Usuario.query.options(db.joinedload(Usuario.rol)).get_or_404(id_usuario)
            
            # 4. Actualizar campos básicos con validaciones
            if 'nombre' in data:
                usuario.nombre = data['nombre'].strip() if data['nombre'] else usuario.nombre
            
            if 'email' in data:
                new_email = data['email'].strip().lower()
                if new_email and new_email != usuario.email:
                    # Validar formato de email
                    if '@' not in new_email or '.' not in new_email.split('@')[-1]:
                        return {"mensaje": "Formato de email inválido"}, 400
                    # Verificar unicidad
                    if Usuario.query.filter(Usuario.email == new_email, Usuario.id != id_usuario).first():
                        return {"mensaje": "El email ya está registrado"}, 400
                    usuario.email = new_email
            
            if 'num_cel' in data:
                usuario.num_cel = data['num_cel'].strip() if data['num_cel'] else None
            
            if 'direccion' in data:
                usuario.direccion = data['direccion'].strip() if data['direccion'] else None
            
            if 'estado' in data and data['estado'] in ['Activo', 'Inactivo']:
                usuario.estado = data['estado']
            
            # 5. Manejo de roles
            if 'id_rol' in data:
                try:
                    id_rol = int(data['id_rol'])
                    rol = Rol.query.get(id_rol)
                    if not rol:
                        return {"mensaje": "El rol especificado no existe"}, 400
                    usuario.id_rol = id_rol
                except (ValueError, TypeError):
                    return {"mensaje": "ID de rol inválido"}, 400
            
            # 6. Manejo de contraseña
            if 'contrasena' in data and data['contrasena']:
                if len(data['contrasena']) < 6:
                    return {"mensaje": "La contraseña debe tener al menos 6 caracteres"}, 400
                usuario.contrasena = data['contrasena']  # El setter hashea la contraseña
            
            # 7. Guardar cambios
            db.session.commit()
            
            # 8. Preparar respuesta
            response_data = usuario_schema.dump(usuario)
            response_data['rol_nombre'] = usuario.rol.nombre if usuario.rol else None
            
            return {
                "mensaje": "Usuario actualizado correctamente",
                "usuario": response_data
            }, 200
            
        except SQLAlchemyError as e:
            db.session.rollback()
            current_app.logger.error(f"Error de base de datos: {str(e)}")
            return {"mensaje": "Error al actualizar el usuario en la base de datos"}, 500
        except Exception as e:
            current_app.logger.error(f"Error inesperado: {str(e)}")
            return {"mensaje": "Error interno del servidor"}, 500

    @jwt_required()
    def delete(self, id_usuario):
        try:
            # 1. Verificar autenticación
            usuario_actual_id = get_jwt_identity()
            if not usuario_actual_id:
                return {"mensaje": "Token inválido o no proporcionado"}, 401

            # 2. Verificar que el usuario no se esté eliminando a sí mismo
            if str(usuario_actual_id) == str(id_usuario):
                return {"mensaje": "No puedes eliminar tu propio usuario"}, 400

            # 3. Obtener y eliminar usuario
            usuario = Usuario.query.get_or_404(id_usuario)
            db.session.delete(usuario)
            db.session.commit()
            
            return '', 204
            
        except SQLAlchemyError as e:
            db.session.rollback()
            current_app.logger.error(f"Error de base de datos: {str(e)}")
            return {"mensaje": "Error al eliminar el usuario"}, 500
        except Exception as e:
            current_app.logger.error(f"Error inesperado: {str(e)}")
            return {"mensaje": "Error interno del servidor"}, 500


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
    @cross_origin()
    def options(self):
        return {'message': 'OK'}, 200

    @cross_origin()
    def get(self, id_producto):
        """Obtener un producto específico"""
        producto = Producto.query.get_or_404(id_producto)
        producto_data = producto_schema.dump(producto)
        
        # Añadir información adicional
        producto_data['disponible'] = producto.disponible
        producto_data['stock_total'] = producto.stock_total
        
        return producto_data, 200

    @cross_origin()
    def put(self, id_producto):
        """Actualizar producto existente"""
        try:
            Config.init_cloudinary()
            producto = Producto.query.get_or_404(id_producto)
            
            # Manejar datos del formulario (incluyendo imagen)
            data = request.form
            imagen = request.files.get('imagen')

            # Validar campos requeridos
            campos_requeridos = ['nombre', 'precio', 'id_categoria']
            for campo in campos_requeridos:
                if campo not in data or not data[campo].strip():
                    return {'error': f'El campo {campo} es requerido'}, 400

            # Actualizar campos básicos
            producto.nombre = data['nombre'].strip()
            producto.descripcion = data.get('descripcion', '').strip()
            producto.precio = float(data['precio'])
            producto.id_categoria = int(data['id_categoria'])
            
            # El estado ahora se maneja automáticamente, no se permite actualización manual
            producto.actualizar_estado()

            # Manejar imagen si se proporciona una nueva
            if imagen and imagen.filename:
                if producto.imagen_url:
                    try:
                        public_id = producto.imagen_url.split('/')[-1].split('.')[0]
                        cloudinary.uploader.destroy(f"productos/{public_id}")
                    except Exception as e:
                        print(f"Error eliminando imagen anterior: {str(e)}")
                
                upload_result = cloudinary.uploader.upload(
                    imagen,
                    folder='productos',
                    allowed_formats=['jpg', 'png', 'jpeg', 'webp'],
                    quality='auto:good',
                    width=800,
                    crop='limit'
                )
                producto.imagen_url = upload_result['secure_url']

            db.session.commit()
            
            # Devolver datos actualizados con disponibilidad
            producto_data = producto_schema.dump(producto)
            producto_data['disponible'] = producto.disponible
            producto_data['stock_total'] = producto.stock_total
            
            return producto_data, 200

        except ValueError as e:
            db.session.rollback()
            return {'error': f'Error en los datos: {str(e)}'}, 400
        except Exception as e:
            db.session.rollback()
            return {'error': f'Error al actualizar el producto: {str(e)}'}, 500

    @cross_origin()
    def delete(self, id_producto):
        """Eliminar producto"""
        try:
            producto = Producto.query.get_or_404(id_producto)
            
            if producto.imagen_url:
                Config.init_cloudinary()
                try:
                    public_id = producto.imagen_url.split('/')[-1].split('.')[0]
                    cloudinary.uploader.destroy(f"productos/{public_id}")
                except Exception as e:
                    print(f"Error eliminando imagen de Cloudinary: {str(e)}")
            
            db.session.delete(producto)
            db.session.commit()
            return {'mensaje': 'Producto eliminado correctamente'}, 200
            
        except Exception as e:
            db.session.rollback()
            return {'error': str(e)}, 500

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

   

producto_schema = ProductoSchema()

class VistaCrearProducto(Resource):
    @cross_origin()
    def options(self):
        """Maneja solicitudes OPTIONS para CORS"""
        return {'message': 'OK'}, 200

    @cross_origin()
    def post(self):
        """
        Crea un nuevo producto con imagen en Cloudinary
        ---
        tags:
          - Productos
        consumes:
          - multipart/form-data
        parameters:
          - in: formData
            name: nombre
            type: string
            required: true
          - in: formData
            name: descripcion
            type: string
            required: false
          - in: formData
            name: precio
            type: number
            required: true
          - in: formData
            name: estado
            type: string
            enum: [Disponible, No Disponible, Agotado]
            default: Disponible
          - in: formData
            name: id_categoria
            type: integer
            required: true
          - in: formData
            name: id_genero
            type: integer
            required: true
          - in: formData
            name: imagen
            type: file
            required: true
        responses:
          201:
            description: Producto creado exitosamente
          400:
            description: Datos faltantes o inválidos
          404:
            description: Categoría o Género no encontrado
          500:
            description: Error del servidor
        """
        try:
            # Inicializar Cloudinary
            Config.init_cloudinary()
            
            # Validar archivo de imagen
            if 'imagen' not in request.files:
                return {'error': 'Se requiere una imagen para el producto'}, 400
                
            imagen = request.files['imagen']
            if not imagen.filename:
                return {'error': 'No se seleccionó ningún archivo de imagen'}, 400

            data = request.form
            
            # Validar campos requeridos
            campos_requeridos = ['nombre', 'precio', 'id_categoria', 'id_genero']
            for campo in campos_requeridos:
                if campo not in data or not str(data[campo]).strip():
                    return {'error': f'El campo {campo} es requerido'}, 400

            # Validar que la categoría exista
            categoria = Categoria.query.get(data['id_categoria'])
            if not categoria:
                return {'error': 'La categoría especificada no existe'}, 404

            # Validar que el género exista
            genero = Genero.query.get(data['id_genero'])
            if not genero:
                return {'error': 'El género especificado no existe'}, 404

            # Validar y formatear estado
            estado = data.get('estado', 'Disponible').capitalize()
            estados_validos = ['Disponible', 'No disponible', 'Agotado']
            if estado not in estados_validos:
                estado = 'Disponible'

            # Validar precio positivo
            precio = float(data['precio'])
            if precio <= 0:
                return {'error': 'El precio debe ser mayor que cero'}, 400

            # Subir imagen a Cloudinary
            upload_result = cloudinary.uploader.upload(
                imagen,
                folder='productos',
                allowed_formats=['jpg', 'png', 'jpeg', 'webp'],
                quality='auto:good',
                width=800,
                crop='limit'
            )

            # Crear nuevo producto
            nuevo_producto = Producto(
                nombre=data['nombre'].strip(),
                descripcion=data.get('descripcion', '').strip(),
                precio=precio,
                estado=estado,
                id_categoria=int(data['id_categoria']),
                id_genero=int(data['id_genero']),
                imagen_url=upload_result['secure_url']
            )

            db.session.add(nuevo_producto)
            db.session.commit()

            return producto_schema.dump(nuevo_producto), 201

        except ValueError as e:
            return {'error': f'Error en los datos numéricos: {str(e)}'}, 400
            
        except Exception as e:
            db.session.rollback()
            # Intentar eliminar imagen subida si hubo error
            if 'upload_result' in locals() and 'public_id' in upload_result:
                try:
                    cloudinary.uploader.destroy(upload_result['public_id'])
                except:
                    pass
            return {'error': f'Error al crear el producto: {str(e)}'}, 500



        

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
        mensaje.body = f""" Como Estas {usuario.nombre}!

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
        asunto = data.get("asunto", "Notificación desde Stay In Style")
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
    @jwt_required()
    def post(self):
        try:
            # Configurar el parser para los datos de la compra
            parser = reqparse.RequestParser()
            parser.add_argument('barrio', type=str, required=True, help='El campo barrio es obligatorio')
            parser.add_argument('observaciones', type=str)
            parser.add_argument('metodo_pago_id', type=int, required=True, help='El campo metodo_pago_id es obligatorio')
            parser.add_argument('productos', type=list, location='json', required=True, help='Lista de productos es obligatoria')
            
            # Parsear los datos de la solicitud
            datos = parser.parse_args()

            # Validar estructura básica de los productos
            if not isinstance(datos['productos'], list) or len(datos['productos']) == 0:
                return {
                    'mensaje': 'La lista de productos no puede estar vacía',
                    'status': 400
                }, 400

            # Obtener el ID del usuario autenticado desde el token JWT
            usuario_actual_id = get_jwt_identity()
            
            # Verificar que el usuario exista
            usuario = Usuario.query.get(usuario_actual_id)
            if not usuario:
                return {'mensaje': 'Usuario no encontrado', 'status': 404}, 404

            # Verificar que el método de pago exista
            metodo_pago = MetodoPago.query.get(datos['metodo_pago_id'])
            if not metodo_pago:
                return {'mensaje': 'Método de pago no encontrado', 'status': 404}, 404

            # Crear la nueva compra
            nueva_compra = Compra(
                barrio=datos['barrio'],
                observaciones=datos.get('observaciones'),
                usuario_id=usuario_actual_id,
                metodo_pago_id=datos['metodo_pago_id'],
                estado_pedido='Procesado',
                fecha_compra=datetime.utcnow()
            )

            db.session.add(nueva_compra)
            db.session.flush()  # Para obtener el ID de la compra

            # Procesar cada producto en la compra
            productos_info = []
            productos_actualizados = set()  # Para evitar actualizar el mismo producto múltiples veces
            
            for idx, producto_data in enumerate(datos['productos']):
                try:
                    # Validar campos requeridos con mensajes más descriptivos
                    id_producto = producto_data.get('id_producto')
                    if not id_producto:
                        raise ValueError(f'Producto en posición {idx+1} no tiene id_producto')
                    
                    cantidad = producto_data.get('cantidad')
                    if not cantidad:
                        raise ValueError(f'Producto en posición {idx+1} no tiene cantidad')
                    try:
                        cantidad = int(cantidad)
                        if cantidad <= 0:
                            raise ValueError(f'Cantidad inválida para producto en posición {idx+1}')
                    except (ValueError, TypeError):
                        raise ValueError(f'Cantidad debe ser un número positivo para producto en posición {idx+1}')
                    
                    id_talla = producto_data.get('id_talla')
                    if not id_talla:
                        raise ValueError(f'Producto en posición {idx+1} no tiene id_talla')
                    try:
                        id_talla = int(id_talla)
                    except (ValueError, TypeError):
                        raise ValueError(f'id_talla debe ser un número para producto en posición {idx+1}')
                
                    producto = Producto.query.get(id_producto)
                    if not producto:
                        raise ValueError(f'Producto con ID {id_producto} no encontrado (posición {idx+1})')
                    
                    # Verificar que la talla exista
                    talla = Talla.query.get(id_talla)
                    if not talla:
                        raise ValueError(f'Talla con ID {id_talla} no encontrada (posición {idx+1})')

                    # Verificar inventario y stock
                    inventario = Inventario.query.filter_by(
                        id_producto=id_producto,
                        id_talla=id_talla
                    ).with_for_update().first()

                    if not inventario:
                        raise ValueError(f'No existe inventario para el producto {producto.nombre} en talla {talla.nombre} (posición {idx+1})')

                    if inventario.stock < cantidad:
                        raise ValueError(f'No hay suficiente stock para {producto.nombre} (Talla: {talla.nombre}). Disponible: {inventario.stock}, Solicitado: {cantidad} (posición {idx+1})')

                    # Obtener precio del producto
                    precio_unitario = producto_data.get('precio_unitario', producto.precio)
                    try:
                        precio_unitario = float(precio_unitario)
                    except (ValueError, TypeError):
                        precio_unitario = float(producto.precio)
                    
                    subtotal = precio_unitario * cantidad

                    # Registrar en tabla intermedia (incluyendo id_talla)
                    db.session.execute(
                        compra_producto.insert().values(
                            compra_id=nueva_compra.id,
                            producto_id=producto.id,
                            id_talla=id_talla,
                            precio_unitario=precio_unitario,
                            cantidad=cantidad
                        )
                    )
                    
                    # Actualizar el inventario (reducir stock)
                    inventario.stock -= cantidad
                    
                    # Marcar el producto para actualizar su estado después
                    productos_actualizados.add(id_producto)

                    productos_info.append({
                        'id_producto': producto.id,
                        'nombre': producto.nombre,
                        'id_talla': id_talla,
                        'talla': talla.nombre,
                        'cantidad': cantidad,
                        'precio_unitario': precio_unitario,
                        'subtotal': subtotal,
                        'imagen_url': producto.imagen_url,
                        'stock_actualizado': inventario.stock,
                        'posicion': idx+1
                    })

                except ValueError as ve:
                    db.session.rollback()
                    return {
                        'mensaje': str(ve),
                        'status': 400,
                        'producto_posicion': idx+1
                    }, 400

            # Actualizar el estado de los productos afectados
            for producto_id in productos_actualizados:
                producto = Producto.query.get(producto_id)
                if producto:
                    # Verificar si quedan unidades disponibles en cualquier talla
                    tiene_stock = any(inv.stock > 0 for inv in producto.inventarios)
                    producto.estado = "Disponible" if tiene_stock else "Agotado"

            # Calcular el total de la compra
            nueva_compra.total = sum(p['subtotal'] for p in productos_info)
            
            # Cambiar estado del carrito a "Completado" si existe
            carrito = Carrito.query.filter_by(
                id_usuario=usuario_actual_id,
                estado="Abierto"
            ).first()
            
            if carrito:
                carrito.estado = "Completado"
                carrito.total = 0.0
                # Eliminar los productos del carrito
                CarritoProducto.query.filter_by(id_carrito=carrito.id).delete()

            db.session.commit()

            return {
                'mensaje': 'Compra registrada exitosamente',
                'compra_id': nueva_compra.id,
                'fecha': nueva_compra.fecha_compra.isoformat(),
                'productos': productos_info,
                'total': nueva_compra.total,
                'status': 201
            }, 201

        except Exception as e:
            db.session.rollback()
            import traceback
            traceback.print_exc()
            return {
                'mensaje': f'Error al procesar la compra: {str(e)}',
                'error': str(e),
                'status': 500
            }, 500

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


# PARA VER LAS CATEGORIASSSSSSSS
class VistaCategorias(Resource):
    @cross_origin()
    def get(self):
        """Obtener todas las categorías"""
        try:
            categorias = Categoria.query.order_by(Categoria.nombre.asc()).all()
            return categorias_schema.dump(categorias), 200
        except Exception as e:
            return {'error': str(e)}, 500

    @cross_origin()
    def post(self):
        """Crear nueva categoría"""
        try:
            data = request.get_json()
            
            # Validación simple
            if not data.get('nombre'):
                return {'error': 'El nombre es requerido'}, 400
                
            # Verificar si ya existe
            if Categoria.query.filter_by(nombre=data['nombre'].strip()).first():
                return {'error': 'Esta categoría ya existe'}, 400
                
            nueva_categoria = Categoria(nombre=data['nombre'].strip())
            db.session.add(nueva_categoria)
            db.session.commit()
            
            return categoria_schema.dump(nueva_categoria), 201
            
        except Exception as e:
            db.session.rollback()
            return {'error': str(e)}, 500

class VistaCategoria(Resource):
    @cross_origin()
    def get(self, id_categoria):
        """Obtener una categoría específica"""
        try:
            categoria = Categoria.query.get_or_404(id_categoria)
            return categoria_schema.dump(categoria), 200
        except Exception as e:
            return {'error': str(e)}, 404

    @cross_origin()
    def put(self, id_categoria):
        """Actualizar categoría"""
        try:
            categoria = Categoria.query.get_or_404(id_categoria)
            data = request.get_json()
            
            if not data.get('nombre'):
                return {'error': 'El nombre es requerido'}, 400
                
            # Verificar si el nuevo nombre ya existe (y no es el mismo)
            nombre = data['nombre'].strip()
            if nombre != categoria.nombre and Categoria.query.filter_by(nombre=nombre).first():
                return {'error': 'Esta categoría ya existe'}, 400
                
            categoria.nombre = nombre
            db.session.commit()
            
            return categoria_schema.dump(categoria), 200
            
        except Exception as e:
            db.session.rollback()
            return {'error': str(e)}, 500

    @cross_origin()
    def delete(self, id_categoria):
        """Eliminar categoría"""
        try:
            categoria = Categoria.query.get_or_404(id_categoria)
            
            # Verificar si tiene productos asociados
            if categoria.productos:
                return {'error': 'No se puede eliminar, tiene productos asociados'}, 400
                
            db.session.delete(categoria)
            db.session.commit()
            return {'mensaje': 'Categoría eliminada correctamente'}, 200
            
        except Exception as e:
            db.session.rollback()
            return {'error': str(e)}, 500



class VistaReporteVentas(Resource):
    def get(self):
        # Parámetros de filtrado
        periodo = request.args.get('periodo', 'dia')  # dia/semana/mes/año
        top = request.args.get('top', type=int)  # Opcional (ej: 5 para top 5)
        
        # Calcular rangos de fecha según el periodo
        hoy = datetime.utcnow()
        query = db.session.query(
            Producto.nombre,
            func.sum(compra_producto.c.cantidad).label('total_unidades'),
            func.sum(compra_producto.c.cantidad * compra_producto.c.precio_unitario).label('total_ventas')
        ).join(
            compra_producto, Producto.id == compra_producto.c.producto_id
        ).join(
            Compra, Compra.id == compra_producto.c.compra_id
        )

        # Filtrar por periodo
        if periodo == 'dia':
            query = query.filter(func.date(Compra.fecha_compra) == hoy.date())
        elif periodo == 'semana':
            inicio_semana = hoy - timedelta(days=hoy.weekday())
            query = query.filter(func.date(Compra.fecha_compra) >= inicio_semana.date())
        elif periodo == 'mes':
            query = query.filter(
                extract('month', Compra.fecha_compra) == hoy.month,
                extract('year', Compra.fecha_compra) == hoy.year
            )
        elif periodo == 'año':
            query = query.filter(extract('year', Compra.fecha_compra) == hoy.year)

        # Agrupar y ordenar
        query = query.group_by(Producto.nombre).order_by(func.sum(compra_producto.c.cantidad).desc())

        if top:
            query = query.limit(top)

        resultados = query.all()
        
        return {
            'periodo': periodo,
            'ventas': [{
                'producto': item.nombre,
                'unidades_vendidas': item.total_unidades,
                'ventas_totales': round(item.total_ventas, 2)
            } for item in resultados]
        }, 200


class VistaRoles(Resource):
    def get(self):
        try:
            roles = Rol.query.order_by(Rol.id).all()
            
            if not roles:
                return {"mensaje": "No hay roles registrados"}, 404
                
            return {
                "mensaje": "Roles obtenidos correctamente",
                "roles": roles_schema.dump(roles)  # Usa el schema importado
            }, 200
            
        except Exception as e:
            return {
                "mensaje": "Error al consultar los roles",
                "error": str(e)
            }, 500


# VAMOS A CREAR TOOD PARA LO DE CARRITO 

# Vista para Obtener y Crear Carritos (VistaCarritos)
class VistaCarritos(Resource):
    @jwt_required()
    def get(self):
        """Obtener todos los carritos del usuario (activos e históricos)"""
        try:
            usuario_id = get_jwt_identity()
            carritos = Carrito.query.filter_by(id_usuario=usuario_id).order_by(Carrito.id.desc()).all()
            
            return {
                "carritos": [{
                    "id": carrito.id,
                    "total": carrito.total,
                    "estado": carrito.estado,
                    "fecha_creacion": carrito.fecha_creacion.isoformat() if carrito.fecha_creacion else None,
                    "fecha_actualizacion": carrito.fecha_actualizacion.isoformat() if carrito.fecha_actualizacion else None,
                    "cantidad_productos": len(carrito.productos)
                } for carrito in carritos]
            }, 200
            
        except Exception as e:
            logging.error(f"Error en VistaCarritos.get: {str(e)}", exc_info=True)
            return {"mensaje": "Error al obtener los carritos"}, 500

    @jwt_required()
    def post(self):
        """Crear un nuevo carrito para el usuario"""
        try:
            usuario_id = get_jwt_identity()
            
            # Verificar si ya tiene un carrito abierto
            carrito_abierto = Carrito.query.filter_by(
                id_usuario=usuario_id, 
                estado="Abierto"
            ).first()
            
            if carrito_abierto:
                return {
                    "mensaje": "Ya tienes un carrito abierto",
                    "carrito_id": carrito_abierto.id
                }, 200
            
            # Crear nuevo carrito
            nuevo_carrito = Carrito(
                id_usuario=usuario_id,
                estado="Abierto",
                total=0.0
            )
            
            db.session.add(nuevo_carrito)
            db.session.commit()
            
            return {
                "mensaje": "Carrito creado exitosamente",
                "carrito_id": nuevo_carrito.id
            }, 201
            
        except Exception as e:
            db.session.rollback()
            logging.error(f"Error en VistaCarritos.post: {str(e)}")
            return {"mensaje": "Error al crear el carrito"}, 500


#Vista para Gestionar un Carrito Específico (VistaCarrito)

class VistaCarrito(Resource):
    @jwt_required()
    def get(self, id_carrito):
        """Obtener detalles de un carrito específico"""
        try:
            usuario_id = get_jwt_identity()
            carrito = Carrito.query.filter_by(
                id=id_carrito,
                id_usuario=usuario_id
            ).first_or_404()
            
            # Función para formatear URL de imagen
            def format_image_url(imagen_url):
                if not imagen_url:
                    return None
                if imagen_url.startswith('http'):
                    return imagen_url
                return f"https://res.cloudinary.com/dodecmh9s/image/upload/w_300,h_300,c_fill/{imagen_url}"
            
            productos = []
            for item in carrito.productos:
                producto = item.producto
                productos.append({
                    "id_producto": producto.id,
                    "nombre": producto.nombre,
                    "precio": float(producto.precio),
                    "imagen_url": format_image_url(producto.imagen_url),
                    "talla": item.talla,
                    "cantidad": item.cantidad,
                    "subtotal": float(item.subtotal),
                    "producto": {
                        "nombre": producto.nombre,
                        "precio": float(producto.precio),
                        "imagen_url": format_image_url(producto.imagen_url)
                    }
                })
            
            return {
                "carrito": {
                    "id": carrito.id,
                    "total": float(carrito.total),
                    "estado": carrito.estado,
                    "fecha_creacion": carrito.fecha_creacion.isoformat() if carrito.fecha_creacion else None,
                    "productos": productos
                }
            }, 200
            
        except Exception as e:
            logging.error(f"Error en VistaCarrito.get: {str(e)}")
            return {"mensaje": "Error al obtener el carrito"}, 500

    @jwt_required()
    def put(self, id_carrito):
        """Actualizar estado del carrito (ej: de Abierto a Completado)"""
        try:
            usuario_id = get_jwt_identity()
            data = request.get_json()
            
            carrito = Carrito.query.filter_by(
                id=id_carrito,
                id_usuario=usuario_id
            ).with_for_update().first_or_404()
            
            if 'estado' in data and data['estado'] in ['Abierto', 'Completado', 'Cancelado']:
                carrito.estado = data['estado']
                db.session.commit()
                
                return {
                    "mensaje": "Estado del carrito actualizado",
                    "carrito": {
                        "id": carrito.id,
                        "estado": carrito.estado,
                        "total": float(carrito.total)
                    }
                }, 200
            else:
                return {"mensaje": "Estado no válido o no proporcionado"}, 400
                
        except Exception as e:
            db.session.rollback()
            logging.error(f"Error en VistaCarrito.put: {str(e)}")
            return {"mensaje": "Error al actualizar el carrito"}, 500

    @jwt_required()
    def delete(self, id_carrito):
        """Cancelar/eliminar un carrito"""
        try:
            usuario_id = get_jwt_identity()
            carrito = Carrito.query.filter_by(
                id=id_carrito,
                id_usuario=usuario_id,
                estado="Abierto"
            ).with_for_update().first_or_404()
            
            # Eliminar todos los productos del carrito primero
            for item in carrito.productos:
                db.session.delete(item)
            
            carrito.estado = "Cancelado"
            carrito.total = 0.0
            db.session.commit()
            
            return {
                "mensaje": "Carrito cancelado exitosamente",
                "carrito": {
                    "id": carrito.id,
                    "estado": carrito.estado,
                    "total": 0.0
                }
            }, 200
            
        except Exception as e:
            db.session.rollback()
            logging.error(f"Error en VistaCarrito.delete: {str(e)}")
            return {"mensaje": "Error al cancelar el carrito"}, 500


class VistaCarritoProductos(Resource):
    @jwt_required()
    def post(self):
        """Agregar producto al carrito con id_talla y validación de stock"""
        try:
            usuario_id = get_jwt_identity()
            data = request.get_json()
            
            # Validación básica de datos
            if not data or 'producto_id' not in data or 'id_talla' not in data:
                return {
                    "mensaje": "Datos incompletos. Se requieren 'producto_id' e 'id_talla'",
                    "status": 400
                }, 400
            
            # Validar y obtener cantidad (valor por defecto 1)
            cantidad = 1
            if 'cantidad' in data:
                try:
                    cantidad = int(data['cantidad'])
                    if cantidad <= 0:
                        return {
                            "mensaje": "La cantidad debe ser mayor a 0",
                            "status": 400
                        }, 400
                except ValueError:
                    return {
                        "mensaje": "Cantidad debe ser un número válido",
                        "status": 400
                    }, 400

            # Obtener o crear carrito con bloqueo
            carrito = Carrito.query.filter_by(
                id_usuario=usuario_id,
                estado="Abierto"
            ).with_for_update().first()

            if not carrito:
                carrito = Carrito(
                    id_usuario=usuario_id,
                    estado="Abierto",
                    total=0.0
                )
                db.session.add(carrito)
                db.session.flush()
            
            # Verificar producto
            producto = Producto.query.filter_by(
                id=data['producto_id'],
                estado="Disponible"
            ).first()
            
            if not producto:
                return {
                    "mensaje": "Producto no disponible o no encontrado",
                    "status": 404
                }, 404

            # Verificar talla
            talla = Talla.query.get(data['id_talla'])
            if not talla:
                return {
                    "mensaje": "Talla no válida",
                    "status": 400
                }, 400

            # Verificar inventario
            inventario = Inventario.query.filter_by(
                id_producto=producto.id,
                id_talla=data['id_talla']
            ).with_for_update().first()

            if not inventario:
                return {
                    "mensaje": "No hay inventario para esta combinación de producto y talla",
                    "status": 400
                }, 400

            # Buscar item existente en carrito
            item_existente = CarritoProducto.query.filter_by(
                id_carrito=carrito.id,
                id_producto=producto.id,
                id_talla=data['id_talla']
            ).with_for_update().first()

            # Calcular nueva cantidad total
            nueva_cantidad = cantidad + (item_existente.cantidad if item_existente else 0)

            # Validar stock
            if inventario.stock < nueva_cantidad:
                disponible = inventario.stock - (item_existente.cantidad if item_existente else 0)
                return {
                    "mensaje": f"No hay suficiente stock. Disponible: {max(disponible, 0)}",
                    "status": 400,
                    "stock_disponible": max(disponible, 0)
                }, 400

            # Actualizar o crear item
            if item_existente:
                item_existente.cantidad = nueva_cantidad
                item_existente.subtotal = producto.precio * nueva_cantidad
            else:
                item_existente = CarritoProducto(
                    id_carrito=carrito.id,
                    id_producto=producto.id,
                    id_talla=data['id_talla'],
                    cantidad=cantidad,
                    subtotal=producto.precio * cantidad
                )
                db.session.add(item_existente)

            # Actualizar total del carrito
            carrito.total = sum(item.subtotal for item in carrito.productos)
            db.session.commit()

            # Preparar respuesta
            response_data = {
                "mensaje": "Producto agregado al carrito",
                "carrito": {
                    "id": carrito.id,
                    "total": float(carrito.total),
                    "productos": [{
                        "id_producto": producto.id,
                        "nombre": producto.nombre,
                        "id_talla": data['id_talla'],
                        "talla": talla.nombre if talla else "Desconocida",
                        "cantidad": nueva_cantidad,
                        "subtotal": float(producto.precio * nueva_cantidad),
                        "precio_unitario": float(producto.precio),
                        "imagen_url": producto.imagen_url,
                        "stock_disponible": inventario.stock - nueva_cantidad
                    }]
                }
            }

            return response_data, 200

        except Exception as e:
            db.session.rollback()
            logging.error(f"Error en agregar producto al carrito: {str(e)}", exc_info=True)
            return {
                "mensaje": "Error al procesar la solicitud",
                "error": str(e),
                "status": 500
            }, 500

    @jwt_required()
    def get(self):
        """Obtener carrito actual con información de stock"""
        try:
            usuario_id = get_jwt_identity()
            
            carrito = Carrito.query.filter_by(
                id_usuario=usuario_id,
                estado="Abierto"
            ).first()

            if not carrito:
                return {
                    "mensaje": "No tienes un carrito activo",
                    "carrito": None,
                    "status": 200
                }, 200

            response_data = {
                "carrito": {
                    "id": carrito.id,
                    "total": float(carrito.total),
                    "productos": []
                }
            }

            # Obtener productos con información de stock
            for item in carrito.productos:
                producto = item.producto
                talla = Talla.query.get(item.id_talla)
                inventario = Inventario.query.filter_by(
                    id_producto=producto.id,
                    id_talla=item.id_talla
                ).first()

                response_data["carrito"]["productos"].append({
                    "id_producto": producto.id,
                    "nombre": producto.nombre,
                    "id_talla": item.id_talla,
                    "talla": talla.nombre if talla else "Desconocida",
                    "cantidad": item.cantidad,
                    "subtotal": float(item.subtotal),
                    "precio_unitario": float(producto.precio),
                    "imagen_url": producto.imagen_url,
                    "stock_disponible": inventario.stock if inventario else 0,
                    "puede_aumentar": inventario.stock > item.cantidad if inventario else False
                })

            return response_data, 200

        except Exception as e:
            logging.error(f"Error al obtener carrito: {str(e)}", exc_info=True)
            return {
                "mensaje": "Error al obtener el carrito",
                "error": str(e),
                "status": 500
            }, 500

    @jwt_required()
    def put(self):
        """Actualizar cantidad en carrito con validación de stock"""
        try:
            usuario_id = get_jwt_identity()
            data = request.get_json()
            
            # Validación de datos
            required_fields = ['producto_id', 'id_talla', 'cantidad']
            if not all(field in data for field in required_fields):
                return {
                    "mensaje": f"Datos incompletos. Requeridos: {', '.join(required_fields)}",
                    "status": 400
                }, 400

            try:
                nueva_cantidad = int(data['cantidad'])
                if nueva_cantidad <= 0:
                    return {
                        "mensaje": "La cantidad debe ser mayor a 0",
                        "status": 400
                    }, 400
            except ValueError:
                return {
                    "mensaje": "Cantidad debe ser un número válido",
                    "status": 400
                }, 400

            # Obtener carrito con bloqueo
            carrito = Carrito.query.filter_by(
                id_usuario=usuario_id,
                estado="Abierto"
            ).with_for_update().first_or_404(description="No tienes un carrito activo")

            # Buscar item en carrito
            item = CarritoProducto.query.filter_by(
                id_carrito=carrito.id,
                id_producto=data['producto_id'],
                id_talla=data['id_talla']
            ).with_for_update().first_or_404(description="El producto no está en tu carrito")

            # Verificar stock disponible
            inventario = Inventario.query.filter_by(
                id_producto=item.id_producto,
                id_talla=item.id_talla
            ).with_for_update().first()

            if not inventario or inventario.stock < nueva_cantidad:
                disponible = inventario.stock if inventario else 0
                return {
                    "mensaje": f"No hay suficiente stock. Disponible: {disponible}",
                    "stock_disponible": disponible,
                    "status": 400
                }, 400

            # Actualizar cantidad
            item.cantidad = nueva_cantidad
            item.subtotal = item.producto.precio * nueva_cantidad

            # Recalcular total
            carrito.total = db.session.query(
                db.func.sum(CarritoProducto.subtotal)
            ).filter_by(id_carrito=carrito.id).scalar() or 0.0

            db.session.commit()

            talla = Talla.query.get(item.id_talla)
            return {
                "mensaje": "Cantidad actualizada",
                "carrito": {
                    "id": carrito.id,
                    "total": float(carrito.total),
                    "productos": [{
                        "id_producto": item.id_producto,
                        "nombre": item.producto.nombre,
                        "id_talla": item.id_talla,
                        "talla": talla.nombre if talla else "Desconocida",
                        "cantidad": item.cantidad,
                        "subtotal": float(item.subtotal),
                        "stock_disponible": inventario.stock - item.cantidad
                    }]
                }
            }, 200

        except Exception as e:
            db.session.rollback()
            logging.error(f"Error al actualizar cantidad: {str(e)}", exc_info=True)
            return {
                "mensaje": "Error al actualizar cantidad",
                "error": str(e),
                "status": 500
            }, 500

    @jwt_required()
    def delete(self):
        """Eliminar producto del carrito"""
        try:
            usuario_id = get_jwt_identity()
            data = request.get_json()
            
            # Validación de datos
            required_fields = ['producto_id', 'id_talla']
            if not all(field in data for field in required_fields):
                return {
                    "mensaje": f"Datos incompletos. Requeridos: {', '.join(required_fields)}",
                    "status": 400
                }, 400

            # Obtener carrito con bloqueo
            carrito = Carrito.query.filter_by(
                id_usuario=usuario_id,
                estado="Abierto"
            ).with_for_update().first_or_404(description="No tienes un carrito activo")

            # Buscar y eliminar item
            item = CarritoProducto.query.filter_by(
                id_carrito=carrito.id,
                id_producto=data['producto_id'],
                id_talla=data['id_talla']
            ).with_for_update().first_or_404(description="El producto no está en tu carrito")

            db.session.delete(item)

            # Recalcular total
            carrito.total = db.session.query(
                db.func.sum(CarritoProducto.subtotal)
            ).filter_by(id_carrito=carrito.id).scalar() or 0.0

            # Si no quedan productos, eliminar carrito
            if carrito.total == 0:
                db.session.delete(carrito)

            db.session.commit()

            return {
                "mensaje": "Producto eliminado del carrito",
                "carrito_id": carrito.id if carrito.total > 0 else None,
                "total": float(carrito.total) if carrito.total > 0 else 0,
                "status": 200
            }, 200

        except Exception as e:
            db.session.rollback()
            logging.error(f"Error al eliminar producto: {str(e)}", exc_info=True)
            return {
                "mensaje": "Error al eliminar producto",
                "error": str(e),
                "status": 500
            }, 500


# VAMOS A CREAR LAS VISTA PAR AEL INVENTARIO

inventario_schema = InventarioSchema()
inventarios_schema = InventarioSchema(many=True)

inventario_schema = InventarioSchema()
inventarios_schema = InventarioSchema(many=True)

class VistaInventarioProducto(Resource):
    @jwt_required()
    def get(self, id_producto):
        producto = Producto.query.get_or_404(id_producto)
        
        # Obtener todas las tallas disponibles en la base de datos
        todas_tallas = Talla.query.all()
        tallas_permitidas_ids = [talla.id for talla in todas_tallas if talla.nombre.strip() in TALLAS_PERMITIDAS]
        
        # Filtrar inventarios por tallas permitidas
        inventarios = [inv for inv in producto.inventarios if inv.id_talla in tallas_permitidas_ids]
        
        # Cargar información completa de la talla
        resultado = []
        for inv in inventarios:
            talla = Talla.query.get(inv.id_talla)
            resultado.append({
                "id": inv.id,
                "id_producto": inv.id_producto,
                "id_talla": inv.id_talla,
                "talla": talla.nombre.strip(),
                "stock": inv.stock
            })
        
        return resultado, 200
    
    @jwt_required()
    def post(self, id_producto):
        producto = Producto.query.get_or_404(id_producto)
        data = request.get_json()
        
        # Validaciones básicas
        if 'id_talla' not in data or 'stock' not in data:
            return {"mensaje": "Se requieren los campos id_talla y stock"}, 400
        
        # Validar que la talla exista y esté permitida
        talla = Talla.query.get(data['id_talla'])
        if not talla:
            return {"mensaje": "La talla especificada no existe"}, 404
            
        if talla.nombre.strip() not in TALLAS_PERMITIDAS:
            return {
                "mensaje": f"Talla no permitida. Las tallas válidas son: {', '.join(TALLAS_PERMITIDAS)}"
            }, 400
        
        # Validar si ya existe inventario para esta talla
        if Inventario.query.filter_by(id_producto=id_producto, id_talla=data['id_talla']).first():
            return {"mensaje": "Ya existe un registro de inventario para esta talla"}, 400
            
        # Validar que el stock sea un número positivo
        try:
            stock = int(data['stock'])
            if stock < 0:
                raise ValueError
        except (ValueError, KeyError):
            return {"mensaje": "El stock debe ser un número entero positivo"}, 400
            
        # Crear el nuevo registro de inventario
        inventario = Inventario(
            id_producto=id_producto,
            id_talla=data['id_talla'],
            stock=stock
        )
        
        db.session.add(inventario)
        db.session.commit()
        
        # Devolver respuesta con información completa
        return {
            "id": inventario.id,
            "id_producto": inventario.id_producto,
            "id_talla": inventario.id_talla,
            "talla": talla.nombre.strip(),
            "stock": inventario.stock,
            "mensaje": "Inventario creado exitosamente"
        }, 201

class VistaInventarioProducto(Resource):
    @jwt_required()
    def get(self, id_producto):
        producto = Producto.query.get_or_404(id_producto)
        
        # Obtener todas las tallas disponibles en la base de datos
        todas_tallas = Talla.query.all()
        
        # Cargar información completa del inventario con tallas
        resultado = []
        for inv in producto.inventarios:
            talla = Talla.query.get(inv.id_talla)
            resultado.append({
                "id": inv.id,
                "id_producto": inv.id_producto,
                "id_talla": inv.id_talla,
                "talla": talla.nombre.strip(),
                "stock": inv.stock
            })
        
        return resultado, 200
    
    @jwt_required()
    def post(self, id_producto):
        producto = Producto.query.get_or_404(id_producto)
        data = request.get_json()
        
        # Validaciones básicas
        if 'id_talla' not in data or 'stock' not in data:
            return {"mensaje": "Se requieren los campos id_talla y stock"}, 400
        
        # Validar que la talla exista
        talla = Talla.query.get(data['id_talla'])
        if not talla:
            return {"mensaje": "La talla especificada no existe"}, 404
        
        # Validar si ya existe inventario para esta talla
        if Inventario.query.filter_by(id_producto=id_producto, id_talla=data['id_talla']).first():
            return {"mensaje": "Ya existe un registro de inventario para esta talla"}, 400
            
        # Validar que el stock sea un número positivo
        try:
            stock = int(data['stock'])
            if stock < 0:
                raise ValueError
        except (ValueError, KeyError):
            return {"mensaje": "El stock debe ser un número entero positivo"}, 400
            
        # Crear el nuevo registro de inventario
        inventario = Inventario(
            id_producto=id_producto,
            id_talla=data['id_talla'],
            stock=stock
        )
        
        db.session.add(inventario)
        db.session.commit()
        
        # Devolver respuesta con información completa
        return {
            "id": inventario.id,
            "id_producto": inventario.id_producto,
            "id_talla": inventario.id_talla,
            "talla": talla.nombre.strip(),
            "stock": inventario.stock,
            "mensaje": "Inventario creado exitosamente"
        }, 201
class VistaInventarioItem(Resource):
    @jwt_required()
    def put(self, id_inventario):
        inventario = Inventario.query.get_or_404(id_inventario)
        data = request.get_json()
        
        # Validar talla si se está actualizando
        if 'talla' in data:
            if data['talla'] not in TALLAS_PERMITIDAS:
                return {
                    "mensaje": f"Talla no permitida. Las tallas válidas son: {', '.join(TALLAS_PERMITIDAS)}"
                }, 400
            inventario.talla = data['talla']
        
        # Validar stock si se está actualizando
        if 'stock' in data:
            try:
                stock = int(data['stock'])
                if stock < 0:
                    raise ValueError
                inventario.stock = stock
            except (ValueError, KeyError):
                return {"mensaje": "El stock debe ser un número entero positivo"}, 400
        
        db.session.commit()
        
        # Actualizar el estado del producto relacionado
        producto = Producto.query.get(inventario.id_producto)
        producto.actualizar_estado()
        
        return inventario_schema.dump(inventario), 200
    
    @jwt_required()
    def delete(self, id_inventario):
        inventario = Inventario.query.get_or_404(id_inventario)
        producto_id = inventario.id_producto  # Guardamos el ID antes de borrar
        
        db.session.delete(inventario)
        db.session.commit()
        
        # Actualizar el estado del producto relacionado
        producto = Producto.query.get(producto_id)
        producto.actualizar_estado()
        
        return {"mensaje": "Registro de inventario eliminado"}, 204

class VistaTallasDisponibles(Resource):
    def get(self):
        # Consulta directa a la tabla tallas
        tallas = Talla.query.order_by(Talla.id).all()
        
        # Formatear la respuesta con solo los datos básicos
        return {
            "tallas": [
                {
                    "id": talla.id,
                    "nombre": talla.nombre.strip()  # .strip() para eliminar espacios extras
                } 
                for talla in tallas
            ]
        }, 200


class VistaTallas(Resource):
    def get(self, id_producto):
        # Verificar que el producto exista
        producto = Producto.query.get(id_producto)
        if not producto:
            return {"mensaje": "Producto no encontrado"}, 404
        
        # Obtener todas las tallas de la base de datos
        todas_tallas = Talla.query.all()
        
        # Obtener el inventario para este producto
        inventarios = Inventario.query.filter_by(id_producto=id_producto).all()
        
        # Crear un diccionario temporal para mapear tallas por ID
        tallas_por_id = {talla.id: talla.nombre.strip() for talla in todas_tallas}
        
        # Crear respuesta con todas las tallas
        tallas_disponibles = []
        
        for talla_id, talla_nombre in tallas_por_id.items():
            # Buscar si existe inventario para esta talla y producto
            inventario = next(
                (inv for inv in inventarios if inv.id_talla == talla_id), 
                None
            )
            
            if inventario:
                # Si existe registro en inventario
                tallas_disponibles.append({
                    "id_talla": talla_id,
                    "talla": talla_nombre,
                    "stock": inventario.stock,
                    "disponible": inventario.stock > 0
                })
            else:
                # Si no existe registro, mostrar con stock 0
                tallas_disponibles.append({
                    "id_talla": talla_id,
                    "talla": talla_nombre,
                    "stock": 0,
                    "disponible": False
                })
        
        return {
            "id_producto": id_producto,
            "tallas": tallas_disponibles
        }, 200


class VistaGeneroDisponible(Resource):
    def get(self):
        # Consulta directa a la tabla genero
        generos = Genero.query.order_by(Genero.id).all()
        
        # Formatear la respuesta básica
        return {
            "generos": [
                {
                    "id": genero.id,
                    "nombre": genero.nombre.strip()  # .strip() por si acaso hay espacios
                } 
                for genero in generos
            ]
        }, 200



class VistaHistorialCompras(Resource):
    @jwt_required()
    def get(self):
        try:
            usuario_actual = get_jwt_identity()
            print(f"Usuario autenticado: {usuario_actual}")
            
            # Verificar si el usuario existe
            usuario = Usuario.query.get(usuario_actual)
            if not usuario:
                return {'error': 'Usuario no encontrado'}, 404
            
            # Consulta de compras del usuario
            compras = Compra.query.filter_by(usuario_id=usuario_actual)\
                                .order_by(Compra.fecha_compra.desc())\
                                .all()
            print(f"Compras encontradas: {len(compras)}")
            
            if not compras:
                return {'mensaje': 'No has realizado compras aún'}, 200
            
            resultado = []
            for compra in compras:
                try:
                    # Consulta para obtener productos de la compra
                    productos_compra = db.session.query(
                        Producto.id,
                        Producto.nombre,
                        Producto.imagen_url,
                        compra_producto.c.cantidad,
                        compra_producto.c.precio_unitario,
                        Talla.nombre.label('talla')
                    ).select_from(compra_producto)\
                     .join(Producto, Producto.id == compra_producto.c.producto_id)\
                     .join(Talla, Talla.id == compra_producto.c.id_talla)\
                     .filter(compra_producto.c.compra_id == compra.id)\
                     .all()
                    
                    # Calcular el total sumando todos los subtotales
                    total_compra = sum(p.precio_unitario * p.cantidad for p in productos_compra)
                    
                    productos = [{
                        'id': p.id,
                        'nombre': p.nombre,
                        'imagen': p.imagen_url,
                        'cantidad': p.cantidad,
                        'precio': float(p.precio_unitario),
                        'talla': p.talla,
                        'subtotal': float(p.cantidad * p.precio_unitario)
                    } for p in productos_compra]
                    
                    resultado.append({
                        'id': compra.id,
                        'fecha': compra.fecha_compra.isoformat(),
                        'estado': compra.estado_pedido,
                        'total': float(total_compra),  # Total calculado
                        'metodo_pago': compra.metodo_pago.tipo if compra.metodo_pago else None,
                        'barrio': compra.barrio,
                        'observaciones': compra.observaciones,
                        'productos': productos
                    })
                    
                except Exception as e:
                    print(f"Error procesando compra {compra.id}: {str(e)}")
                    continue
            
            return {'compras': resultado}, 200
            
        except Exception as e:
            print(f"Error en endpoint: {str(e)}")
            return {
                'error': 'Ocurrió un error al obtener el historial',
                'detalle': str(e)
            }, 500


class VistaHistorialCompras(Resource):
    @jwt_required()
    def get(self):
        try:
            usuario_actual = get_jwt_identity()
            print(f"Usuario autenticado: {usuario_actual}")
            
            # Verificar si el usuario existe
            usuario = Usuario.query.get(usuario_actual)
            if not usuario:
                return {'error': 'Usuario no encontrado'}, 404
            
            # Consulta de compras del usuario
            compras = Compra.query.filter_by(usuario_id=usuario_actual)\
                                .order_by(Compra.fecha_compra.desc())\
                                .all()
            print(f"Compras encontradas: {len(compras)}")
            
            if not compras:
                return {'mensaje': 'No has realizado compras aún'}, 200
            
            resultado = []
            for compra in compras:
                try:
                    # Consulta para obtener productos de la compra
                    productos_compra = db.session.query(
                        Producto.id,
                        Producto.nombre,
                        Producto.imagen_url,
                        compra_producto.c.cantidad,
                        compra_producto.c.precio_unitario,
                        Talla.nombre.label('talla')
                    ).select_from(compra_producto)\
                     .join(Producto, Producto.id == compra_producto.c.producto_id)\
                     .join(Talla, Talla.id == compra_producto.c.id_talla)\
                     .filter(compra_producto.c.compra_id == compra.id)\
                     .all()
                    
                    # Calcular el total sumando todos los subtotales
                    total_compra = sum(p.precio_unitario * p.cantidad for p in productos_compra)
                    
                    productos = [{
                        'id': p.id,
                        'nombre': p.nombre,
                        'imagen': p.imagen_url,
                        'cantidad': p.cantidad,
                        'precio': float(p.precio_unitario),
                        'talla': p.talla,
                        'subtotal': float(p.cantidad * p.precio_unitario)
                    } for p in productos_compra]
                    
                    resultado.append({
                        'id': compra.id,
                        'fecha': compra.fecha_compra.isoformat(),
                        'estado': compra.estado_pedido,
                        'total': float(total_compra),  # Total calculado
                        'metodo_pago': compra.metodo_pago.tipo if compra.metodo_pago else None,
                        'barrio': compra.barrio,
                        'observaciones': compra.observaciones,
                        'productos': productos
                    })
                    
                except Exception as e:
                    print(f"Error procesando compra {compra.id}: {str(e)}")
                    continue
            
            return {'compras': resultado}, 200
            
        except Exception as e:
            print(f"Error en endpoint: {str(e)}")
            return {
                'error': 'Ocurrió un error al obtener el historial',
                'detalle': str(e)
            }, 500


class VistaHistorialStock(Resource):
    @jwt_required()
    def get(self):
        try:
            historial = HistorialStock.query\
                .options(
                    joinedload(HistorialStock.inventario_relacion).joinedload(Inventario.producto),
                    joinedload(HistorialStock.inventario_relacion).joinedload(Inventario.talla),
                    joinedload(HistorialStock.usuario_relacion)
                )\
                .order_by(HistorialStock.fecha_cambio.desc())\
                .all()
            
            return historial_stocks_schema.dump(historial), 200
        except Exception as e:
            current_app.logger.error(f"Error en VistaHistorialStock: {str(e)}")
            return {"mensaje": "Error al obtener el historial general"}, 500


class VistaHistorialStockProducto(Resource):
    @jwt_required()
    def get(self, id_producto):
        try:
            historial = HistorialStock.query\
                .join(Inventario, HistorialStock.inventario_relacion)\
                .options(
                    joinedload(HistorialStock.inventario_relacion).joinedload(Inventario.producto),
                    joinedload(HistorialStock.inventario_relacion).joinedload(Inventario.talla),
                    joinedload(HistorialStock.usuario_relacion)
                )\
                .filter(Inventario.id_producto == id_producto)\
                .order_by(HistorialStock.fecha_cambio.desc())\
                .all()
            
            return historial_stocks_schema.dump(historial), 200
        except Exception as e:
            current_app.logger.error(f"Error en VistaHistorialStockProducto: {str(e)}")
            return {"mensaje": f"Error al obtener historial para producto {id_producto}"}, 500

class VistaCrearHistorialStock(Resource):
    @jwt_required()
    def post(self):
        try:
            usuario_actual = get_jwt_identity()
            data = request.get_json()
            
            # Validaciones
            required_fields = ['id_inventario', 'stock_anterior', 'stock_nuevo']
            if not all(field in data for field in required_fields):
                return {"mensaje": "Faltan campos requeridos"}, 400

            # Verificar que el inventario exista
            inventario = Inventario.query.get_or_404(data['id_inventario'])
            
            # Verificar que el inventario tenga producto y talla asociados
            if not inventario.id_producto or not inventario.id_talla:
                return {"mensaje": "El inventario no tiene producto o talla asociada"}, 400
            
            # Crear el registro de historial
            nuevo_historial = HistorialStock(
                id_inventario=data['id_inventario'],
                id_usuario=usuario_actual,
                stock_anterior=data['stock_anterior'],
                stock_nuevo=data['stock_nuevo'],
                motivo=data.get('motivo', 'Ajuste manual'),
                # Estos campos se autocompletarán en __init__ a través de la relación
                inventario_relacion=inventario,
                # También podemos pasarlos directamente si queremos
                id_producto=inventario.id_producto,
                id_talla=inventario.id_talla
            )
            
            db.session.add(nuevo_historial)
            db.session.commit()
            
            return historial_stock_schema.dump(nuevo_historial), 201
        
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Error en VistaCrearHistorialStock: {str(e)}")
            return {"mensaje": "Error al crear el registro de historial"}, 500


class VistaDisponibilidadProducto(Resource):
    @cross_origin()
    def get(self, id_producto):
        """Obtener disponibilidad detallada del producto"""
        producto = Producto.query.get_or_404(id_producto)
        
        # Obtener información de tallas y stock
        tallas_info = []
        for inv in producto.inventarios:
            talla = Talla.query.get(inv.id_talla)
            tallas_info.append({
                "id_talla": talla.id,
                "talla": talla.nombre.strip(),
                "stock": inv.stock,
                "disponible": inv.stock > 0
            })
        
        return {
            "id_producto": producto.id,
            "nombre": producto.nombre,
            "disponible": producto.disponible,
            "estado": producto.estado,
            "stock_total": producto.stock_total,
            "tallas": tallas_info
        }, 200