import React from 'react';
import "./Footer.css";

const Footer = () => {
  return (
    <footer>
      <div className="footer-section">
        <h3>SOBRE NOSOTROS</h3>
        <ul>
          <li><a href="/Usuarios/sobre_nosotros/QuienesSomos">¿Quiénes somos?</a></li>
          <li><a href="/Usuarios/sobre_nosotros/QueEsStayInStyle">¿Qué es Stay in Style?</a></li>
        </ul>
      </div>
      <div className="footer-section">
        <h3>NUESTRAS CATEGORÍAS</h3>
        <ul>
          <li><a href="/Usuarios/Categorias/Categoriash">Hombre</a></li>
          <li><a href="/Usuarios/Categorias/Categoriasm">Mujer</a></li>
        </ul>
      </div>
      <div className="footer-section">
        <h3>SÍGUENOS</h3>
        <ul className="social-media">
          <li><a href="https://facebook.com" target="_blank" rel="noopener noreferrer"><img src="/src/assets/Imagenes/facebook.jpg" alt="Facebook" /></a></li>
          <li><a href="https://instagram.com" target="_blank" rel="noopener noreferrer"><img src="/src/assets/Imagenes/instragram.jpg" alt="Instagram" /></a></li>
          <li><a href="https://tiktok.com" target="_blank" rel="noopener noreferrer"><img src="/src/assets/Imagenes/tiktok.jpg" alt="TikTok" /></a></li>
        </ul>
      </div>
    </footer>
  );
};

export default Footer;
