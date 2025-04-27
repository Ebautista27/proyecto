import React, { createContext, useState, useEffect } from "react";

// Crear el contexto
export const CarritoContext = createContext();

// Proveedor del contexto
export const CarritoProvider = ({ children }) => {
  const [carrito, setCarrito] = useState([]);
  const [totalPrecio, setTotalPrecio] = useState(0);

  // Cargar carrito desde localStorage al iniciar
  useEffect(() => {
    const carritoGuardado = JSON.parse(localStorage.getItem("carrito")) || [];
    setCarrito(carritoGuardado);
    calcularTotal(carritoGuardado);
  }, []);

  // Guardar en localStorage cada vez que cambie el carrito
  useEffect(() => {
    localStorage.setItem("carrito", JSON.stringify(carrito));
    calcularTotal(carrito);
  }, [carrito]);

  // Función para calcular el total del carrito
  const calcularTotal = (productos) => {
    const total = productos.reduce((sum, p) => sum + p.precio * p.cantidad, 0);
    setTotalPrecio(total);
  };

  // Función para agregar un producto al carrito
  const addToCart = (producto) => {
    setCarrito((prevCarrito) => {
      const existe = prevCarrito.find((p) => p.id === producto.id && p.talla === producto.talla);
      if (existe) {
        return prevCarrito.map((p) =>
          p.id === producto.id && p.talla === producto.talla
            ? { ...p, cantidad: p.cantidad + producto.cantidad }
            : p
        );
      }
      return [...prevCarrito, producto];
    });
  };

  return (
    <CarritoContext.Provider value={{ carrito, totalPrecio, addToCart }}>
      {children}
    </CarritoContext.Provider>
  );
};
