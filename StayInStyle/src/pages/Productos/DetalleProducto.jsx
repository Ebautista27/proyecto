import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";
import Swal from "sweetalert2";
import { useCarrito } from "../../context/CarritoContext";
import { FaShoppingCart, FaStar, FaRegStar, FaExclamationTriangle } from "react-icons/fa";
import "./productos.css";

const DetalleProducto = () => {
  const { id } = useParams();
  const { agregarProducto, carrito } = useCarrito();
  const [producto, setProducto] = useState(null);
  const [reseñas, setReseñas] = useState([]);
  const [tallaSeleccionada, setTallaSeleccionada] = useState(null); // Cambiado a objeto con id_talla y talla
  const [cantidad, setCantidad] = useState(1);
  const [nuevaReseña, setNuevaReseña] = useState({
    comentario: "",
    calificacion: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [tallasDisponibles, setTallasDisponibles] = useState([]);
  const [tallasAgotadas, setTallasAgotadas] = useState([]);

  const getImageUrl = (imagenUrl) => {
    if (!imagenUrl) return "https://via.placeholder.com/400";
    if (imagenUrl.includes("res.cloudinary.com")) return imagenUrl;
    if (!imagenUrl.startsWith("http")) {
      return `https://res.cloudinary.com/dodecmh9s/image/upload/${imagenUrl}`;
    }
    return imagenUrl;
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);
        
        const [productoResponse, reseñasResponse, tallasResponse] = await Promise.all([
          axios.get(`http://localhost:5000/productos/${id}`),
          axios.get(`http://localhost:5000/productos/${id}/reseñas`).catch(() => ({ data: [] })),
          axios.get(`http://localhost:5000/api/productos/${id}/tallas-disponibles`)
        ]);

        if (!productoResponse.data) {
          throw new Error("Producto no encontrado");
        }

        const productoData = productoResponse.data;
        const tallasData = tallasResponse.data.tallas || [];
        
        // Buscar el producto en el carrito
        const enCarrito = carrito?.productos?.find(
          p => p.id_producto === productoData.id
        );

        // Filtrar tallas disponibles y agotadas
        const disponibles = tallasData.filter(t => t.disponible);
        const agotadas = tallasData.filter(t => !t.disponible);

        setProducto({
          ...productoData,
          imagen_url: getImageUrl(productoData.imagen_url),
          precio: parseFloat(productoData.precio || 0).toFixed(2),
          enCarrito: enCarrito ? {
            cantidad: enCarrito.cantidad,
            talla: enCarrito.talla,
            id_talla: enCarrito.id_talla
          } : null
        });

        setReseñas(reseñasResponse.data || []);
        setTallasDisponibles(disponibles);
        setTallasAgotadas(agotadas);

        // Si el producto ya está en el carrito, seleccionar esa talla por defecto
        if (enCarrito) {
          setTallaSeleccionada({
            id_talla: enCarrito.id_talla,
            talla: enCarrito.talla,
            stock: disponibles.find(t => t.id_talla === enCarrito.id_talla)?.stock || 0
          });
          setCantidad(enCarrito.cantidad);
        }

      } catch (error) {
        console.error("Error al obtener datos:", error);
        setError("No se pudo cargar el producto");
        Swal.fire({
          icon: "error",
          title: "Error",
          text: "No se pudo cargar el producto",
          footer: error.message,
        });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id, carrito]);

  const handleAgregarAlCarrito = async () => {
    if (!tallaSeleccionada) {
      Swal.fire({
        icon: "warning",
        title: "Oops...",
        text: "Por favor selecciona una talla",
      });
      return;
    }

    // Verificar si hay suficiente stock
    if (cantidad > tallaSeleccionada.stock) {
      Swal.fire({
        icon: "error",
        title: "Stock insuficiente",
        text: `Solo quedan ${tallaSeleccionada.stock} unidades disponibles de esta talla`,
      });
      return;
    }

    try {
      const success = await agregarProducto(
        producto.id, 
        tallaSeleccionada.id_talla, // Usamos id_talla en lugar de talla
        cantidad
      );

      if (success) {
        setProducto(prev => ({
          ...prev,
          enCarrito: {
            cantidad: cantidad,
            talla: tallaSeleccionada.talla,
            id_talla: tallaSeleccionada.id_talla
          }
        }));

        Swal.fire({
          title: "¡Añadido al carrito!",
          html: `
            <div style="text-align: center;">
              <img src="${producto.imagen_url}" 
                   alt="${producto.nombre}" 
                   style="max-width: 150px; border-radius: 8px; margin: 10px 0;"/>
              <h4 style="margin: 5px 0; color: #333;">${producto.nombre}</h4>
              <div style="display: flex; justify-content: center; gap: 15px; margin: 8px 0;">
                <span style="font-weight: 500;">Talla: ${tallaSeleccionada.talla}</span>
                <span style="font-weight: 500;">Cantidad: ${cantidad}</span>
              </div>
              <p style="margin: 5px 0; font-size: 1.2em; color:rgb(0, 0, 0); font-weight: bold;">
                $${(producto.precio * cantidad).toFixed(2)} COP
              </p>
            </div>
          `,
          icon: "success",
          confirmButtonColor: "#000000",
          confirmButtonText: "¡Entendido!",
        });
      }
    } catch (error) {
      Swal.fire({
        icon: "error",
        title: "Error",
        text: "No se pudo agregar al carrito",
        footer: error.response?.data?.mensaje || error.message || "",
      });
    }
  };

  const enviarReseña = async () => {
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        Swal.fire({
          icon: "error",
          title: "Error",
          text: "Debes iniciar sesión para dejar una reseña",
        });
        return;
      }

      if (!nuevaReseña.comentario || nuevaReseña.calificacion === 0) {
        Swal.fire({
          icon: "warning",
          title: "Oops...",
          text: "Por favor completa todos los campos",
        });
        return;
      }

      const response = await axios.post(
        `http://localhost:5000/productos/${id}/crear-reseña`,
        {
          comentario: nuevaReseña.comentario,
          calificacion: nuevaReseña.calificacion,
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      setReseñas([...reseñas, response.data]);
      setNuevaReseña({ comentario: "", calificacion: 0 });
      
      Swal.fire({
        icon: "success",
        title: "¡Reseña publicada!",
        showConfirmButton: false,
        timer: 1500,
      });
    } catch (error) {
      Swal.fire({
        icon: "error",
        title: "Error",
        text: "No se pudo publicar la reseña",
        footer: error.response?.data?.mensaje || "",
      });
    }
  };

  const renderEstrellas = (calificacion) => {
    return [1, 2, 3, 4, 5].map((star) => (
      star <= calificacion ? <FaStar key={star} /> : <FaRegStar key={star} />
    ));
  };

  if (loading) {
    return (
      <div className="pagina-detalle">
        <div className="cargando-producto">
          <div className="spinner"></div>
          <p>Cargando producto...</p>
        </div>
      </div>
    );
  }

  if (error || !producto) {
    return (
      <div className="pagina-detalle">
        <div className="error-producto">
          <h3>¡Ups! Algo salió mal</h3>
          <p>{error || "El producto no existe o no está disponible"}</p>
          <button 
            className="btn-reintentar"
            onClick={() => window.location.reload()}
          >
            Reintentar
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="pagina-detalle">
      <div className="producto-detalle-container">
        <div className="producto-imagen">
          <img
            src={producto.imagen_url}
            alt={producto.nombre}
            onError={(e) => {
              e.target.src = "https://via.placeholder.com/400";
            }}
          />
        </div>

        <div className="producto-informacion">
          <h1>{producto.nombre}</h1>
          <div className="precio">${producto.precio} COP</div>

          {producto.enCarrito && (
            <div className="producto-en-carrito-alert">
              <p>Ya tienes {producto.enCarrito.cantidad} unidad(es) de este producto en tu carrito (Talla: {producto.enCarrito.talla})</p>
            </div>
          )}

          <form id="form-detalles-producto">
            <div className="seleccion-talla">
              <h3>Tallas disponibles</h3>
              <div className="tallas">
                {tallasDisponibles.map((talla) => (
                  <div
                    key={talla.id_talla}
                    className={`talla ${
                      tallaSeleccionada?.id_talla === talla.id_talla ? "active" : ""
                    }`}
                    onClick={() => setTallaSeleccionada({
                      id_talla: talla.id_talla,
                      talla: talla.talla,
                      stock: talla.stock
                    })}
                  >
                    {talla.talla}
                  </div>
                ))}
              </div>
            </div>

            {tallasAgotadas.length > 0 && (
              <div className="tallas-agotadas">
                <FaExclamationTriangle className="icono-advertencia" />
                <span>Tallas agotadas: {tallasAgotadas.map(t => t.talla).join(", ")}</span>
              </div>
            )}

            <div className="seleccion-cantidad">
              <h3>Cantidad</h3>
              <div className="cantidad-control">
                <button
                  type="button"
                  onClick={() => setCantidad(Math.max(1, cantidad - 1))}
                  disabled={cantidad <= 1}
                >
                  -
                </button>
                <input 
                  type="text" 
                  value={cantidad} 
                  readOnly 
                />
                <button
                  type="button"
                  onClick={() => {
                    const maxCantidad = tallaSeleccionada?.stock || 0;
                    setCantidad(Math.min(cantidad + 1, maxCantidad));
                  }}
                  disabled={!tallaSeleccionada || cantidad >= tallaSeleccionada.stock}
                >
                  +
                </button>
              </div>
              {tallaSeleccionada && (
                <p className="stock-disponible">
                  Stock disponible: {tallaSeleccionada.stock} unidades
                </p>
              )}
            </div>

            <button
              type="button"
              className="btn-agregar-carrito"
              onClick={handleAgregarAlCarrito}
              disabled={!tallaSeleccionada}
            >
              <FaShoppingCart style={{ marginRight: "8px" }} />
              {producto.enCarrito ? "Actualizar carrito" : "Añadir al carrito"}
            </button>
          </form>

          <div className="producto-descripcion">
            <h3>Descripción</h3>
            <p>{producto.descripcion || "Este producto no tiene descripción."}</p>
          </div>
        </div>
      </div>

      <div className="reseñas-container">
        <h2>Opiniones de clientes</h2>
        
        <div className="formulario-reseña">
          <h3>Deja tu reseña</h3>
          <div className="calificacion-estrellas">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                type="button"
                className={nuevaReseña.calificacion >= star ? "activa" : ""}
                onClick={() => setNuevaReseña({...nuevaReseña, calificacion: star})}
              >
                ★
              </button>
            ))}
          </div>
          <textarea
            placeholder="Escribe tu opinión sobre este producto..."
            value={nuevaReseña.comentario}
            onChange={(e) => setNuevaReseña({...nuevaReseña, comentario: e.target.value})}
          ></textarea>
          <button
            type="button"
            className="boton-enviar"
            onClick={enviarReseña}
            disabled={!nuevaReseña.comentario || nuevaReseña.calificacion === 0}
          >
            Enviar reseña
          </button>
        </div>

        <div className="lista-reseñas">
          {reseñas.length > 0 ? (
            reseñas.map((reseña) => (
              <div key={reseña.id} className="reseña-item">
                <div className="reseña-cabecera">
                  <span className="reseña-usuario">
                    {reseña.usuario?.nombre || "Anónimo"}
                  </span>
                  <div className="reseña-estrellas">
                    {renderEstrellas(reseña.calificacion)}
                  </div>
                  <span className="reseña-fecha">
                    {new Date(reseña.fecha_creacion).toLocaleDateString()}
                  </span>
                </div>
                <p className="reseña-comentario">{reseña.comentario}</p>
              </div>
            ))
          ) : (
            <p className="sin-reseñas">Aún no hay reseñas para este producto</p>
          )}
        </div>
      </div>
    </div>
  );
};

export default DetalleProducto;