import React, { useState, useEffect } from "react";
import "./carrito.css";
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2'; // Para alertas bonitas (opcional)

const Carrito = () => {
  const [carrito, setCarrito] = useState([]);
  const [showLoginMessage, setShowLoginMessage] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const carritoGuardado = JSON.parse(localStorage.getItem("carrito")) || [];
    setCarrito(carritoGuardado);
  }, []);

  const eliminarDelCarrito = (index) => {
    const nuevoCarrito = carrito.filter((_, i) => i !== index);
    setCarrito(nuevoCarrito);
    localStorage.setItem("carrito", JSON.stringify(nuevoCarrito));
  };

  const calcularTotal = () => {
    return carrito.reduce((total, producto) => {
      return total + (parseInt(producto.precio) * producto.cantidad);
    }, 0);
  };

  const handleComprar = () => {
    // Verificar si el token existe
    const token = localStorage.getItem('token'); // O sessionStorage, según tu implementación
    
    if (!token) {
      // Mostrar mensaje de que debe iniciar sesión
      Swal.fire({
        title: '¡Inicia sesión primero!',
        text: 'Debes iniciar sesión para realizar compras',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Ir a Iniciar Sesión',
        cancelButtonText: 'Seguir comprando',
        customClass: {
          popup: 'custom-swal-popup' // Clase CSS personalizada si necesitas
        }
      }).then((result) => {
        if (result.isConfirmed) {
          navigate('/IniciarSesion');
        }
      });
      
      // Alternativa sin SweetAlert:
      // setShowLoginMessage(true);
      return;
    }
    
    // Si hay token, redirigir a la página de compra
    navigate('../Usuarios/Comprar');
  };

  return (
    <div style={{
      backgroundColor: "#E5E1DA",
      minHeight: "100vh",
      padding: "20px 0"
    }}>
      <div className="carrito-container">
        <h1>Carrito de Compras</h1>
        
        {/* Mensaje de login (versión simple) */}
        {showLoginMessage && (
          <div className="login-message">
            <p>Debes iniciar sesión para comprar</p>
            <button 
              onClick={() => navigate('/IniciarSesion')}
              className="login-btn"
            >
              Ir a Iniciar Sesión
            </button>
          </div>
        )}

        {carrito.length === 0 ? (
          <p className="carrito-vacio">El carrito está vacío.</p>
        ) : (
          <>
            <div className="carrito-items">
              {carrito.map((producto, index) => (
                <div key={index} className="producto-carrito">
                  <div className="producto-contenido">
                    <img
                      src={producto.imagen}
                      alt={producto.nombre}
                      className="producto-imagen22"
                      onError={(e) => {
                        e.target.onerror = null;
                        e.target.src = 'https://via.placeholder.com/120';
                      }}
                    />
                    <div className="producto-detalle">
                      <h2>{producto.nombre}</h2>
                      <div className="producto-especificaciones">
                        <p><strong>Precio:</strong> {producto.precio.toLocaleString()} pesos</p>
                        <p><strong>Cantidad:</strong> {producto.cantidad}</p>
                        <p><strong>Talla:</strong> {producto.talla}</p>
                      </div>
                    </div>
                  </div>
                  <button
                    onClick={() => eliminarDelCarrito(index)}
                    className="eliminar-btn"
                  >
                    Eliminar
                  </button>
                </div>
              ))}
            </div>

            <div className="carrito-footer">
              <div className="carrito-total">
                <p><strong>Total:</strong> {calcularTotal().toLocaleString()} mil pesos</p>
              </div>
              <button
                id="comprar-btn"
                onClick={handleComprar}
              >
                Comprar
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default Carrito;