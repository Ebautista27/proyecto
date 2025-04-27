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


// Importar los archivos de detalle de productos
import DetalleProducto1 from "../pages/Productos/detalle_producto1";
import DetalleProducto2 from "../pages/Productos/detalle_producto2";
import DetalleProducto3 from "../pages/Productos/detalle_producto3";
import DetalleProducto4 from "../pages/Productos/detalle_producto4";
import DetalleProducto5 from "../pages/Productos/detalle_producto_camisa_blanca_overzice";
import DetalleProducto6 from "../pages/Productos/detalle_producto_camisa_negra_araña";
import DetalleProducto7 from "../pages/Productos/detalle_producto_camisa_blanca_llamas";
import DetalleProducto8 from "../pages/Productos/detalle_producto_camisa_negra_clasica";
import DetalleProducto9 from "../pages/Productos/detalle_producto_camisa_gris_AW_SPIKY_HEAD";
import DetalleProducto10 from "../pages/Productos/detalle_producto_camisa_blanca-gris_xomoclothes";
import DetalleProducto11 from "../pages/Productos/detalle_producto_camisa_negra-blanco_blackstar";
import DetalleProducto12 from "../pages/Productos/detalle_producto_camisa_negra_eterning";
import DetalleProducto13 from "../pages/Productos/detalle_producto_camisa_arena97";
import AdminReseñas from '../pages/Administradores/AdminReseñas/AdminReseñas';
import DetalleProducto14 from "../pages/Productos/detalle_producto_camisa_gris-negra";
import DetalleProducto15 from "../pages/Productos/detalle_producto_camisa_negra_sidesteet";
import DetalleProducto16 from "../pages/Productos/detalle_producto_camisa_negra_saint-tears";
import DetalleProducto17 from "../pages/Productos/detalle_producto_pantalonM_anything";
import DetalleProducto18 from "../pages/Productos/detalle_producto_pantalonM_Cargo_Morado";
import DetalleProducto19 from "../pages/Productos/detalle_producto_pantalonetaM_Cargo";
import DetalleProducto20 from "../pages/Productos/detalle_producto_pantalonM_Desteñido_llamas-Moradas";
import DetalleProducto21 from "../pages/Productos/dealle_producto_destacado_chaqueta_azul";
import DetalleProducto22 from "../pages/Productos/detalle_producto_destacado_camiseta_azul";
import DetalleProducto23 from "../pages/Productos/detalle_producto_destacado_chaqueta_negra";

// Importar los archivos de compra
import Confirmacion from "../pages/Usuarios/Comprar/Confirmación";



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
      <Route path="/Administradores/AdminReseñas" element={<AdminReseñas />} />
      <Route path="/Usuarios/sobre_nosotros/QueEsStayInStyle" element={<QueEsStayInStyle />} />
      <Route path="/Usuarios/sobre_nosotros/QuienesSomos" element={<QuienesSomos />} />

      {/* Rutas dinámicas para cada detalle de producto */}
      <Route path="/Productos/detalle_producto1" element={<DetalleProducto1 />} />
      <Route path="/Productos/detalle_producto2" element={<DetalleProducto2 />} />
      <Route path="/Productos/detalle_producto3" element={<DetalleProducto3 />} />
      <Route path="/Productos/detalle_producto4" element={<DetalleProducto4 />} />
      <Route path="/Productos/detalle_producto_camisa_blanca_overzice" element={<DetalleProducto5 />} />
      <Route path="/Productos/detalle_producto_camisa_negra_araña" element={<DetalleProducto6 />} />
      <Route path="/Productos/detalle_producto_camisa_blanca_llamas" element={<DetalleProducto7 />} />
      <Route path="/Productos/detalle_producto_camisa_negra_clasica" element={<DetalleProducto8 />} />
      <Route path="/Productos/detalle_producto_camisa_gris_AW_SPIKY_HEAD" element={<DetalleProducto9 />} />
      <Route path="/Productos/detalle_producto_camisa_blanca-gris_xomoclothes" element={<DetalleProducto10 />} />
      <Route path="/Productos/detalle_producto_camisa_negra-blanco_blackstar" element={<DetalleProducto11 />} />
      <Route path="/Productos/detalle_producto_camisa_negra_eterning" element={<DetalleProducto12 />} />
      <Route path="/Productos/detalle_producto_camisa_arena97" element={<DetalleProducto13 />} />
      <Route path="/Productos/detalle_producto_camisa_gris-negra" element={<DetalleProducto14 />} />
      <Route path="/Productos/detalle_producto_camisa_negra_sidesteet" element={<DetalleProducto15 />} />
      <Route path="/Productos/detalle_producto_camisa_negra_saint-tears" element={<DetalleProducto16 />} />
      <Route path="/Productos/detalle_producto_pantalonM_anything" element={<DetalleProducto17 />} />
      <Route path="/Productos/detalle_producto_pantalonM_Cargo_Morado" element={<DetalleProducto18 />} />
      <Route path="/Productos/detalle_producto_pantalonetaM_Cargo" element={<DetalleProducto19 />} />
      <Route path="/Productos/detalle_producto_pantalonM_Desteñido_llamas-Moradas" element={<DetalleProducto20 />} />
      <Route path="/Productos/dealle_producto_destacado_chaqueta_azul" element={<DetalleProducto21 />} />
      <Route path="/Productos/detalle_producto_destacado_camiseta_azul" element={<DetalleProducto22 />} />
      <Route path="/Productos/detalle_producto_destacado_chaqueta_negra" element={<DetalleProducto23 />} />
       {/* contraseña restablecer */}
      <Route path="/ForgotPassword" element={<ForgotPassword/>} />
      <Route path="/ResetPasswordPage/:token" element={<ResetPasswordPage />} />
      {/* compra */} 
      <Route path="/Confirmación" element={<Confirmacion/>} />


    </Routes>
  );
};

export default NavbarRoutes;
