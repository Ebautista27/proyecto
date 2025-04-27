import React, { useState, useEffect } from "react";
import AOS from "aos";
import "aos/dist/aos.css";
import "./adminUsuarios.css";

const AdminUsuarios = () => {
  const [usuarios, setUsuarios] = useState([]);
  const [formData, setFormData] = useState({
    nombre: "",
    email: "",
    contrasena: "",
    id_rol: "",
    num_cel: "",
    direccion: "",
  });
  const [editData, setEditData] = useState(null);
  const [mensaje, setMensaje] = useState("");
  const token = localStorage.getItem("token");

  // Inicializar AOS y cargar usuarios al montar el componente
  useEffect(() => {
    AOS.init();
    fetchUsuarios();
  }, []);

  // Obtener la lista de usuarios desde el backend
  const fetchUsuarios = async () => {
    try {
      const response = await fetch("http://127.0.0.1:5000/usuarios", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      const data = await response.json();
      if (response.ok) {
        setUsuarios(data); // Guardar los usuarios en el estado
      } else {
        setMensaje(data.mensaje || "Error al cargar los usuarios.");
      }
    } catch (error) {
      setMensaje("Error al cargar los usuarios.");
      console.error("Error fetching usuarios:", error);
    }
  };

  // Manejar cambios en los campos del formulario
  const handleChange = (e) => {
    const { name, value } = e.target;

    // Validar que el id_rol solo acepte 1 o 2
    if (name === "id_rol" && value !== "" && !["1", "2"].includes(value)) {
      setMensaje("El rol debe ser 1 (Usuario) o 2 (Administrador).");
      return;
    }

    setMensaje("");
    setFormData({ ...formData, [name]: value });
  };

  // Manejar el envío del formulario (crear o actualizar usuario)
  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validar que el id_rol sea 1 o 2 antes de enviar
    if (!["1", "2"].includes(formData.id_rol)) {
      setMensaje("Por favor, ingrese un rol válido: 1 (Usuario) o 2 (Administrador).");
      return;
    }

    const url = editData
      ? `http://127.0.0.1:5000/usuarios/${editData.id}`
      : "http://127.0.0.1:5000/usuarios";
    const method = editData ? "PUT" : "POST";

    try {
      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          ...formData,
          id_rol: parseInt(formData.id_rol), // Convertir a número antes de enviar
        }),
      });

      const data = await response.json();
      if (response.ok) {
        setMensaje(editData ? "Usuario actualizado" : "Usuario creado");
        fetchUsuarios(); // Recargar la lista de usuarios
        setFormData({
          nombre: "",
          email: "",
          contrasena: "",
          id_rol: "",
          num_cel: "",
          direccion: "",
        });
        setEditData(null);
      } else {
        setMensaje(data.mensaje || "Error al guardar el usuario.");
      }
    } catch (error) {
      setMensaje("Error al guardar el usuario.");
      console.error("Error saving usuario:", error);
    }
  };

  // Manejar la edición de un usuario
  const handleEdit = (usuario) => {
    setEditData(usuario);
    setFormData({
      nombre: usuario.nombre,
      email: usuario.email,
      contrasena: "",
      id_rol: usuario.id_rol.toString(),
      num_cel: usuario.num_cel,
      direccion: usuario.direccion,
    });
  };

  // Manejar la eliminación de un usuario
  const handleDelete = async (id) => {
    try {
      const response = await fetch(`http://127.0.0.1:5000/usuarios/${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        setMensaje("Usuario eliminado");
        fetchUsuarios(); // Recargar la lista de usuarios
      } else {
        const data = await response.json();
        setMensaje(data.mensaje || "Error al eliminar el usuario.");
      }
    } catch (error) {
      setMensaje("Error al eliminar el usuario.");
      console.error("Error deleting usuario:", error);
    }
  };

  return (
    <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
      <div className="container">
        <h1 data-aos="fade-down" data-aos-duration="1000">Gestión de Usuarios</h1>

        {mensaje && <div className="alert alert-info">{mensaje}</div>}

        <div className="form-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>{editData ? "Editar Usuario" : "Crear Usuario"}</h2>
          <form onSubmit={handleSubmit}>
            <input
              type="text"
              name="nombre"
              placeholder="Nombre"
              value={formData.nombre}
              onChange={handleChange}
              required
            />
            <input
              type="email"
              name="email"
              placeholder="Email"
              value={formData.email}
              onChange={handleChange}
              required
            />
            <input
              type="password"
              name="contrasena"
              placeholder="Contraseña"
              value={formData.contrasena}
              onChange={handleChange}
              required={!editData} // Solo requerido al crear
            />
            <input
              type="text"
              name="id_rol"
              placeholder="Rol (1: Usuario, 2: Administrador)"
              value={formData.id_rol}
              onChange={handleChange}
              required
            />
            <input
              type="text"
              name="num_cel"
              placeholder="Teléfono"
              value={formData.num_cel}
              onChange={handleChange}
            />
            <input
              type="text"
              name="direccion"
              placeholder="Dirección"
              value={formData.direccion}
              onChange={handleChange}
            />
            <button type="submit">
              {editData ? "Actualizar Usuario" : "Crear Usuario"}
            </button>
          </form>
        </div>

        <div className="usuarios-list" data-aos="fade-up" data-aos-duration="2000">
          <h2>Lista de Usuarios</h2>
          <table>
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Email</th>
                <th>Teléfono</th>
                <th>Dirección</th>
                <th>Rol</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {usuarios.map((usuario) => (
                <tr key={usuario.id}>
                  <td>{usuario.nombre}</td>
                  <td>{usuario.email}</td>
                  <td>{usuario.num_cel}</td>
                  <td>{usuario.direccion}</td>
                  <td>{usuario.id_rol === 1 ? "Usuario" : "Administrador"}</td>
                  <td>
                    <button onClick={() => handleEdit(usuario)}>Editar</button>
                    <button onClick={() => handleDelete(usuario.id)}>Eliminar</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminUsuarios;