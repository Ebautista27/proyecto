import React, { createContext, useState, useEffect, useContext, useCallback } from "react";
import axios from "axios";
import Swal from "sweetalert2";

const API_URL = "http://localhost:5000/api";

const CarritoContext = createContext();

export const CarritoProvider = ({ children }) => {
  const [carrito, setCarrito] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const getAuthHeader = useCallback(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      throw new Error("Para agregar productos al carrito primero debes de iniciar sesión!");
    }
    return {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    };
  }, []);

  const obtenerCarrito = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      if (!localStorage.getItem("token")) {
        setCarrito(null);
        return;
      }

      const { data } = await axios.get(`${API_URL}/carritos/productos`, getAuthHeader());
      
      // Ajustar estructura según el backend
      if (data.carrito) {
        setCarrito({
          id: data.carrito.id,
          total: data.carrito.total,
          productos: data.carrito.productos.map(item => ({
            id_producto: item.id_producto,
            nombre: item.nombre,
            id_talla: item.id_talla,
            talla: item.talla,
            cantidad: item.cantidad,
            subtotal: item.subtotal,
            precio_unitario: item.precio_unitario,
            imagen_url: item.imagen_url,
            stock_disponible: item.stock_disponible,
            puede_aumentar: item.stock_disponible > item.cantidad
          }))
        });
      } else {
        setCarrito({ productos: [], total: 0 });
      }
      
    } catch (err) {
      console.error("Error obteniendo carrito:", err);
      
      if (err.response?.status === 401) {
        setError("Debes iniciar sesión para ver tu carrito");
      } else if (err.response?.status === 404) {
        setCarrito({ productos: [], total: 0 });
      } else {
        setError("Error al cargar el carrito. Intenta nuevamente.");
      }
      setCarrito(null);
    } finally {
      setLoading(false);
    }
  }, [getAuthHeader]);

  const agregarProducto = async (productoId, id_talla, cantidad = 1) => {
    try {
      if (isNaN(cantidad)) {
        throw new Error("Cantidad debe ser un número");
      }
      cantidad = parseInt(cantidad);
      if (cantidad <= 0) {
        throw new Error("La cantidad debe ser mayor a 0");
      }

      const { data } = await axios.post(
        `${API_URL}/carritos/productos`,
        { producto_id: productoId, id_talla, cantidad },
        getAuthHeader()
      );
      
      // Actualizar carrito con la respuesta del backend
      setCarrito({
        id: data.carrito.id,
        total: data.carrito.total,
        productos: data.carrito.productos.map(item => ({
          id_producto: item.id_producto,
          nombre: item.nombre,
          id_talla: item.id_talla,
          talla: item.talla,
          cantidad: item.cantidad,
          subtotal: item.subtotal,
          precio_unitario: item.precio_unitario,
          imagen_url: item.imagen_url,
          stock_disponible: item.stock_disponible,
          puede_aumentar: item.stock_disponible > item.cantidad
        }))
      });
      
      Swal.fire({
        title: "¡Añadido al carrito!",
        icon: "success",
        showConfirmButton: false,
        timer: 1500,
      });
      
      return true;
    } catch (err) {
      const errorMsg = err.response?.data?.mensaje || 
                     err.response?.data?.error || 
                     err.message || 
                     "Error al agregar producto";
      
      if (err.response?.data?.stock_disponible !== undefined) {
        Swal.fire({
          title: "Stock insuficiente",
          text: `${errorMsg}. Stock disponible: ${err.response.data.stock_disponible}`,
          icon: "warning"
        });
      } else {
        Swal.fire("Error", errorMsg, "error");
      }
      return false;
    }
  };

  const eliminarProducto = async (productoId, id_talla) => {
    try {
      await axios.delete(`${API_URL}/carritos/productos`, {
        headers: getAuthHeader().headers,
        data: { producto_id: productoId, id_talla },
      });
      
      await obtenerCarrito();
      return true;
    } catch (err) {
      const errorMsg = err.response?.data?.mensaje || 
                     "No se pudo eliminar el producto";
      Swal.fire("Error", errorMsg, "error");
      return false;
    }
  };

  const actualizarCantidad = async (productoId, id_talla, nuevaCantidad) => {
    try {
      nuevaCantidad = parseInt(nuevaCantidad);
      if (isNaN(nuevaCantidad)) {
        throw new Error("Cantidad debe ser un número");
      }
      if (nuevaCantidad <= 0) {
        return await eliminarProducto(productoId, id_talla);
      }

      const { data } = await axios.put(
        `${API_URL}/carritos/productos`,
        { producto_id: productoId, id_talla, cantidad: nuevaCantidad },
        getAuthHeader()
      );
      
      // Actualizar carrito con la respuesta del backend
      setCarrito({
        id: data.carrito.id,
        total: data.carrito.total,
        productos: data.carrito.productos.map(item => ({
          id_producto: item.id_producto,
          nombre: item.nombre,
          id_talla: item.id_talla,
          talla: item.talla,
          cantidad: item.cantidad,
          subtotal: item.subtotal,
          precio_unitario: item.precio_unitario,
          imagen_url: item.imagen_url,
          stock_disponible: item.stock_disponible,
          puede_aumentar: item.stock_disponible > item.cantidad
        }))
      });
      
      return true;
    } catch (err) {
      const errorMsg = err.response?.data?.mensaje || 
                     err.response?.data?.error || 
                     "No se pudo actualizar la cantidad";
      
      if (err.response?.data?.stock_disponible !== undefined) {
        Swal.fire({
          title: "Stock insuficiente",
          text: `${errorMsg}. Stock disponible: ${err.response.data.stock_disponible}`,
          icon: "warning"
        });
      } else {
        Swal.fire("Error", errorMsg, "error");
      }
      
      // Forzar actualización del carrito para sincronizar
      await obtenerCarrito();
      return false;
    }
  };

  const vaciarCarrito = async () => {
    try {
      if (carrito?.id) {
        await axios.delete(`${API_URL}/carritos/${carrito.id}`, getAuthHeader());
        setCarrito({ productos: [], total: 0 });
        return true;
      }
      return false;
    } catch (err) {
      const errorMsg = err.response?.data?.mensaje || 
                     "No se pudo vaciar el carrito";
      Swal.fire("Error", errorMsg, "error");
      return false;
    }
  };

  useEffect(() => {
    obtenerCarrito();
  }, [obtenerCarrito]);

  useEffect(() => {
    const handleStorageChange = () => {
      if (!localStorage.getItem("token")) {
        setCarrito(null);
      }
    };

    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);

  return (
    <CarritoContext.Provider
      value={{
        carrito,
        loading,
        error,
        agregarProducto,
        eliminarProducto,
        actualizarCantidad,
        obtenerCarrito,
        vaciarCarrito
      }}
    >
      {children}
    </CarritoContext.Provider>
  );
};

export const useCarrito = () => {
  const context = useContext(CarritoContext);
  
  if (!context) {
    throw new Error(
      "useCarrito debe ser usado dentro de un CarritoProvider. " +
      "Asegúrate de que tu aplicación esté envuelta con <CarritoProvider> " +
      "en el componente raíz (index.js o App.js)."
    );
  }
  
  return context;
};