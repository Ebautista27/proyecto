import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import './BuscadorProductos.css';

const BuscadorProductos = () => {
  const [productos, setProductos] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoria, setCategoria] = useState('');
  const [categorias, setCategorias] = useState([]);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  // Función para obtener URL correcta de Cloudinary
  const getImageUrl = (imagenUrl) => {
    if (!imagenUrl) return 'https://res.cloudinary.com/dodecmh9s/image/upload/v1620000000/default.jpg';
    
    if (imagenUrl.includes('res.cloudinary.com')) {
      return imagenUrl;
    }
    
    if (!imagenUrl.startsWith('http')) {
      return `https://res.cloudinary.com/dodecmh9s/image/upload/${imagenUrl}`;
    }
    
    return imagenUrl;
  };

  // Obtener categorías disponibles
  useEffect(() => {
    const fetchCategorias = async () => {
      try {
        const response = await axios.get('http://localhost:5000/categorias');
        setCategorias(response.data);
      } catch (error) {
        console.error('Error fetching categorías:', error);
      }
    };
    fetchCategorias();
  }, []);

  // Buscar productos con debounce
  useEffect(() => {
    const fetchProductos = async () => {
      setLoading(true);
      try {
        const params = new URLSearchParams();
        if (searchTerm) params.append('search', searchTerm);
        if (categoria) params.append('categoria', categoria);
        
        const response = await axios.get(`http://localhost:5000/productos?${params.toString()}`);
        
        // Procesar productos para asegurar URLs de imágenes correctas
        const productosProcesados = response.data.map(producto => ({
          ...producto,
          imagen_url: getImageUrl(producto.imagen_url)
        }));
        
        setProductos(productosProcesados);
      } catch (error) {
        console.error('Error fetching productos:', error);
      } finally {
        setLoading(false);
      }
    };

    const timer = setTimeout(() => {
      if (searchTerm || categoria) {
        fetchProductos();
      } else {
        setProductos([]);
      }
    }, 500);

    return () => clearTimeout(timer);
  }, [searchTerm, categoria]);

  const handleClickProducto = (idProducto) => {
    navigate(`/productos/${idProducto}`);
  };

  return (
    <div className="buscardor-main-container">
      <h2 className="buscardor-title">Encuentra lo que buscas</h2>
      
      <div className="buscardor-filters">
        <div className="buscardor-input-container">
          <input
            type="text"
            placeholder="Buscar productos..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="buscardor-input"
          />
          <span className="buscardor-search-icon">🔍</span>
        </div>
        
      </div>
      
      {loading && (
        <div className="buscardor-loading">
          <div className="buscardor-spinner"></div>
          <p>Buscando productos...</p>
        </div>
      )}
      
      <div className="buscardor-grid">
        {productos.map(producto => (
          <div 
            key={producto.id} 
            className="buscardor-product-card"
            onClick={() => handleClickProducto(producto.id)}
          >
            <div className="buscardor-img-container">
              <img 
                src={producto.imagen_url} 
                alt={producto.nombre} 
                className="buscardor-product-img"
                onError={(e) => {
                  e.target.src = 'https://res.cloudinary.com/dodecmh9s/image/upload/v1620000000/default.jpg';
                }}
                loading="lazy"
              />
            </div>
            <div className="buscardor-product-info">
              <h3 className="buscardor-product-name">{producto.nombre}</h3>
              <p className="buscardor-product-price">${producto.precio?.toLocaleString('es-CO') || '0'} COP</p>
              <span className={`buscardor-product-status ${producto.estado?.toLowerCase().replace(/\s+/g, '-') || 'disponible'}`}>
                {producto.estado || 'Disponible'}
              </span>
            </div>
          </div>
        ))}
        
        {!loading && productos.length === 0 && (searchTerm || categoria) && (
          <div className="buscardor-no-results">
            <p>No se encontraron productos</p>
            <button 
              onClick={() => {
                setSearchTerm('');
                setCategoria('');
              }}
              className="buscardor-reset-btn"
            >
              Limpiar búsqueda
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default BuscadorProductos;