import React, { useState, useEffect } from "react";
import AOS from "aos";
import "aos/dist/aos.css";
import "./adminUsuarios.css";

const AdminUsuarios = () => {
  const [usuarios, setUsuarios] = useState([]);
  const [roles, setRoles] = useState([]);
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
  const [loading, setLoading] = useState(false);
  const token = localStorage.getItem("token");

  // Inicializar AOS y cargar datos al montar el componente
  useEffect(() => {
    AOS.init();
    fetchRoles();
    fetchUsuarios();
  }, []);

  // Obtener la lista de roles desde el backend
  const fetchRoles = async () => {
    try {
      const response = await fetch("http://127.0.0.1:5000/roles", {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await response.json();
      if (response.ok) {
        setRoles(data.roles);
      } else {
        setMensaje(data.mensaje || "Error al cargar los roles.");
      }
    } catch (error) {
      setMensaje("Error al cargar los roles.");
      console.error("Error fetching roles:", error);
    }
  };

  // Obtener la lista de usuarios desde el backend
  const fetchUsuarios = async () => {
    setLoading(true);
    try {
      const response = await fetch("http://127.0.0.1:5000/usuarios", {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await response.json();
      if (response.ok) {
        setUsuarios(data.usuarios || data); // Adaptación para ambas estructuras
      } else {
        setMensaje(data.mensaje || "Error al cargar los usuarios.");
      }
    } catch (error) {
      setMensaje("Error al cargar los usuarios.");
      console.error("Error fetching usuarios:", error);
    } finally {
      setLoading(false);
    }
  };

  // Manejar cambios en los campos del formulario
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
    setMensaje("");
  };

  // Manejar el envío del formulario (crear o actualizar usuario)
  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.id_rol) {
      setMensaje("Por favor, seleccione un rol.");
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
          id_rol: parseInt(formData.id_rol),
        }),
      });

      const data = await response.json();
      if (response.ok) {
        setMensaje(editData ? "Usuario actualizado correctamente" : "Usuario creado exitosamente");
        fetchUsuarios();
        resetForm();
      } else {
        setMensaje(data.mensaje || "Error al procesar la solicitud.");
      }
    } catch (error) {
      setMensaje("Error de conexión con el servidor.");
      console.error("Error saving usuario:", error);
    }
  };

  // Resetear formulario
  const resetForm = () => {
    setFormData({
      nombre: "",
      email: "",
      contrasena: "",
      id_rol: "",
      num_cel: "",
      direccion: "",
    });
    setEditData(null);
  };

  // Manejar la edición de un usuario
  const handleEdit = (usuario) => {
    setEditData(usuario);
    setFormData({
      nombre: usuario.nombre,
      email: usuario.email,
      contrasena: "",
      id_rol: usuario.id_rol.toString(),
      num_cel: usuario.num_cel || "",
      direccion: usuario.direccion || "",
    });
  };

  // Manejar la eliminación de un usuario
  const handleDelete = async (id) => {
    if (!window.confirm("¿Está seguro que desea eliminar este usuario?")) {
      return;
    }

    try {
      const response = await fetch(`http://127.0.0.1:5000/usuarios/${id}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setMensaje("Usuario eliminado correctamente");
        fetchUsuarios();
      } else {
        const data = await response.json();
        setMensaje(data.mensaje || "Error al eliminar el usuario.");
      }
    } catch (error) {
      setMensaje("Error al eliminar el usuario.");
      console.error("Error deleting usuario:", error);
    }
  };

  // Obtener nombre del rol
  const getRolNombre = (id_rol) => {
    const rol = roles.find(r => r.id === Number(id_rol));
    return rol ? rol.nombre : "Rol no encontrado";
  };

  if (loading) {
    return (
      <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
        <div className="container">Cargando usuarios...</div>
      </div>
    );
  }

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
              required={!editData}
            />
            <select
              name="id_rol"
              value={formData.id_rol}
              onChange={handleChange}
              required
            >
              <option value="">Seleccione un rol</option>
              {roles.map(rol => (
                <option key={rol.id} value={rol.id}>
                  {rol.nombre}
                </option>
              ))}
            </select>
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
            {editData && (
              <button type="button" onClick={resetForm} style={{ marginLeft: '10px' }}>
                Cancelar
              </button>
            )}
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
              {usuarios.map(usuario => (
                <tr key={usuario.id}>
                  <td>{usuario.nombre}</td>
                  <td>{usuario.email}</td>
                  <td>{usuario.num_cel || "-"}</td>
                  <td>{usuario.direccion || "-"}</td>
                  <td>{getRolNombre(usuario.id_rol)}</td>
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