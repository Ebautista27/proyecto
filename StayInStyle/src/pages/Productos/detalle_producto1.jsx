import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";
import Swal from "sweetalert2";
import "./productos.css";

const DetalleProducto1 = () => {
  const { id } = useParams();
  const [producto, setProducto] = useState(null);
  const [reseñas, setReseñas] = useState([]);
  const [tallaSeleccionada, setTallaSeleccionada] = useState("");
  const [cantidad, setCantidad] = useState(1);
  const [zoomStyle, setZoomStyle] = useState({ display: "none" });
  const [zoomPosition, setZoomPosition] = useState({ left: 0, top: 0 });
  const [nuevaReseña, setNuevaReseña] = useState({
    comentario: "",
    calificacion: 0,
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [productoResponse, reseñasResponse] = await Promise.all([
          axios.get(`http://127.0.0.1:5000/productos/${id}`),
          axios.get(`http://127.0.0.1:5000/reseñas`),
        ]);
        
        setProducto(productoResponse.data);
        // Filtrar reseñas para este producto específico
        const reseñasProducto = reseñasResponse.data.filter(
          r => r.id_producto === parseInt(id)
        );
        setReseñas(reseñasProducto);
      } catch (error) {
        console.error("Error al obtener datos:", error);
      }
    };
    fetchData();
  }, [id]);

  const agregarAlCarrito = () => {
    if (!tallaSeleccionada) {
      Swal.fire("Error", "Por favor selecciona una talla", "warning");
      return;
    }

    const nuevoProducto = {
      id: producto?.id,
      nombre: producto?.nombre,
      precio: producto?.precio ? parseFloat(producto.precio).toFixed(2) : "119.900",
      imagen: producto?.imagen || "/public/productos/chaqueta_cargo_610.jpg",
      talla: tallaSeleccionada,
      cantidad,
    };

    const carritoActual = JSON.parse(localStorage.getItem("carrito")) || [];
    carritoActual.push(nuevoProducto);
    localStorage.setItem("carrito", JSON.stringify(carritoActual));

    Swal.fire({
      title: "Añadido al carrito",
      html: `
        <img src="${nuevoProducto.imagen}" alt="${nuevoProducto.nombre}" width="100px" />
        <p><strong>${producto?.nombre || "Chaqueta Cargo 610"}</strong></p>
        <p>Precio: $${nuevoProducto.precio} COP</p>
      `,
      icon: "success",
    });
  };

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
      left: e.clientX - 75,
      top: e.clientY - 75,
    });
  };

  const handleMouseLeave = () => {
    setZoomStyle({ display: "none" });
  };

  const handleReseñaChange = (e) => {
    const { name, value } = e.target;
    setNuevaReseña({
      ...nuevaReseña,
      [name]: name === "calificacion" ? parseInt(value) : value,
    });
  };

  const enviarReseña = async () => {
    try {
      const token = localStorage.getItem("token");
      const id_usuario = localStorage.getItem("id_usuario"); // <- Lo recuperas del localStorage
  
      if (!token || !id_usuario) {
        Swal.fire("Error", "Debes iniciar sesión para dejar una reseña", "error");
        return;
      }
  
      if (!nuevaReseña.comentario || nuevaReseña.calificacion === 0) {
        Swal.fire("Error", "Por favor completa todos los campos", "error");
        return;
      }
  
      const response = await axios.post(
        `http://127.0.0.1:5000/productos/17/crear-reseña`, // <-- Usar el ID del producto dinámico
        {
          comentario: nuevaReseña.comentario,
          calificacion: nuevaReseña.calificacion,
          id_usuario: parseInt(id_usuario), // <- Aquí lo mandas
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );
  
      const reseñaConUsuario = {
        ...response.data.reseña,
        usuario: { nombre: localStorage.getItem("nombre_usuario") || "Anónimo" }
      };
  
      setReseñas([...reseñas, reseñaConUsuario]);
      setNuevaReseña({ comentario: "", calificacion: 0 });
      Swal.fire("Éxito", "Tu reseña ha sido publicada", "success");
    } catch (error) {
      console.error("Error al enviar reseña:", error);
      Swal.fire("Error", "No se pudo publicar la reseña", "error");
    }
  };
  
  // Calcular estadísticas de reseñas
  const totalReseñas = reseñas.length;
  const promedioCalificacion = totalReseñas > 0 
    ? (reseñas.reduce((sum, r) => sum + r.calificacion, 0) / totalReseñas).toFixed(1)
    : 0;
  
  const conteoEstrellas = [5, 4, 3, 2, 1].map(star => ({
    stars: star,
    count: reseñas.filter(r => r.calificacion === star).length,
    percentage: totalReseñas > 0 
      ? ((reseñas.filter(r => r.calificacion === star).length / totalReseñas) * 100).toFixed(0)
      : 0
  }));

  return (
    <div className="pagina-detalle">
      <div className="producto-detalle-container">
        <div className="producto-detalle">
          {/* Sección del Producto */}
          <div 
            className="producto-imagen"
            onMouseMove={handleMouseMove}
            onMouseLeave={handleMouseLeave}
          >
            <img 
              src={producto?.imagen || "/public/productos/chaqueta_cargo_610.jpg"} 
              alt={producto?.nombre || "Chaqueta Cargo 610"} 
            />
            <div 
              className="zoom-lupa"
              style={{ ...zoomStyle, left: zoomPosition.left, top: zoomPosition.top }}
            ></div>
          </div>
          
          {/* Información del Producto */}
          <div className="producto-informacion">
            <h1>{producto?.nombre || "Chaqueta Cargo 610"}</h1>
            <p className="precio">{producto ? `$ ${producto.precio} COP` : "$ 119.900 COP"}</p>
            
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
                  <input 
                    type="text" 
                    value={cantidad} 
                    readOnly 
                  />
                  <button 
                    type="button" 
                    onClick={() => setCantidad(cantidad + 1)}
                  >
                    +
                  </button>
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
              {producto?.descripcion || "Esta chaqueta de mezclilla se destaca por su diseño audaz y contemporáneo. Presenta un patrón de bloques de colores en tonos azul claro, beige y púrpura, combinado con denim oscuro que le da un estilo único y moderno. Los múltiples bolsillos en el pecho y los laterales no solo añaden funcionalidad, sino que también realzan el diseño asimétrico. El cuello en contraste de color púrpura profundo añade un toque extra de sofisticación, haciendo de esta chaqueta una prenda perfecta para quienes buscan destacar con un look vanguardista."}
            </p>
          </div>
          
          {/* Sección de Reseñas */}
          <div className="reseñas-container">
            <h2>Reseñas del producto</h2>
            <div className="reseñas-estadisticas">
              <div className="calificacion-promedio">
                <span className="promedio-numero">{promedioCalificacion}</span>
                <span className="promedio-texto">Muy bueno</span>
                <span className="total-reseñas">{totalReseñas} opiniones</span>
              </div>
              
              <div className="distribucion-estrellas">
                {conteoEstrellas.map((item) => (
                  <div key={item.stars} className="fila-estrella">
                    <span>{item.stars} estrellas</span>
                    <div className="barra-contenedor">
                      <div 
                        className="barra-progreso" 
                        style={{ width: `${item.percentage}%` }}
                      ></div>
                    </div>
                    <span>{item.count}</span>
                  </div>
                ))}
              </div>
            </div>
            
            <div className="formulario-reseña">
              <h3>Deja tu reseña</h3>
              <div className="calificacion-estrellas">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    className={`estrella ${nuevaReseña.calificacion >= star ? "activa" : ""}`}
                    onClick={() => setNuevaReseña({...nuevaReseña, calificacion: star})}
                  >
                    ★
                  </button>
                ))}
              </div>
              <textarea
                name="comentario"
                value={nuevaReseña.comentario}
                onChange={handleReseñaChange}
                placeholder="Escribe tu reseña aquí..."
                rows="4"
              ></textarea>
              <button 
                type="button" 
                className="boton-enviar" 
                onClick={enviarReseña}
              >
                Enviar reseña
              </button>
            </div>
            
            <div className="lista-reseñas">
              {reseñas.map((reseña) => (
                <div key={reseña.id} className="reseña-item">
                  <div className="reseña-cabecera">
                    <span className="reseña-usuario">
                      {reseña.usuario?.nombre || "Anónimo"}
                    </span>
                    <div className="reseña-estrellas">
                      {"★".repeat(reseña.calificacion)}{"☆".repeat(5 - reseña.calificacion)}
                    </div>
                    <span className="reseña-fecha">
                      {reseña.fecha_creacion ? new Date(reseña.fecha_creacion).toLocaleDateString() : ""}
                    </span>
                  </div>
                  <p className="reseña-comentario">{reseña.comentario}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DetalleProducto1;