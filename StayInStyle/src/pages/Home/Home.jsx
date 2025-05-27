import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import axios from "axios";
import CustomCarousel from "../../components/CustomCarousel/CustomCarousel";
import BuscadorProductos from "../../components/Buscador/BuscadorProductos";
import "./Home.css";

const Home = () => {
  const [productos, setProductos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Función para asegurar que la URL de la imagen es correcta
  const getImageUrl = (imagenUrl) => {
    if (!imagenUrl) return null;
    
    if (imagenUrl.includes('res.cloudinary.com')) {
      return imagenUrl;
    }
    
    if (!imagenUrl.startsWith('http')) {
      return `https://res.cloudinary.com/dodecmh9s/image/upload/${imagenUrl}`;
    }
    
    return imagenUrl;
  };

  // Función simplificada para verificar disponibilidad
  const verificarDisponibilidad = async (productoId) => {
    try {
      const response = await axios.get(`http://127.0.0.1:5000/productos/${productoId}`);
      return response.data.disponible !== false && response.data.estado !== "Agotado";
    } catch (error) {
      console.error(`Error al verificar disponibilidad para producto ${productoId}:`, error);
      return false;
    }
  };

  useEffect(() => {
    const cargarProductos = async () => {
      try {
        // Cargar los 4 productos específicos
        const productosIds = [1, 2, 3, 4];  
        
        // Obtener los datos básicos de los productos
        const productosPromises = productosIds.map(id => 
          axios.get(`http://127.0.0.1:5000/productos/${id}`)
        );
        
        const responses = await Promise.all(productosPromises);
        
        // Verificar disponibilidad para cada producto
        const disponibilidadPromises = responses.map(res => 
          verificarDisponibilidad(res.data.id)
        );
        const disponibilidades = await Promise.all(disponibilidadPromises);
        
        // Combinar los datos
        const productosData = responses.map((res, index) => ({
          ...res.data,
          imagen_url: getImageUrl(res.data.imagen_url),
          disponible: disponibilidades[index]
        }));
        
        setProductos(productosData);
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
    <div style={{ backgroundColor: "#E5E1DA" }}>
      {/* Header */}
      <div className="header-logo-container">
        <Link>
          <img />
        </Link>
      </div>

      <div className="buscador-container-home">
        <BuscadorProductos />
      </div>

      {/* Vitrina de productos */}
      <div className="vitrina">
        {productos.map((producto) => (
          <Link 
            to={`/productos/${producto.id}`} 
            key={producto.id} 
            className="producto-link"
          >
            <div className="producto">
              <img 
                src={producto.imagen_url || 'https://via.placeholder.com/300?text=Imagen+no+disponible'} 
                alt={producto.nombre} 
                onError={(e) => {
                  e.target.onerror = null;
                  e.target.src = 'https://via.placeholder.com/300?text=Imagen+no+disponible';
                  console.error(`Error cargando imagen del producto ${producto.id}:`, producto.imagen_url);
                }}
                style={{
                  width: '100%',
                  height: '200px',
                  objectFit: 'cover'
                }}
              />
              <h3>{producto.nombre}</h3>
              <p>${producto.precio.toLocaleString('es-CO')} COP</p>
              
              {/* Mostrar solo Disponible o Agotado */}
              <span className={`estado-producto ${producto.disponible ? 'disponible' : 'agotado'}`}>
                {producto.disponible ? 'Disponible' : 'Agotado'}
              </span>
            </div>
          </Link>
        ))}
      </div>

      {/* Carrusel */}
      <div className="video-cards-container">
        <CustomCarousel />
      </div>

      {/* Imágenes de Hombres y Mujeres */}
      <div className="category-cards-container">
        <div className="card-container">
          <Link to="/Usuarios/Categorias/Categoriash" className="image-card hombres-card">
            <img
              src="/src/assets/Imagenes/categoria hombres.jpeg"
              alt="Hombres"
              className="image-card-img"
            />
            <h3 className="card-caption">Hombres</h3>
          </Link>
        </div>

        <div className="card-container">
          <Link to="/Usuarios/Categorias/Categoriasm" className="image-card mujeres-card">
            <img
              src="/src/assets/Imagenes/categorias mujer.jpeg"
              alt="Mujeres"
              className="image-card-img"
            />
            <h3 className="card-caption">Mujeres</h3>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Home;