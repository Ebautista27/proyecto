import React from "react";
import { Route, Routes } from "react-router-dom";

import Administrador from "../pages/Administrador/Administrador"; // Página principal del menú admin
import AdminUsuarios from "../pages/Administradores/adminUsuarios/adminUsuarios"; // Gestión de usuarios
import AdminProductos from "../pages/Administradores/adminproductos/adminproductos"; // Gestión de productos
import AdminPedidos from "../pages/Administradores/adminpedidos/adminpedidos"; // Gestión de pedidos

const AdminRoutes = () => {
  return (
    <Routes>
      {/* Ruta principal del administrador */}
      <Route path="/" element={<Administrador />} />

      {/* Ruta para la gestión de usuarios */}
      <Route path="/adminUsuarios" element={<AdminUsuarios />} />

      {/* Ruta para la gestión de productos */}
      <Route path="/adminproductos" element={<AdminProductos />} />

      {/* Ruta para la gestión de pedidos */}
      <Route path="/adminpedidos" element={<AdminPedidos />} />
    </Routes>
  );
};

export default AdminRoutes;
