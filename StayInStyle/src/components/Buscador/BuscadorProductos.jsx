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

  // Mapeo de IDs de producto a rutas (¡Actualiza esto con tus productos reales!)
  const rutasProductos = {
    // Camisas Hombre (H)
    1: '/Productos/detalle_producto_camisa_blanca_overzice',      // Camisa_H_1.jpg
    2: '/Productos/detalle_producto_camisa_negra_araña',          // Camisa_H_2.jpg
    3: '/Productos/detalle_producto_camisa_blanca_llamas',        // Camisa_H_3.jpg
    4: '/Productos/detalle_producto_camisa_negra_clasica',        // Camisa_H_4.jpg
    5: '/Productos/detalle_producto_camisa_gris_AW_SPIKY_HEAD',   // Camisa_H_5.jpg
    6: '/Productos/detalle_producto_camisa_blanca-gris_xomoclothes', // Camisa_H_6.jpg
    7: '/Productos/detalle_producto_camisa_negra-blanco_blackstar',  // Camisa_h_7.jpg
  
    // Camisas Mujer (M)
    8: '/Productos/detalle_producto1',                            // Camisa_M_1.jpg
    9: '/Productos/detalle_producto2',                            // Camisa_M_2.jpg
    10: '/Productos/detalle_producto3',                           // Camisa_M_3.jpg
    11: '/Productos/detalle_producto4',                           // Camisa_M_4.jpg
  
    // Chaquetas
    12: '/Productos/dealle_producto_destacado_chaqueta_azul',     // chaqueta japon.jpeg
    13: '/Productos/detalle_producto_destacado_chaqueta_negra',   // chaqueta cargo.610.jpg
    14: '/Productos/detalle_producto5',                           // chaqueta_ovejera_blanca.jpeg
  
    // Pantalones (M)
    15: '/Productos/detalle_producto_pantalonM_anything',         // pantalon_M_1.jpeg
    16: '/Productos/detalle_producto_pantalonM_Cargo_Morado',     // Pantalon_M_2.jpg
    17: '/Productos/detalle_producto_pantalonetaM_Cargo',         // Pantalon_M_3.jpg
    18: '/Productos/detalle_producto_pantalonM_Desteñido_llamas-Moradas', // Pantalon_M_4.jpg
    19: '/Productos/detalle_producto6',                           // Pantalon_M_5.jpg
  
    // Camisetas y otros
    20: '/Productos/detalle_producto_destacado_camiseta_azul',    // camiseta ae.jpeg
    21: '/Productos/detalle_producto7',                           // camiseta bbs.jpeg
    22: '/Productos/detalle_producto8',                           // camiseta choize.jpeg
    23: '/Productos/detalle_producto9',                           // camiseta gris bbs.jpeg
  };

  // Obtener categorías al cargar el componente
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

  // Buscar productos
  useEffect(() => {
    const fetchProductos = async () => {
      setLoading(true);
      try {
        const params = new URLSearchParams();
        if (searchTerm) params.append('search', searchTerm);
        if (categoria) params.append('categoria', categoria);
        
        const response = await axios.get(`http://localhost:5000/productos?${params.toString()}`);
        setProductos(response.data);
      } catch (error) {
        console.error('Error fetching productos:', error);
      } finally {
        setLoading(false);
      }
    };

    const timer = setTimeout(() => {
      if (searchTerm || categoria) fetchProductos();
    }, 500);

    return () => clearTimeout(timer);
  }, [searchTerm, categoria]);

  // Función para manejar clic en producto
  const handleClickProducto = (idProducto) => {
    const ruta = rutasProductos[idProducto] || '/producto-no-encontrado';
    navigate(ruta);
  };

  return (
    <div className="buscador-container">
      <h2>Buscador de Productos</h2>
      
      <div className="filtros-container">
        <input
          type="text"
          placeholder="Buscar productos..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="search-input"
        />
        
        <select 
          value={categoria} 
          onChange={(e) => setCategoria(e.target.value)}
          className="categoria-select"
        >
          <option value="">Todas las categorías</option>
          {categorias.map(cat => (
            <option key={cat.id} value={cat.nombre.toLowerCase()}>
              {cat.nombre}
            </option>
          ))}
        </select>
      </div>
      
      {loading && <div className="loading-spinner">Buscando...</div>}
      
      <div className="productos-grid">
        {productos.map(producto => (
          <div 
            key={producto.id} 
            className="producto-card"
            onClick={() => handleClickProducto(producto.id)}
            style={{ cursor: 'pointer' }} // Cambia el cursor para indicar que es clickeable
          >
            <img 
              src={producto.imagen} 
              alt={producto.nombre} 
              className="producto-imagen5"
              onError={(e) => e.target.src = '/productos/placeholder.jpg'}
            />
            <h3>{producto.nombre}</h3>
            <p className="precio">${producto.precio?.toLocaleString() || '0.00'}</p>
            <p className={`estado ${producto.estado?.toLowerCase() || 'disponible'}`}>
              {producto.estado || 'Disponible'}
            </p>
          </div>
        ))}
        
        {!loading && productos.length === 0 && (
          <div className="no-resultados">
            No se encontraron productos
          </div>
        )}
      </div>
    </div>
  );
};

export default BuscadorProductos;