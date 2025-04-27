from flask_restful import Resource, reqparse
from flaskr.modelos import  Usuario, Compra
from flaskr.utils.email import enviar_correo



class VistaNotificaciones(Resource):
    def post(self):
        parser = reqparse.RequestParser()
        parser.add_argument('asunto', required=True)
        parser.add_argument('mensaje', required=True)
        parser.add_argument('destinatarios', required=True, action='append')
        parser.add_argument('incluir_local', type=bool, required=False, default=False)
        parser.add_argument('local_email', required=False)
        datos = parser.parse_args()

        asunto = datos['asunto']
        mensaje = datos['mensaje']
        destinatarios = datos['destinatarios']
        incluir_local = datos['incluir_local']
        local_email = datos.get('local_email')

        if 'todos' in destinatarios:
            # Aquí iría tu lógica real para obtener todos los usuarios
            enviar_correo("dilandakrg@gmail.com", asunto, mensaje)

        else:
            for email in destinatarios:
                enviar_correo(email, asunto, mensaje)

        if incluir_local and local_email:
            enviar_correo(local_email, asunto, mensaje)

        return {'mensaje': 'Notificaciones enviadas con éxito 💌'}, 200
