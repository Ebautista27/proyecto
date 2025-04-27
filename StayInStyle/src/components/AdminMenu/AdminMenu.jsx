import React from "react";
import "./AdminMenu.css"; // Asegúrate de que los estilos estén bien definidos

const MenuAdmin = () => {
  return (
    <div className="admin-container">
      <h2>Gestión de Stock</h2>
      <div className="admin-options">
        <button
          className="admin-btn"
          onClick={() => (window.location.href = "/Administradores/adminUsuarios")}
        >
          Gestión de Usuarios
        </button>
        <button
          className="admin-btn"
          onClick={() => (window.location.href = "/Administradores/adminproductos")}
        >
          Gestión de Productos
        </button>
        <button
          className="admin-btn"
          onClick={() => (window.location.href = "/Administradores/adminpedidos")}
        >
          Gestión de Pedidos
        </button>
      </div>
    </div>
  );
};

export default MenuAdmin;
