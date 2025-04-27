from flaskr import create_app
from flaskr.modelos import db, Rol, Usuario

def seed_roles():
    app = create_app()
    with app.app_context():
        db.create_all()

        # Inicialización de roles
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
        
        # Crear un superadmin si no existe
        if not Usuario.query.filter_by(email="superadmin@example.com").first():
            superadmin = Usuario(
                nombre="Super Admin",
                email="superadmin@example.com",
                num_cel="3170000000",
                direccion="Calle Ficticia 123",
                contrasena="superadmin123",  # Contraseña sin encriptar, el setter se encargará de encriptarla
                id_rol=1  # Rol de Administrador
            )
            db.session.add(superadmin)
            db.session.commit()
            print("Superadmin creado correctamente.")
        else:
            print("El superadmin ya existe.")

if __name__ == "__main__":
    seed_roles()
