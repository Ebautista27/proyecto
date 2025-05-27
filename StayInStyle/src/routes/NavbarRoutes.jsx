import React from "react";
import { Route, Routes } from "react-router-dom";

// Importar los componentes de las páginas
import Home from '../pages/Home/Home';
import Registro from '../pages/Registro/Registro';
import IniciarSesion from '../pages/iniciarSesion/iniciarSesion';
import Administrador from '../pages/Administrador/Administrador';
import Comprar from '../pages/Usuarios/Comprar/Comprar';
import Carrito from '../pages/Usuarios/Carrito/Carrito';
import Categoriash from "../pages/Usuarios/Categorias/Categoriash/Categoriash";
import Categoriasm from "../pages/Usuarios/Categorias/Categoriasm/Categoriasm";
import AdminUsuarios from '../pages/Administradores/adminUsuarios/adminUsuarios';
import AdminProductos from '../pages/Administradores/adminproductos/adminproductos';
import AdminPedidos from '../pages/Administradores/AdminPedidos/AdminPedidos';
import QueEsStayInStyle from "../pages/Usuarios/sobre_nosotros/QueEsStayInStyle";
import QuienesSomos from "../pages/Usuarios/sobre_nosotros/QuienesSomos";
import ForgotPassword from '../components/Auth/ForgotPassword';
import ResetPasswordPage from '../components/Auth/ResetPasswordPage';



import DetalleProducto from "../pages/Productos/DetalleProducto";

// Importar los archivos de compra
import Confirmacion from "../pages/Usuarios/Comprar/Confirmación";

// Importación (asumiendo export default)
import AdminReseñas from "../pages/Administradores/AdminReseñas/AdminReseñas";

import AdminStock from "../pages/Administradores/AdminStock/Adminstock"

import HistorialCompras from "../pages/Usuarios/Comprar/HistorialCompras"



import Pedido from "../pages/Usuarios/Comprar/Pedido"



const NavbarRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/Registro" element={<Registro />} />
      <Route path="/IniciarSesion" element={<IniciarSesion />} />
      <Route path="/Administrador" element={<Administrador />} />
      <Route path="/Carrito" element={<Carrito />} />
      <Route path="Usuarios/Comprar" element={<Comprar />} />
      <Route path="/Usuarios/Categorias/Categoriash" element={<Categoriash />} />
      <Route path="/Usuarios/Categorias/Categoriasm" element={<Categoriasm />} />
      <Route path="/Administradores/adminUsuarios" element={<AdminUsuarios />} />
      <Route path="/Administradores/adminproductos" element={<AdminProductos />} />
      <Route path="/Administradores/AdminPedidos" element={<AdminPedidos />} />

      <Route path="/Usuarios/sobre_nosotros/QueEsStayInStyle" element={<QueEsStayInStyle />} />

      <Route path="/Administradores/AdminReseñas" element={<AdminReseñas />} />

      <Route path="/Usuarios/sobre_nosotros/QuienesSomos" element={<QuienesSomos />} />

      {/* Ruta dinámica para todos los productos */}
      <Route path="/productos/:id" element={<DetalleProducto />} />
       {/* contraseña restablecer */}
      <Route path="/ForgotPassword" element={<ForgotPassword/>} />
      <Route path="/ResetPasswordPage/:token" element={<ResetPasswordPage />} />
      {/* compra */} 
      <Route path="/Confirmación" element={<Confirmacion/>} />

      <Route path="/Administradores/Adminstock" element={<AdminStock/>} />

      <Route path="/historial-compras" element={<HistorialCompras />} />

      <Route path="/pedido" element={<Pedido />} />
      


    </Routes>
  );
};

export default NavbarRoutes;
