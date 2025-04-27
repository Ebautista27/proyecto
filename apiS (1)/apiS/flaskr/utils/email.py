from flask_mail import Message
from ..extensiones import mail
from flask import current_app, render_template

def enviar_correo(destinatario, asunto, contenido_html):
    with current_app.app_context():
        mensaje = Message(subject=asunto, recipients=[destinatario])
        mensaje.html = render_template("email_template.html", contenido=contenido_html)
        mail.send(mensaje)