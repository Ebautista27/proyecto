from flask_restful import Resource, reqparse
from flaskr.modelos import  Usuario, Compra
from flask import current_app
from flaskr.utils.email import enviar_correo
import logging



# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class VistaNotificaciones(Resource):
    def post(self):
        logger.info("Solicitud recibida en /notificaciones")
        
        parser = reqparse.RequestParser()
        parser.add_argument('asunto', required=True)
        parser.add_argument('mensaje', required=True)
        parser.add_argument('destinatarios', required=True, action='append')
        parser.add_argument('incluir_local', type=bool, required=False, default=False)
        parser.add_argument('local_email', required=False)
        
        try:
            datos = parser.parse_args()
            logger.info(f"Datos recibidos: {datos}")
            
            asunto = datos['asunto']
            mensaje = datos['mensaje']
            destinatarios = datos['destinatarios']
            
            # Verificar configuración de email
            logger.info(f"Configuración SMTP: {current_app.config['MAIL_SERVER']}:{current_app.config['MAIL_PORT']}")
            
            resultados = []
            
            if 'todos' in destinatarios:
                logger.info("Modo 'todos' seleccionado")
                # Implementar lógica para obtener todos los usuarios si es necesario
                resultado = enviar_correo("dilandakrg@gmail.com", asunto, mensaje)
                resultados.append(f"dilandakrg@gmail.com: {resultado}")
            else:
                for email in destinatarios:
                    logger.info(f"Enviando a: {email}")
                    resultado = enviar_correo(email, asunto, mensaje)
                    resultados.append(f"{email}: {resultado}")
                    if resultado != True:
                        logger.error(f"Error al enviar a {email}: {resultado}")
            
            if datos['incluir_local'] and datos.get('local_email'):
                logger.info(f"Enviando copia local a: {datos['local_email']}")
                enviar_correo(datos['local_email'], asunto, mensaje)
            
            logger.info("Notificaciones procesadas")
            return {
                'mensaje': 'Notificaciones procesadas',
                'resultados': resultados
            }, 200
            
        except Exception as e:
            logger.error(f"Error en notificaciones: {str(e)}", exc_info=True)
            return {'mensaje': f'Error en el servidor: {str(e)}'}, 500