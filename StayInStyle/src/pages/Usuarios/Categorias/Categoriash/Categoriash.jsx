import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import axios from "axios";
import BuscadorProductos from "../../../../components/Buscador/BuscadorProductos";
import "./Categoriash.css";

const Categoriash = () => {
  const [productos, setProductos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Función para verificar disponibilidad simplificada
  const verificarDisponibilidad = (producto) => {
    return producto.estado !== "Agotado" && producto.estado !== "No disponible";
  };

  useEffect(() => {
    const cargarProductos = async () => {
      try {
        // Obtenemos todos los productos
        const response = await axios.get('http://127.0.0.1:5000/productos');
        
        // Filtramos y mapeamos los productos para hombres (id_genero = 1)
        const productosHombres = response.data
          .filter(producto => producto.id_genero === 1)
          .map(producto => ({
            ...producto,
            imagen_url: producto.imagen_url || 'https://via.placeholder.com/300?text=Imagen+no+disponible',
            disponible: verificarDisponibilidad(producto)
          }));
        
        setProductos(productosHombres);
      } catch (err) {
        console.error("Error al obtener productos:", err);
        setError("Error al cargar los productos. Intenta recargar la página.");
      } finally {
        setLoading(false);
      }
    };

    cargarProductos();
  }, []);

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Cargando productos...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <p>{error}</p>
        <button onClick={() => window.location.reload()}>Recargar página</button>
      </div>
    );
  }

  return (
    <div className="hombres-container">
      <div className="buscador-container-home">
        <BuscadorProductos />
      </div>
      <h2>Prendas para Hombres</h2>
      {productos.length === 0 ? (
        <p className="no-products">No hay productos disponibles en esta categoría</p>
      ) : (
        <section className="vitrina">
          {productos.map((producto) => (
            <div className="producto" key={producto.id}>
              <Link to={`/productos/${producto.id}`}>
                <img 
                  src={producto.imagen_url} 
                  alt={producto.nombre}
                  onError={(e) => {
                    e.target.src = 'https://via.placeholder.com/300?text=Imagen+no+disponible';
                    console.error('Error cargando imagen:', producto.imagen_url);
                  }}
                  loading="lazy"
                />
              </Link>
              <div className="producto-info">
                <h3>{producto.nombre}</h3>
                <p>${producto.precio.toLocaleString('es-CO')} COP</p>
                <span className={`estado ${producto.disponible ? 'disponible' : 'agotado'}`}>
                  {producto.disponible ? 'Disponible' : 'Agotado'}
                </span>
              </div>
            </div>
          ))}
        </section>
      )}
    </div>
  );
};

export default Categoriash;