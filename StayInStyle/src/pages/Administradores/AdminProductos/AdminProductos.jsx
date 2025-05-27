import React, { useState, useEffect } from "react";
import AOS from "aos";
import "aos/dist/aos.css";
import "./adminproductos.css";

const AdminProductos = () => {
  const [productos, setProductos] = useState([]);
  const [categorias, setCategorias] = useState([]);
  const [generos, setGeneros] = useState([]);
  const [formData, setFormData] = useState({
    nombre: "",
    descripcion: "",
    precio: "",
    estado: "Disponible",
    id_categoria: "",
    id_genero: "",
    imagen: null
  });
  const [editData, setEditData] = useState(null);
  const [mensaje, setMensaje] = useState("");
  const [previewImage, setPreviewImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const token = localStorage.getItem("token");

  useEffect(() => {
    AOS.init();
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const endpoints = [
        { url: "http://localhost:5000/productos", key: "productos" },
        { url: "http://localhost:5000/categorias", key: "categorias" },
        { url: "http://localhost:5000/api/generos", key: "generos" }
      ];

      const responses = await Promise.all(
        endpoints.map(endpoint => 
          fetch(endpoint.url, {
            headers: {
              Authorization: `Bearer ${token}`,
              'Content-Type': 'application/json'
            }
          }).then(res => {
            if (!res.ok) throw new Error(`Error en ${endpoint.key}`);
            return res.json();
          })
        )
      );

      // Procesamiento seguro de datos
      const [productosData, categoriasData, generosData] = responses;

      setProductos(Array.isArray(productosData) ? productosData : []);
      setCategorias(Array.isArray(categoriasData) ? categoriasData : []);

      // Manejo flexible de la respuesta de géneros
      let generosProcesados = [];
      if (Array.isArray(generosData)) {
        generosProcesados = generosData;
      } else if (generosData && Array.isArray(generosData.generos)) {
        generosProcesados = generosData.generos;
      } else if (generosData && generosData.data) {
        generosProcesados = generosData.data;
      }
      setGeneros(generosProcesados);

    } catch (error) {
      console.error("Error:", error);
      setMensaje(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFormData(prev => ({ ...prev, imagen: file }));
      
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewImage(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMensaje("");
    
    if (!formData.id_categoria) {
      setMensaje("Debes seleccionar una categoría");
      return;
    }

    if (!formData.id_genero) {
      setMensaje("Debes seleccionar un género");
      return;
    }

    const url = editData
      ? `http://localhost:5000/productos/${editData.id}`
      : "http://localhost:5000/productos/nuevo";
    const method = editData ? "PUT" : "POST";

    try {
      const formDataToSend = new FormData();
      formDataToSend.append('nombre', formData.nombre);
      formDataToSend.append('descripcion', formData.descripcion);
      formDataToSend.append('precio', formData.precio);
      formDataToSend.append('estado', formData.estado);
      formDataToSend.append('id_categoria', formData.id_categoria);
      formDataToSend.append('id_genero', formData.id_genero);
      
      if (formData.imagen) {
        formDataToSend.append('imagen', formData.imagen);
      }

      const response = await fetch(url, {
        method,
        headers: {
          Authorization: `Bearer ${token}`,
        },
        body: formDataToSend,
      });

      const responseData = await response.json();

      if (!response.ok) {
        throw new Error(responseData.error || "Error en la operación");
      }

      setMensaje(editData ? "Producto actualizado con éxito" : "Producto creado con éxito");
      await fetchData();
      resetForm();
    } catch (error) {
      console.error('Error:', error);
      setMensaje(error.message || "Error al procesar la solicitud");
    }
  };

  const resetForm = () => {
    setFormData({
      nombre: "",
      descripcion: "",
      precio: "",
      estado: "Disponible",
      id_categoria: "",
      id_genero: "",
      imagen: null
    });
    setPreviewImage(null);
    setEditData(null);
  };

  const handleEdit = (producto) => {
    setEditData(producto);
    setFormData({
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      precio: producto.precio,
      estado: producto.estado,
      id_categoria: producto.id_categoria.toString(),
      id_genero: producto.id_genero.toString(),
      imagen: null
    });
    setPreviewImage(producto.imagen_url || null);
  };

  const handleDelete = async (id) => {
    if (!window.confirm("¿Estás seguro de eliminar este producto?")) return;
    
    try {
      const response = await fetch(`http://localhost:5000/productos/${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Error al eliminar");
      }

      setMensaje("Producto eliminado con éxito");
      await fetchData();
    } catch (error) {
      console.error("Error deleting product:", error);
      setMensaje(error.message);
    }
  };

  const getNombreCategoria = (idCategoria) => {
    const categoria = categorias.find(cat => cat.id === idCategoria);
    return categoria ? categoria.nombre : `ID: ${idCategoria}`;
  };

  const getNombreGenero = (idGenero) => {
    const genero = generos.find(gen => gen.id === idGenero);
    return genero ? genero.nombre : `ID: ${idGenero}`;
  };

  if (loading) {
    return (
      <div className="admin-productos-container">
        <div className="container">
          <h1>Cargando...</h1>
        </div>
      </div>
    );
  }

  return (
    <div className="admin-productos-container">
      <div className="container">
        <h1 data-aos="fade-down" data-aos-duration="1000">Gestión de Productos</h1>

        {mensaje && (
          <div className={`alert ${mensaje.includes("Error") ? "error" : "success"}`}>
            {mensaje}
          </div>
        )}

        <div className="form-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>{editData ? "Editar Producto" : "Crear Producto"}</h2>
          <form onSubmit={handleSubmit} encType="multipart/form-data">
            <div className="form-group">
              <label>Nombre:</label>
              <input
                type="text"
                name="nombre"
                placeholder="Nombre del producto"
                value={formData.nombre}
                onChange={handleChange}
                required
              />
            </div>
            
            <div className="form-group">
              <label>Descripción:</label>
              <textarea
                name="descripcion"
                placeholder="Descripción del producto"
                value={formData.descripcion}
                onChange={handleChange}
              />
            </div>
            
            <div className="form-group">
              <label>Precio:</label>
              <input
                type="number"
                name="precio"
                placeholder="Precio"
                min="0"
                step="0.01"
                value={formData.precio}
                onChange={handleChange}
                required
              />
            </div>
           
            
            <div className="form-group">
              <label>Categoría:</label>
              <select
                name="id_categoria"
                value={formData.id_categoria}
                onChange={handleChange}
                required
              >
                <option value="">Seleccione una categoría</option>
                {categorias.map(categoria => (
                  <option key={categoria.id} value={categoria.id}>
                    {categoria.nombre}
                  </option>
                ))}
              </select>
            </div>
            
            <div className="form-group">
              <label>Género:</label>
              <select
                name="id_genero"
                value={formData.id_genero}
                onChange={handleChange}
                required
              >
                <option value="">Seleccione un género</option>
                {generos.map(genero => (
                  <option key={genero.id} value={genero.id}>
                    {genero.nombre}
                  </option>
                ))}
              </select>
            </div>
            
            <div className="form-group">
              <label>Imagen del Producto:</label>
              <input
                type="file"
                name="imagen"
                accept="image/*"
                onChange={handleImageChange}
                required={!editData}
              />
              {previewImage && (
                <div className="image-preview">
                  <img src={previewImage} alt="Vista previa" />
                </div>
              )}
            </div>
            
            <div className="form-actions">
              <button type="submit" className="btn-submit">
                {editData ? "Guardar Cambios" : "Crear Producto"}
              </button>
              {editData && (
                <button type="button" className="btn-cancel" onClick={resetForm}>
                  Cancelar
                </button>
              )}
            </div>
          </form>
        </div>

        <div className="table-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>Lista de Productos</h2>
          {productos.length === 0 ? (
            <p>No hay productos registrados</p>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Nombre</th>
                  <th>Descripción</th>
                  <th>Precio</th>
                  <th>Estado</th>
                  <th>Categoría</th>
                  <th>Género</th>
                  <th>Imagen</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {productos.map((producto) => (
                  <tr key={producto.id}>
                    <td>{producto.nombre}</td>
                    <td>{producto.descripcion}</td>
                    <td>${producto.precio?.toFixed(2) || '0.00'}</td>
                    <td className={`estado-${producto.estado?.toLowerCase()?.replace(' ', '-') || ''}`}>
                      {producto.estado || 'Desconocido'}
                    </td>
                    <td>{getNombreCategoria(producto.id_categoria)}</td>
                    <td>{getNombreGenero(producto.id_genero)}</td>
                    <td>
                      {producto.imagen_url && (
                        <img 
                          src={producto.imagen_url} 
                          alt={producto.nombre}
                          className="product-image"
                          onError={(e) => {
                            e.target.onerror = null; 
                            e.target.src = 'https://via.placeholder.com/50';
                          }}
                        />
                      )}
                    </td>
                    <td>
                      <button 
                        onClick={() => handleEdit(producto)} 
                        className="btn-edit"
                      >
                        Editar
                      </button>
                      <button 
                        onClick={() => handleDelete(producto.id)} 
                        className="btn-delete"
                      >
                        Eliminar
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdminProductos;