import React from "react";
import { Route, Routes } from "react-router-dom";

import Administrador from "../pages/Administrador/Administrador"; // Página principal del menú admin
import AdminUsuarios from "../pages/Administradores/adminUsuarios/adminUsuarios"; // Gestión de usuarios
import AdminProductos from "../pages/Administradores/adminproductos/adminproductos"; // Gestión de productos
import AdminStock from "../pages/Administradores/AdminStock/Adminstock";


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

       {/* Ruta simple para AdminStock */}
      <Route path="/admin/stock" element={<AdminStock />} />
    </Routes>
  );
};

export default AdminRoutes;
