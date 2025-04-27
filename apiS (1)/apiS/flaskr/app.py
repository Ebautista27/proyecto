from flask import Flask, request, jsonify
from flaskr import create_app
from flaskr.modelos import db, Rol
import cloudinary
import cloudinary.api
import cloudinary.uploader
import os
import logging

# Cargar la configuración desde config.py
app = create_app()

# Configuración para el modo de depuración y desarrollo
app.config['ENV'] = 'development'
app.config['DEBUG'] = True

# Configuración del logger
logging.basicConfig(level=logging.DEBUG)

# Cargar la configuración de Cloudinary
cloudinary.config(
    cloud_name=os.getenv('CLOUDINARY_CLOUD_NAME'),
    api_key=os.getenv('CLOUDINARY_API_KEY'),
    api_secret=os.getenv('CLOUDINARY_API_SECRET')
)

# Función para inicializar roles
def seed_roles():
    with app.app_context():
        db.create_all()
        if not Rol.query.first():
            roles = [
                Rol(id=1, nombre="Administrador"),
                Rol(id=2, nombre="Usuario")
            ]
            db.session.bulk_save_objects(roles)
            db.session.commit()
            print("Roles inicializados correctamente.")
        else:
            print("Los roles ya están inicializados.")

# Endpoint para cargar una imagen
@app.route('/upload_image', methods=['POST'])
def upload_image():
    if 'image' not in request.files:
        logging.error("No image file in request")
        return jsonify({"error": "No image file"}), 400

    file = request.files['image']
    try:
        # Sube la imagen a Cloudinary
        upload_result = cloudinary.uploader.upload(file)
        image_url = upload_result['url']
        logging.info(f"Image uploaded successfully: {image_url}")
        return jsonify({"image_url": image_url}), 200
    except Exception as e:
        logging.error(f"Error uploading image: {str(e)}")
        return jsonify({"error": str(e)}), 500
    
@app.route('/routes', methods=['GET'])
def listar_rutas():
    """Devuelve una lista de todas las rutas registradas en la aplicación."""
    rutas = []
    for rule in app.url_map.iter_rules():
        rutas.append({
            "endpoint": rule.endpoint,
            "methods": list(rule.methods),
            "url": str(rule)
        })
    return jsonify(rutas)


if __name__ == "__main__":
    logging.info("Starting the Flask application")
    app.run(debug=True, port=5001)  # Cambia 5001 al puerto que desees usar














if __name__ == '__main__':
    seed_roles()  # Inicializa los roles si no existen
    app.run(debug=True)
