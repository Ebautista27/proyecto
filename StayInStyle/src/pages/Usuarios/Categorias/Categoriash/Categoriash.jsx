import React from "react";
import { Link } from "react-router-dom"; // Importa Link para navegación sin recargar
import BuscadorProductos from "../../../../components/Buscador/BuscadorProductos";
import "./Categoriash.css";

const Categoriash = () => {
  const productos = [
    {
      id: 1,
      nombre: "Camisa Overzice A3ORFEND",
      precio: "80.000 COP",
      imagen: "/public/productos/Camisa_H_4.jpg",
      ruta: "/Productos/detalle_producto_camisa_blanca_overzice",
    },
    {
      id: 2,
      nombre: "Camisa Araña WPADF",
      precio: "95.000 COP",
      imagen: "/public/productos/Camisa_H_5.jpg",
      ruta: "/Productos/detalle_producto_camisa_negra_araña",
    },
    {
      id: 3,
      nombre: "Camisa Overzice ATSOBER",
      precio: "85.000 COP",
      imagen: "/public/productos/Camisa_H_6.jpg",
      ruta: "/Productos/detalle_producto_camisa_blanca_llamas",
    },
    {
      id: 4,
      nombre: "Camisa Overzice Sencilla",
      precio: "90.000 COP",
      imagen: "/public/productos/Camisa_h_7.jpg",
      ruta: "/Productos/detalle_producto_camisa_negra_clasica",
    },
    {
      id: 5,
      nombre: "Camisa Overzice AW SPIKY HEAD",
      precio: "110.000 COP",
      imagen: "/public/productos/camiseta ae.jpeg",
      ruta: "/Productos/detalle_producto_camisa_gris_AW_SPIKY_HEAD",
    },
    {
      id: 6,
      nombre: "Camisa Overzice XOMOCLOTHES",
      precio: "98.000 COP",
      imagen: "/public/productos/camiseta bbs.jpeg",
      ruta: "/Productos/detalle_producto_camisa_blanca-gris_xomoclothes",
    },
    {
      id: 7,
      nombre: "Camisa BlackStar",
      precio: "70.000 COP",
      imagen: "/public/productos/Camisa_H_2.jpg",
      ruta: "/Productos/detalle_producto_camisa_negra-blanco_blackstar",
    },
    {
      id: 8,
      nombre: "Camisa Overizece Eterning",
      precio: "99.000 COP",
      imagen: "/public/productos/Camisa_H_3.jpg",
      ruta: "/Productos/detalle_producto_camisa_negra_eterning",
    },
  ];

  return (
    <div className="hombres-container">
       {/* >>>>>>>>> REEMPLAZA TU BARRA DE BÚSQUEDA ACTUAL POR ESTO <<<<<<<<< */}
       <div className="buscador-container-home">
        <BuscadorProductos />
      </div>
      <h2>Prendas destacadas</h2>
      <section className="vitrina">
        {productos.map((producto) => (
          <div className="producto" key={producto.id}>
            <Link to={producto.ruta}>
              <img src={producto.imagen} alt={producto.nombre} />
            </Link>
            <h3>{producto.nombre}</h3>
            <p>Precio: {producto.precio}</p>
          </div>
        ))}
      </section>
    </div>
  );
};

export default Categoriash;

