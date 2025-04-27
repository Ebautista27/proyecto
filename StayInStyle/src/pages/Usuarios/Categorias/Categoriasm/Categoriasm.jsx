import React from "react";
import { Link } from "react-router-dom"; 
import BuscadorProductos from "../../../../components/Buscador/BuscadorProductos";

import "./Categoriasm.css"; // Usamos el mismo CSS de Hombres

const Categoriasm = () => {
  const productos = [
    {
      id: 9,
      nombre: "Camisa Overzice 97",
      precio: "75.000 mil pesos",
      imagen: "/public/productos/Camisa_M_1.jpg",
      enlace: "/Productos/detalle_producto_camisa_arena97",
    },
    {
      id: 10,
      nombre: "Camisa Colmillos",
      precio: "80.000 mil pesos",
      imagen: "/public/productos/Camisa_M_2.jpg",
      enlace: "/Productos/detalle_producto_camisa_gris-negra",
    },
    {
      id: 11,
      nombre: "Camisa SideStreet",
      precio: "90.000 mil pesos",
      imagen: "/public/productos/Camisa_M_3.jpg",
      enlace: "/Productos/detalle_producto_camisa_negra_sidesteet",
    },
    {
      id: 12,
      nombre: "Camisa Saint Tears",
      precio: "95.000 mil pesos",
      imagen: "/public/productos/Camisa_M_4.jpg",
      enlace: "/Productos/detalle_producto_camisa_negra_saint-tears",
    },
    {
      id: 13,
      nombre: "Pantalón Anything",
      precio: "78.000 mil pesos",
      imagen: "/public/productos/pantalon_M_1.jpeg",
      enlace: "/Productos/detalle_producto_pantalonM_anything",
    },
    {
      id: 14,
      nombre: "Cargo Morado",
      precio: "100.000 mil pesos",
      imagen: "/public/productos/Pantalon_M_3.jpg",
      enlace: "/Productos/detalle_producto_pantalonM_Cargo_Morado",
    },
    {
      id: 15,
      nombre: "Shorts Cargo",
      precio: "60.000 mil pesos",
      imagen: "/public/productos/Pantalon_M_4.jpg",
      enlace: "/Productos/detalle_producto_pantalonetaM_Cargo",
    },
    {
      id: 16,
      nombre: "Jeans Atractivos",
      precio: "90.000 mil pesos",
      imagen: "/public/productos/Pantalon_M_5.jpg",
      enlace: "/Productos/detalle_producto_pantalonM_Desteñido_llamas-Moradas",
    },
  ];

  return (
    <div style={{ backgroundColor: "#E5E1DA" }}>
      <div className="mujeres-container">
         {/* >>>>>>>>> REEMPLAZA TU BARRA DE BÚSQUEDA ACTUAL POR ESTO <<<<<<<<< */}
       <div className="buscador-container-home">
        <BuscadorProductos />
      </div>
        <h2>Prendas destacadas</h2>
        <section className="vitrina">
          {productos.map((producto) => (
            <div className="producto" key={producto.id}>
              <Link to={producto.enlace}>
                <img src={producto.imagen} alt={producto.nombre} />
              </Link>
              <h3>{producto.nombre}</h3>
              <p>Precio: {producto.precio}</p>
            </div>
          ))}
        </section>
      </div>
    </div>
  );
};

export default Categoriasm;

 




