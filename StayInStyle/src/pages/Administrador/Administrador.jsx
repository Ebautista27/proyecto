import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom"; // Importamos Link y useNavigate para rutas
import axios from "axios"; // Para interactuar con el backend
import "./Administrador.css";

const Administrador = () => {
  const [photo, setPhoto] = useState(null); // Estado para almacenar la foto del administrador
  const [adminData, setAdminData] = useState({ nombre: "", email: "" }); // Estado para la información del administrador
  const [mensaje, setMensaje] = useState(""); // Mensaje para errores o éxitos
  const navigate = useNavigate(); // Para redirigir al usuario

  // Verificar si el usuario es administrador al cargar la página
  useEffect(() => {
    const token = localStorage.getItem("token");

    if (!token) {
      setMensaje("No tienes acceso. Inicia sesión.");
      navigate("/");
      return;
    }

    try {
      const payload = JSON.parse(atob(token.split(".")[1])); // Decodificar payload del token

      if (payload.email !== "superadmin@example.com") {
        navigate("/Administrador");
        return;
      }
    } catch (error) {
      setMensaje("Token inválido. Inicia sesión nuevamente.");
      navigate("/");
      return;
    }

    const fetchAdminData = async () => {
      try {
        const response = await axios.get("http://127.0.0.1:5000/superadmin", {
          headers: { Authorization: `Bearer ${token}` },
        });
        setAdminData(response.data);
        setPhoto(response.data.foto);
      } catch (error) {
        setMensaje("Error al cargar los datos del administrador.");
      }
    };

    fetchAdminData();
  }, [navigate]);




  return (
    <div className="admin-container">
      {/* Header con botón de cerrar sesión */}
      <div className="admin-header">
        <h1>Panel de Administrador</h1>
        
      </div>

      <div className="admin-layout">
        {/* Contenedor izquierdo: Información del administrador */}
        <div className="admin-info">
          <div className="admin-photo">
            {photo ? (
              <img src={photo} alt="Admin" className="admin-photo-img" />
            ) : (
              <span>Sin Foto</span>
            )}
            <label htmlFor="photo-upload" className="photo-btn">
              +
            </label>
            <input
              type="file"
              id="photo-upload"
              style={{ display: "none" }}
              onChange={(e) => {
                const file = e.target.files[0];
                if (file) {
                  const reader = new FileReader();
                  reader.onload = (e) => {
                    setPhoto(e.target.result);
                  };
                  reader.readAsDataURL(file);
                  setMensaje("Foto cargada exitosamente.");
                }
              }}
            />
            {photo && (
              <button className="photo-btn delete" onClick={() => setPhoto(null)}>
                X
              </button>
            )}
          </div>
          <h2>Bienvenidos, Administradores</h2>
          <p className="nombres">Nombre: Stif Mejor Admin</p>
          <p className="nombres">Nombre: Dilan Mejor Admin</p>

          {mensaje && <p className="mensaje">{mensaje}</p>}
        </div>

        {/* Contenedor derecho: Menú de gestión */}
        <div className="admin-menu">
          <h2>Gestión de Stock</h2>
          <div className="admin-menu-buttons">
            <Link to="/Administradores/adminUsuarios">
              <button className="btn">Gestión de Usuarios</button>
            </Link>
            <Link to="/Administradores/AdminProductos">
              <button className="btn">Gestión de Productos</button>
            </Link>
            <Link to="/Administradores/adminpedidos">
              <button className="btn">Gestión de Pedidos</button>
            </Link>
            <Link to="/Administradores/adminreseñas">
              <button className="btn">Gestión de Reseñas</button>
            </Link>
            <Link to="/Administradores/AdminStock">
              <button className="btn">Gestión de Stock</button>
            </Link>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer>
        &copy; {new Date().getFullYear()} Stay in Style - Todos los derechos reservados.
      </footer>
    </div>
  );
};

export default Administrador;
  