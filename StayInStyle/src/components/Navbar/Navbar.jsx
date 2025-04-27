import React from "react";
import "./Navbar.css";
import '@fortawesome/fontawesome-free/css/all.min.css';

const Navbar = () => {
  const cerrarSesion = () => {
    localStorage.clear(); // Elimina todo del localStorage
    window.location.href = "/"; // Redirige al login
  };

  return (
    <header>
      <div className="logo-container">
        <a href="/" className="logo-link">
          <img
            src="/src/assets/Imagenes/Stay_In_Style.png"
            alt="Logo"
            className="logo-image"
          />
          <span className="logo-text">Stay in Style</span>
        </a>
      </div>
      <nav>
        <ul>
          <li>
            <a href="/">
              <i className="fas fa-home"></i> Inicio
            </a>
          </li>
          <li>
            <a href="/IniciarSesion">
              <i className="fas fa-user"></i> Iniciar Sesión
            </a>
          </li>
          <li>
            <a href="/Registro">
              <i className="fas fa-user-plus"></i> Registrarse
            </a>
          </li>
          <li>
            <a href="/Carrito">
              <i className="fas fa-shopping-cart"></i> Carrito
            </a>
          </li>
          <li>
            <a href="#">
              <i className="fas fa-th-large"></i> Categorías
            </a>
            <ul>
              <li>
                <a href="/Usuarios/Categorias/Categoriash">Hombre</a>
              </li>
              <li>
                <a href="/Usuarios/Categorias/Categoriasm">Mujer</a>
              </li>
            </ul>
          </li>
          <li>
            <button className="cerrar-sesion-btn" onClick={cerrarSesion}>
              <i className="fas fa-sign-out-alt"></i> Cerrar Sesión
            </button>
          </li>
        </ul>
      </nav>
    </header>
  );
};

export default Navbar;
