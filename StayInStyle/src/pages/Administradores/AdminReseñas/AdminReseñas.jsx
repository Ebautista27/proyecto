import React, { useState, useEffect } from "react";
import AOS from "aos";
import "aos/dist/aos.css";
import { useNavigate } from "react-router-dom";
import "./adminReseñas.css";

const AdminReseñas = () => {
    const [reseñas, setReseñas] = useState([]);
    const [productos, setProductos] = useState([]);
    const [usuarios, setUsuarios] = useState([]);
    const [formData, setFormData] = useState({
        comentario: "",
        calificacion: 5,
        id_producto: "",
        id_usuario: ""
    });
    const [editData, setEditData] = useState(null);
    const [mensaje, setMensaje] = useState("");
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const token = localStorage.getItem("token");
    const navigate = useNavigate();

    useEffect(() => {
        AOS.init({ duration: 1000 });
        
        if (!token) {
            navigate("/login");
            return;
        }
        
        const fetchData = async () => {
            try {
                await Promise.all([fetchReseñas(), fetchProductos(), fetchUsuarios()]);
            } catch (error) {
                console.error("Error fetching data:", error);
                setError("Error al cargar los datos");
            } finally {
                setLoading(false);
            }
        };
        
        fetchData();
    }, [navigate, token]);

    const fetchReseñas = async () => {
        try {
            const response = await fetch("http://127.0.0.1:5000/reseñas", {
                headers: { Authorization: `Bearer ${token}` },
            });
            
            if (!response.ok) {
                throw new Error("Error al cargar reseñas");
            }
            
            const data = await response.json();
            setReseñas(Array.isArray(data) ? data : []);
        } catch (error) {
            setError(error.message);
        }
    };

    const fetchProductos = async () => {
        try {
            const response = await fetch("http://127.0.0.1:5000/productos", {
                headers: { Authorization: `Bearer ${token}` },
            });
            
            if (!response.ok) {
                throw new Error("Error al cargar productos");
            }
            
            const data = await response.json();
            setProductos(Array.isArray(data) ? data : []);
        } catch (error) {
            setError(error.message);
        }
    };

    const fetchUsuarios = async () => {
        try {
            const response = await fetch("http://127.0.0.1:5000/usuarios", {
                headers: { Authorization: `Bearer ${token}` },
            });
            
            if (!response.ok) {
                throw new Error("Error al cargar usuarios");
            }
            
            const data = await response.json();
            // Asegurarse de que data.usuarios existe y es un array
            const usuariosData = Array.isArray(data.usuarios) ? data.usuarios : 
                               Array.isArray(data) ? data : [];
            setUsuarios(usuariosData);
        } catch (error) {
            setError(error.message);
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
                url = `http://127.0.0.1:5000/reseñas/${editData.id}`;
                method = "PUT";
            } else {
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
                    id_usuario: formData.id_usuario
                }),
            });

            const data = await response.json();
            
            if (response.ok) {
                setMensaje(editData ? "Reseña actualizada ✅" : "Reseña creada ✅");
                await fetchReseñas();
                setFormData({ 
                    comentario: "", 
                    calificacion: 5, 
                    id_producto: "",
                    id_usuario: ""
                });
                setEditData(null);
            } else {
                setMensaje(data.mensaje || "Error al guardar la reseña ❌");
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
            id_usuario: reseña.id_usuario
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
                await fetchReseñas();
            } else {
                const errorData = await response.json();
                setMensaje(errorData.mensaje || "Error al eliminar la reseña ❌");
            }
        } catch (error) {
            setMensaje("Error de conexión al servidor ❌");
        }
    };

    if (loading) {
        return <div className="loading">Cargando...</div>;
    }

    if (error) {
        return <div className="error">{error}</div>;
    }

    return (
        <div className="admin-reseñas-container">
            <div className="container">
                <h1 data-aos="fade-down">Gestión de Reseñas</h1>
                {mensaje && (
                    <div className={`alert ${mensaje.includes("✅") ? "alert-success" : "alert-error"}`}>
                        {mensaje}
                    </div>
                )}

                <div className="form-container" data-aos="fade-up">
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
                                {Array.isArray(productos) && productos.map(producto => (
                                    <option key={producto.id} value={producto.id}>
                                        {producto.nombre}
                                    </option>
                                ))}
                            </select>
                        </div>

                        <div className="form-group">
                            <label>Usuario:</label>
                            <select
                                name="id_usuario"
                                value={formData.id_usuario}
                                onChange={handleChange}
                                required
                            >
                                <option value="">Seleccione un usuario</option>
                                {Array.isArray(usuarios) && usuarios.map(usuario => (
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
                                        id_usuario: ""
                                    });
                                }}
                            >
                                Cancelar
                            </button>
                        )}
                    </form>
                </div>

                <div className="table-container" data-aos="fade-up">
                    <h2>Lista de Reseñas</h2>
                    {reseñas.length === 0 ? (
                        <p>No hay reseñas disponibles</p>
                    ) : (
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
                    )}
                </div>
            </div>
        </div>
    );
};

export default AdminReseñas;