import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";
import Swal from "sweetalert2";
import "./productos.css";

const DetalleProducto14 = () => {
  const { id } = useParams();
  const [producto, setProducto] = useState(null);
  const [tallaSeleccionada, setTallaSeleccionada] = useState("");
  const [cantidad, setCantidad] = useState(1);
  const [zoomStyle, setZoomStyle] = useState({ display: "none" });
  const [zoomPosition, setZoomPosition] = useState({ left: 0, top: 0 });

  useEffect(() => {
    const fetchProducto = async () => {
      try {
        const response = await axios.get(`http://127.0.0.1:5000/productos/${id}`);
        setProducto(response.data);
      } catch (error) {
        console.error("Error al obtener el producto:", error);
      }
    };
    fetchProducto();
  }, [id]);

      //////
                      
  const agregarAlCarrito = () => {
console.log("Producto antes de agregar:", producto); // 🔍 Verifica que tenga datos
                      
    if (!tallaSeleccionada) {
        Swal.fire("Error", "Por favor selecciona una talla", "warning");
              return;
 }
                      
      const nuevoProducto = {
  id: producto?.id,
 nombre: producto?.nombre,
         precio: producto?.precio ? parseFloat(producto.precio).toFixed(2) : "100.000  ", 
        imagen: producto?.imagen || "/public/productos/Camisa_M_2.jpg", // Imagen por defecto si falta
        talla: tallaSeleccionada,
           cantidad,
     };
                      
   console.log("Producto añadido al carrito:", nuevoProducto); // 🔍 Verifica los datos antes de guardarlos
                      
     const carritoActual = JSON.parse(localStorage.getItem("carrito")) || [];
    carritoActual.push(nuevoProducto);
     localStorage.setItem("carrito", JSON.stringify(carritoActual));
                      
     Swal.fire({
       title: "Añadido al carrito",
         html: `
         <img src="${nuevoProducto.imagen}" alt="${nuevoProducto.nombre}" width="100px" />
           <p><strong>${"Camisa Colmillos"}</strong></p>
           <p>Precio: $${nuevoProducto.precio} COP</p>
        `,
         icon: "success",
       });
       };
                      
                      
 //////////

  const handleMouseMove = (e) => {
    const imagen = e.target.getBoundingClientRect();
    const x = ((e.clientX - imagen.left) / imagen.width) * 100;
    const y = ((e.clientY - imagen.top) / imagen.height) * 100;

    setZoomStyle({
      display: "block",
      backgroundImage: `url(${producto?.imagen})`,
      backgroundPosition: `${x}% ${y}%`,
      backgroundSize: "200%",
    });

    setZoomPosition({
      left: e.clientX - 75, // Ajuste para centrar la lupa
      top: e.clientY - 75,
    });
  };

  const handleMouseLeave = () => {
    setZoomStyle({ display: "none" });
  };

  return (
    <div className="pagina-detalle">
      <div className="producto-detalle-container">
        <div className="producto-detalle">
          <div 
            className="producto-imagen"
            onMouseMove={handleMouseMove}
            onMouseLeave={handleMouseLeave}
          >
            <img src={producto?.imagen || "/public/productos/Camisa_M_2.jpg"} />
            <div 
              className="zoom-lupa"
              style={{ ...zoomStyle, left: zoomPosition.left, top: zoomPosition.top }}
            ></div>
          </div>
          <div className="producto-informacion">
            <h1>{producto?.nombre || "Camisa Colmillos"}</h1>
            <p className="precio">{producto ? `$ ${producto.precio} COP` : "$ 100.000 COP"}</p>
            <form>
              <div className="seleccion-talla">
                <label>Elige tu talla:</label>
                <div className="tallas">
                  {["XS", "S", "M", "L", "XL"].map((talla) => (
                    <button
                      key={talla}
                      type="button"
                      className={`talla ${tallaSeleccionada === talla ? "active" : ""}`}
                      onClick={() => setTallaSeleccionada(talla)}
                    >
                      {talla}
                    </button>
                  ))}
                </div>
              </div>
              <div className="seleccion-cantidad">
                <label>Cantidad:</label>
                <div className="cantidad-control">
                  <input type="text" value={cantidad} readOnly />
                  <button type="button" onClick={() => setCantidad(cantidad + 1)}>+</button>
                </div>
              </div>
              <button 
  type="button" 
  className="boton-carrito" 
  onClick={agregarAlCarrito}
>
  Añadir a la cesta
</button>
            </form>
            <h5>DESCRIPCIÓN</h5>
            <p>
              {producto?.descripcion || "Destaca con esta camiseta blanca única que presenta un diseño gráfico audaz de colmillos en la parte frontal. El estampado en negro crea un contraste impactante que añade un toque artístico y rebelde a cualquier atuendo. Ideal para quienes buscan un estilo atrevido y fuera de lo común, esta prenda es perfecta para hacer una declaración de moda. Confeccionada en algodón suave, garantiza comodidad durante todo el día."}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DetalleProducto14;
