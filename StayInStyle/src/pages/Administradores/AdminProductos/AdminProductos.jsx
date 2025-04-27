import React, { useState, useEffect } from "react";
import AOS from "aos";
import "aos/dist/aos.css";
import "./adminproductos.css";

const AdminProductos = () => {
  const [productos, setProductos] = useState([]);
  const [formData, setFormData] = useState({
    nombre: "",
    descripcion: "",
    precio: "",
    estado: "Disponible",
    id_categoria: "",
  });
  const [editData, setEditData] = useState(null);
  const [mensaje, setMensaje] = useState("");
  const token = localStorage.getItem("token");

  useEffect(() => {
    AOS.init();
    fetchProductos();
  }, []);

  // Obtener la lista de productos
  const fetchProductos = async () => {
    try {
      const response = await fetch("http://127.0.0.1:5000/productos", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      const data = await response.json();
      if (response.ok) {
        setProductos(data);
      } else {
        setMensaje(data.mensaje || "Error al cargar los productos.");
      }
    } catch (error) {
      setMensaje("Error al cargar los productos.");
    }
  };

  // Manejar cambios en el formulario
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  // Manejar el envío del formulario (crear o actualizar)
  const handleSubmit = async (e) => {
    e.preventDefault();

 const url = editData
  ? `http://127.0.0.1:5000/productos/${editData.id}`
  : "http://127.0.0.1:5000/productos/nuevo";  // ✅ Ruta correcta según tu backend
    const method = editData ? "PUT" : "POST";

    try {
      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(formData),
      });

      if (response.ok) {
        setMensaje(editData ? "Producto actualizado" : "Producto creado");
        fetchProductos();
        setFormData({
          nombre: "",
          descripcion: "",
          precio: "",
          estado: "Disponible",
          id_categoria: "",
        });
        setEditData(null);
      } else {
        const errorData = await response.json();
        setMensaje(errorData.mensaje || "Error al guardar el producto.");
      }
    } catch  {
      setMensaje("Error al guardar el producto.");
    }
  };

  // Manejar la edición de un producto
  const handleEdit = (producto) => {
    setEditData(producto);
    setFormData({
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      precio: producto.precio,
      estado: producto.estado,
      id_categoria: producto.id_categoria,
    });
  };

  // Manejar la eliminación de un producto
  const handleDelete = async (id) => {
    try {
      const response = await fetch(`http://127.0.0.1:5000/productos/${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        setMensaje("Producto eliminado");
        fetchProductos();
      } else {
        const errorData = await response.json();
        setMensaje(errorData.mensaje || "Error al eliminar el producto.");
      }
    } catch (error) {
      setMensaje("Error al eliminar el producto.");
    }
  };

  return (
    <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
      <div className="container">
        <h1 data-aos="fade-down" data-aos-duration="1000">Gestión de Productos</h1>

        {mensaje && <div className="alert alert-info">{mensaje}</div>}

        <div className="form-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>{editData ? "Editar Producto" : "Crear Producto"}</h2>
          <form onSubmit={handleSubmit}>
            <input
              type="text"
              name="nombre"
              placeholder="Nombre"
              value={formData.nombre}
              onChange={handleChange}
              required
            />
            <input
              type="text"
              name="descripcion"
              placeholder="Descripción"
              value={formData.descripcion}
              onChange={handleChange}
              required
            />
            <input
              type="number"
              name="precio"
              placeholder="Precio"
              value={formData.precio}
              onChange={handleChange}
              required
            />
            <select
              name="estado"
              value={formData.estado}
              onChange={handleChange}
              required
            >
              <option value="Disponible">Disponible</option>
              <option value="No Disponible">No Disponible</option>
            </select>
            <input
              type="text"
              name="id_categoria"
              placeholder="ID Categoría"
              value={formData.id_categoria}
              onChange={handleChange}
              required
            />
            <button type="submit">
              {editData ? "Guardar Cambios" : "Crear Producto"}
            </button>
          </form>
        </div>

        <div className="table-container" data-aos="fade-up" data-aos-duration="1500">
          <table>
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Descripción</th>
                <th>Precio</th>
                <th>Estado</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {productos.map((producto) => (
                <tr key={producto.id}>
                  <td>{producto.nombre}</td>
                  <td>{producto.descripcion}</td>
                  <td>{producto.precio}</td>
                  <td>{producto.estado}</td>
                  <td>
                    <button onClick={() => handleEdit(producto)}>Editar</button>
                    <button onClick={() => handleDelete(producto.id)}>Eliminar</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminProductos;