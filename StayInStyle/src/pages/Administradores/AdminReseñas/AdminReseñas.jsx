import React, { useState, useEffect } from "react";
import AOS from "aos";
import "aos/dist/aos.css";
import "./adminReseñas.css";
import { useNavigate } from "react-router-dom";

const AdminReseñas = () => {
    const [reseñas, setReseñas] = useState([]);
    const [productos, setProductos] = useState([]);
    const [usuarios, setUsuarios] = useState([]);
    const [formData, setFormData] = useState({
        comentario: "",
        calificacion: 5,
        id_producto: "",
        id_usuario: "" // Agregado para seleccionar el usuario
    });
    const [editData, setEditData] = useState(null);
    const [mensaje, setMensaje] = useState("");
    const token = localStorage.getItem("token");
    const navigate = useNavigate();

    useEffect(() => {
        AOS.init();
        fetchReseñas();
        fetchProductos();
        fetchUsuarios(); // Ahora también se obtienen los usuarios
    }, []);

    const fetchReseñas = async () => {
        try {
            const response = await fetch("http://127.0.0.1:5000/reseñas", {
                headers: { Authorization: `Bearer ${token}` },
            });
            const data = await response.json();
            if (response.ok) {
                setReseñas(data);
            } else {
                setMensaje(data.mensaje || "Error al cargar las reseñas.");
            }
        } catch (error) {
            setMensaje("Error al cargar las reseñas.");
        }
    };

    const fetchProductos = async () => {
        try {
            const response = await fetch("http://127.0.0.1:5000/productos", {
                headers: { Authorization: `Bearer ${token}` },
            });
            const data = await response.json();
            if (response.ok) {
                setProductos(data);
            }
        } catch (error) {
            console.error("Error al cargar productos:", error);
        }
    };

    const fetchUsuarios = async () => {
        try {
            const response = await fetch("http://127.0.0.1:5000/usuarios", {
                headers: { Authorization: `Bearer ${token}` },
            });
            const data = await response.json();
            if (response.ok) {
                setUsuarios(data);
            }
        } catch (error) {
            console.error("Error al cargar usuarios:", error);
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData({ ...formData, [name]: value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (formData.calificacion < 1 || formData.calificacion > 5) {
            setMensaje("La calificación debe ser entre 1 y 5");
            return;
        }

        try {
            let url, method;
            
            if (editData) {
                // Edición de reseña existente
                url = `http://127.0.0.1:5000/reseñas/${editData.id}`;
                method = "PUT";
            } else {
                // Creación de nueva reseña
                url = `http://127.0.0.1:5000/productos/${formData.id_producto}/crear-reseña`;
                method = "POST";
            }

            const response = await fetch(url, {
                method,
                headers: { 
                    "Content-Type": "application/json", 
                    Authorization: `Bearer ${token}` 
                },
                body: JSON.stringify({
                    comentario: formData.comentario,
                    calificacion: formData.calificacion,
                    id_usuario: formData.id_usuario // Incluyendo el usuario seleccionado
                }),
            });

            if (response.ok) {
                setMensaje(editData ? "Reseña actualizada ✅" : "Reseña creada ✅");
                fetchReseñas();
                setFormData({ 
                    comentario: "", 
                    calificacion: 5, 
                    id_producto: "",
                    id_usuario: "" // Limpiar el usuario seleccionado
                });
                setEditData(null);
            } else {
                const errorData = await response.json();
                setMensaje(errorData.mensaje || "Error al guardar la reseña ❌");
            }
        } catch (error) {
            setMensaje("Error de conexión al servidor ❌");
        }
    };

    const handleEdit = (reseña) => {
        setEditData(reseña);
        setFormData({
            comentario: reseña.comentario,
            calificacion: reseña.calificacion,
            id_producto: reseña.id_producto,
            id_usuario: reseña.id_usuario // Cargar usuario en edición
        });
    };

    const handleDelete = async (id) => {
        if (!window.confirm("¿Estás seguro de eliminar esta reseña?")) return;
        
        try {
            const response = await fetch(`http://127.0.0.1:5000/reseñas/${id}`, {
                method: "DELETE",
                headers: { Authorization: `Bearer ${token}` },
            });

            if (response.ok) {
                setMensaje("Reseña eliminada ✅");
                fetchReseñas();
            } else {
                const errorData = await response.json();
                setMensaje(errorData.mensaje || "Error al eliminar la reseña ❌");
            }
        } catch (error) {
            setMensaje("Error de conexión al servidor ❌");
        }
    };

    return (
        <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
            <div className="container">
                <h1 data-aos="fade-down" data-aos-duration="1000">Gestión de Reseñas</h1>
                {mensaje && (
                    <div className={`alert ${mensaje.includes("✅") ? "alert-success" : "alert-error"}`}>
                        {mensaje}
                    </div>
                )}

                <div className="form-container" data-aos="fade-up" data-aos-duration="1500">
                    <h2>{editData ? "Editar Reseña" : "Crear Reseña"}</h2>
                    <form onSubmit={handleSubmit}>
                        <textarea
                            name="comentario"
                            placeholder="Comentario"
                            value={formData.comentario}
                            onChange={handleChange}
                            required
                            rows="3"
                        />
                        
                        <div className="form-group">
                            <label>Calificación (1-5):</label>
                            <input
                                type="number"
                                name="calificacion"
                                min="1"
                                max="5"
                                value={formData.calificacion}
                                onChange={handleChange}
                                required
                            />
                        </div>
                        
                        {/* Selección de Producto */}
                        <div className="form-group">
                            <label>Producto:</label>
                            <select
                                name="id_producto"
                                value={formData.id_producto}
                                onChange={handleChange}
                                required={!editData}
                                disabled={!!editData}
                            >
                                <option value="">Seleccione un producto</option>
                                {productos.map(producto => (
                                    <option key={producto.id} value={producto.id}>
                                        {producto.nombre}
                                    </option>
                                ))}
                            </select>
                        </div>

                        {/* Selección de Usuario */}
                        <div className="form-group">
                            <label>Usuario:</label>
                            <select
                                name="id_usuario"
                                value={formData.id_usuario}
                                onChange={handleChange}
                                required
                            >
                                <option value="">Seleccione un usuario</option>
                                {usuarios.map(usuario => (
                                    <option key={usuario.id} value={usuario.id}>
                                        {usuario.nombre}
                                    </option>
                                ))}
                            </select>
                        </div>
                        
                        <button type="submit" className="btn-primary">
                            {editData ? "Guardar Cambios" : "Crear Reseña"}
                        </button>
                        {editData && (
                            <button 
                                type="button" 
                                className="btn-secondary"
                                onClick={() => {
                                    setEditData(null);
                                    setFormData({
                                        comentario: "", 
                                        calificacion: 5, 
                                        id_producto: "",
                                        id_usuario: "" // Limpiar el usuario seleccionado
                                    });
                                }}
                            >
                                Cancelar
                            </button>
                        )}
                    </form>
                </div>

                {/* Tabla de Reseñas */}
                <div className="table-container" data-aos="fade-up" data-aos-duration="1500">
                    <h2>Lista de Reseñas</h2>
                    <table className="table-style">
                        <thead>
                            <tr>
                                <th>Usuario</th>
                                <th>Producto</th>
                                <th>Comentario</th>
                                <th>Calificación</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            {reseñas.map((reseña) => (
                                <tr key={reseña.id}>
                                    <td>{reseña.usuario?.nombre || "Usuario desconocido"}</td>
                                    <td>{reseña.producto?.nombre || "Producto desconocido"}</td>
                                    <td>{reseña.comentario}</td>
                                    <td>{reseña.calificacion}</td>
                                    <td>
                                        <button 
                                            onClick={() => handleEdit(reseña)}
                                            className="btn-edit"
                                        >
                                            Editar
                                        </button>
                                        <button 
                                            onClick={() => handleDelete(reseña.id)}
                                            className="btn-delete"
                                        >
                                            Eliminar
                                        </button>
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

export default AdminReseñas;
