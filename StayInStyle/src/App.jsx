import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, useLocation } from "react-router-dom";
import Navbar from "./components/Navbar/Navbar";
import NavbarRoutes from "./routes/NavbarRoutes";
import Footer from "./components/Footer/Footer";
import { CarritoProvider } from "./context/CarritoContext"; // Importa el Provider
import "./App.css";
import 'bootstrap/dist/css/bootstrap.min.css';

// Componente wrapper para controlar la visibilidad del Footer
const LayoutWrapper = ({ children }) => {
  const location = useLocation();
  const [showFooter, setShowFooter] = useState(true);

  useEffect(() => {
    // Ocultar Footer en rutas de administración
    const adminPaths = ['/Administrador', '/adminUsuarios', '/adminproductos', '/adminpedidos'];
    const isAdminPath = adminPaths.some(path => location.pathname.startsWith(path));
   
    setShowFooter(!isAdminPath);
  }, [location]);

  return (
    <>
      {/* Navbar siempre visible */}
      <Navbar />
     
      <div className="content">
        {children}
      </div>

      {/* Footer condicional */}
      {showFooter && <Footer />}
    </>
  );
};

function App() {
  return (
    <Router>
      <CarritoProvider> {/* Envuelve todo con el Provider del carrito */}
        <LayoutWrapper>
          <NavbarRoutes />
        </LayoutWrapper>
      </CarritoProvider>
    </Router>
  );
}

export default App;