import React from "react";
import { Link } from "react-router-dom"; // Importa Link para la navegación
import CustomCarousel from "../../components/CustomCarousel/CustomCarousel"; // Carrusel para videos y fotos
import BuscadorProductos from "../../components/Buscador/BuscadorProductos"; // Nuevo import
import "./Home.css";



const Home = () => {
  const productos = [
    { 
      id: 1, 
      nombre: "Chaqueta cargo 610", 
      precio: "110.000 mil pesos", 
      img: "/public/productos/chaqueta_cargo_610.jpg",
      ruta: "/Productos/detalle_producto1"
    },
    { 
      id: 2, 
      nombre: "Chaqueta Polo",  // Chaqueta ovejera blanca le cambiamos el nombre
      precio: "105.000 mil pesos", 
      img: "/public/productos/chaqueta_ovejera_blanca.jpeg",
      ruta: "/Productos/detalle_producto2"
    },
    { 
      id: 3, 
      nombre: "Camiseta Choize", 
      precio: "90.000 mil pesos", 
      img: "/public/productos/camiseta choize.jpeg",
      ruta: "/Productos/detalle_producto3"
    },
    { 
      id: 4, 
      nombre: "Camisa boxy fit", 
      precio: "100.000 mil pesos", 
      img: "/public/productos/camiseta bbs.jpeg",
      ruta: "/Productos/detalle_producto4"
    },
  ];

  return (
    <div style={{ backgroundColor: "#E5E1DA" }}>
      {/* Header */}
      <div className="header-logo-container">
        <Link to="/">
          <img  />
        </Link>

        
      </div>

          {/* >>>>>>>>> REEMPLAZA TU BARRA DE BÚSQUEDA ACTUAL POR ESTO <<<<<<<<< */}
          <div className="buscador-container-home">
        <BuscadorProductos />
      </div>

      {/* Vitrina de productos */}
      <div className="vitrina">
        {productos.map((producto) => (
          <Link to={producto.ruta} key={producto.id} className="producto-link">
            <div className="producto">
              <img src={producto.img} alt={producto.nombre} />
              <h3>{producto.nombre}</h3>
              <p>{producto.precio}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Carrusel */}
      <div className="video-cards-container">
        <CustomCarousel />
      </div>

      {/* Imágenes de Hombres y Mujeres debajo del carrusel */}
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