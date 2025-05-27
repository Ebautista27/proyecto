import React, { useEffect } from "react";
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';
import { useCarrito } from "../../../context/CarritoContext";
import "./carrito.css";

const Carrito = () => {
  const navigate = useNavigate();
  const { 
    carrito, 
    loading, 
    error,
    eliminarProducto,
    actualizarCantidad,
    obtenerCarrito,
    vaciarCarrito
  } = useCarrito();

  useEffect(() => {
    obtenerCarrito();
  }, [obtenerCarrito]);

  const getImageUrl = (imagenUrl) => {
    if (!imagenUrl) return "https://placehold.co/300x300?text=Imagen+no+disponible";
    if (imagenUrl.startsWith('http')) return imagenUrl;
    return `https://res.cloudinary.com/dodecmh9s/image/upload/w_300,h_300,c_fill/${imagenUrl}`;
  };

  const calcularTotal = () => {
    if (!carrito?.productos || carrito.productos.length === 0) return 0;
    return carrito.total || carrito.productos.reduce((total, producto) => total + producto.subtotal, 0);
  };

  const handleComprar = () => {
    if (!localStorage.getItem("token")) {
      Swal.fire({
        title: 'Inicia sesión',
        text: 'Debes iniciar sesión para continuar',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Ir a login',
        cancelButtonText: 'Cancelar'
      }).then((result) => {
        if (result.isConfirmed) navigate('/login');
      });
      return;
    }

    if (!carrito?.productos?.length) {
      Swal.fire('Carrito vacío', 'Agrega productos al carrito', 'warning');
      return;
    }

    navigate('/Usuarios/Comprar');
  };

  const handleEliminar = async (productoId, id_talla) => {
    const result = await Swal.fire({
      title: '¿Eliminar producto?',
      text: "Esta acción no se puede deshacer",
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    });

    if (result.isConfirmed) {
      await eliminarProducto(productoId, id_talla);
      Swal.fire('Eliminado', 'Producto removido del carrito', 'success');
    }
  };

  const handleVaciarCarrito = async () => {
    const result = await Swal.fire({
      title: '¿Vaciar carrito?',
      text: "Se eliminarán todos los productos",
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Sí, vaciar',
      cancelButtonText: 'Cancelar'
    });

    if (result.isConfirmed) {
      await vaciarCarrito();
      Swal.fire('Carrito vacío', 'Todos los productos fueron eliminados', 'success');
    }
  };

  if (loading) {
    return (
      <div className="carrito-container">
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Cargando tu carrito...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="carrito-container">
        <div className="error-container">
          <p>{error}</p>
          <button onClick={obtenerCarrito}>Reintentar</button>
        </div>
      </div>
    );
  }

  return (
    <div className="carrito-container">
      <h1>Tu Carrito de Compras</h1>
      
      <div className="cart-content">
        {!carrito?.productos?.length ? (
          <div className="empty-cart">
            <p>No hay productos en tu carrito</p>
            <button 
              onClick={() => navigate('/')}
              className="btn-continue-shopping"
            >
              Seguir comprando
            </button>
          </div>
        ) : (
          <>
            <div className="cart-items">
              {carrito.productos.map((producto) => (
                <div key={`${producto.id_producto}-${producto.id_talla}`} className="cart-item">
                  <div className="item-image">
                    <img
                      src={getImageUrl(producto.imagen_url)}
                      alt={producto.nombre}
                      onError={(e) => {
                        e.target.onerror = null;
                        e.target.src = 'https://placehold.co/300x300?text=Imagen+no+disponible';
                      }}
                    />
                  </div>
                  
                  <div className="item-details">
                    <h3>{producto.nombre}</h3>
                    <p>Talla: {producto.talla}</p>
                    <p>Precio unitario: ${producto.precio_unitario.toLocaleString()}</p>
                    <p>Stock disponible: {producto.stock_disponible}</p>
                    
                    <div className="quantity-control">
                      <button
                        onClick={() => actualizarCantidad(producto.id_producto, producto.id_talla, producto.cantidad - 1)}
                        disabled={producto.cantidad <= 1}
                      >
                        -
                      </button>
                      <span>{producto.cantidad}</span>
                      <button
                        onClick={() => actualizarCantidad(producto.id_producto, producto.id_talla, producto.cantidad + 1)}
                        disabled={!producto.puede_aumentar}
                      >
                        +
                      </button>
                    </div>
                    
                    <p>Subtotal: ${producto.subtotal.toLocaleString()}</p>
                  </div>
                  
                  <button
                    onClick={() => handleEliminar(producto.id_producto, producto.id_talla)}
                    className="btn-remove"
                  >
                    Eliminar
                  </button>
                </div>
              ))}
            </div>
            
            <div className="cart-summary">
              <div className="cart-total">
                <h3>Total: ${calcularTotal().toLocaleString()}</h3>
              </div>
              
              <div className="cart-actions">
                <button 
                  onClick={handleVaciarCarrito}
                  className="btn-clear-cart"
                >
                  Vaciar Carrito
                </button>
                
                <button
                  onClick={handleComprar}
                  className="btn-checkout"
                >
                  Proceder al Pago
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default Carrito;