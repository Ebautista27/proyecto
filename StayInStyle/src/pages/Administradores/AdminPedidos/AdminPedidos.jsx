import React, { useState, useEffect } from "react";
import AOS from "aos";
import "aos/dist/aos.css";
import "./adminpedidos.css";

const AdminCompras = () => {
  const [compras, setCompras] = useState([]);
  const [metodosPago, setMetodosPago] = useState([]);
  const [usuarios, setUsuarios] = useState([]);
  const [formData, setFormData] = useState({
    barrio: "",
    observaciones: "",
    usuario_id: "",
    metodo_pago_id: "",
    estado_pedido: "Procesado",
    productos: []
  });

  const [editData, setEditData] = useState(null);
  const [mensaje, setMensaje] = useState("");
  const [loading, setLoading] = useState(false);
  const [isSendingEmail, setIsSendingEmail] = useState(false);

  useEffect(() => {
    AOS.init();
    fetchCompras();
    fetchMetodosPago();
    fetchUsuarios();
  }, []);

  const fetchCompras = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setMensaje("No hay token de autenticación.");
        return;
      }

      const response = await fetch("http://127.0.0.1:5000/compras/todas", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) throw new Error("Error al cargar las compras");

      const data = await response.json();
      setCompras(data);
    } catch (error) {
      console.error("Error al cargar compras:", error);
      setMensaje("Error al cargar las compras.");
    } finally {
      setLoading(false);
    }
  };

  const fetchMetodosPago = async () => {
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setMensaje("No hay token de autenticación.");
        return;
      }

      const response = await fetch("http://127.0.0.1:5000/metodos_pago", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();
      if (response.ok) {
        setMetodosPago(data);
      } else {
        setMensaje("Error al cargar métodos de pago.");
      }
    } catch (error) {
      setMensaje("Error al cargar métodos de pago.");
      console.error("Error al cargar métodos de pago:", error);
    }
  };

  const fetchUsuarios = async () => {
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setMensaje("No hay token de autenticación.");
        return;
      }

      const response = await fetch("http://127.0.0.1:5000/usuarios", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();
      if (response.ok) {
        const usuariosData = Array.isArray(data.usuarios) ? data.usuarios : [];
        setUsuarios(usuariosData);
      } else {
        setMensaje(data.mensaje || "Error al cargar los usuarios.");
      }
    } catch (error) {
      setMensaje("Error al cargar los usuarios.");
      console.error("Error al cargar usuarios:", error);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const formatProductos = (productos) => {
    if (!productos || !Array.isArray(productos)) return "No hay detalles de productos";
    
    // Formatear cada producto mostrando nombre y cantidad
    return productos.map(p => 
      `- ${p.nombre || 'Producto'} (Cantidad: ${p.cantidad || 1})`
    ).join('\n');
  };

  const enviarNotificacion = async (compraId, estado) => {
    if (isSendingEmail) return;
    setIsSendingEmail(true);
    
    console.log(`[Notificación] Iniciando envío para compra ${compraId}, estado: ${estado}`);
    
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        console.error("[Notificación] No se encontró token de autenticación");
        return;
      }

      const compra = compras.find(c => c.id == compraId);
      if (!compra) {
        console.error(`[Notificación] No se encontró compra con ID ${compraId}`);
        return;
      }

      const usuario = usuarios.find(u => u.id == compra.usuario_id);
      
      if (!usuario) {
        console.error(`[Notificación] No se encontró usuario con ID ${compra.usuario_id}`);
        return;
      }

      if (!usuario.email || usuario.email.trim() === "") {
        console.error(`[Notificación] Usuario ${usuario.id} no tiene email registrado`);
        return;
      }

      const detalleProductos = formatProductos(compra.productos);
      
      let asunto, mensaje;
      switch(estado) {
        case "Procesado":
          asunto = "Tu pedido está siendo procesado";
          mensaje = `Hola ${usuario.nombre},\n\nTu pedido con los siguientes productos:\n${detalleProductos}\n\nEstá siendo preparado.\n\nGracias por tu compra!`;
          break;
        case "Enviado":
          asunto = "¡Tu pedido está en camino!";
          mensaje = `Hola ${usuario.nombre},\n\nTu pedido con los siguientes productos:\n${detalleProductos}\n\nHa sido enviado.\n\nTiempo estimado: 5-8 días.`;
          break;
        case "Entregado":
          asunto = "¡Pedido entregado!";
          mensaje = `Hola ${usuario.nombre},\n\nTu pedido con los siguientes productos:\n${detalleProductos}\n\nHa sido entregado. ¡Esperamos que lo disfrutes!`;
          break;
        case "Cancelado":
          asunto = "Pedido cancelado";
          mensaje = `Hola ${usuario.nombre},\n\nLamentamos informarte que tu pedido con los siguientes productos:\n${detalleProductos}\n\nHa sido cancelado.\n\nContacto: soporte@tienda.com`;
          break;
        default:
          console.error(`[Notificación] Estado no reconocido: ${estado}`);
          return;
      }

      const response = await fetch("http://localhost:5000/notificaciones", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`
        },
        body: JSON.stringify({
          asunto,
          mensaje,
          destinatarios: [usuario.email],
          incluir_local: true,
          local_email: "dilandakrg@gmail.com"
        })
      });

      const data = await response.json();
      console.log("[Notificación] Respuesta del servidor:", data);

      if (!response.ok) {
        throw new Error(data.mensaje || "Error al enviar notificación");
      }

      return data;
    } catch (error) {
      console.error("[Notificación] Error al enviar notificación:", error);
      throw error;
    } finally {
      setIsSendingEmail(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (loading) return;
    
    setLoading(true);
    setMensaje("");

    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setMensaje("No hay token de autenticación.");
        return;
      }

      const url = editData
        ? `http://127.0.0.1:5000/compras/${editData.id}`
        : "http://127.0.0.1:5000/compras";
      const method = editData ? "PUT" : "POST";

      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(formData),
      });

      const responseData = await response.json();

      if (!response.ok) {
        throw new Error(responseData.mensaje || "Error al guardar la compra");
      }

      let mensajeEstado = editData 
        ? "Compra actualizada correctamente ✅" 
        : "Compra creada correctamente ✅";

      if (editData) {
        if (formData.estado_pedido !== editData.estado_pedido) {
          await enviarNotificacion(editData.id, formData.estado_pedido);
        }
      } else if (formData.estado_pedido !== "Procesado") {
        await enviarNotificacion(responseData.id, formData.estado_pedido);
      }

      setMensaje(mensajeEstado);
      fetchCompras();
      setFormData({
        barrio: "",
        observaciones: "",
        usuario_id: "",
        metodo_pago_id: "",
        estado_pedido: "Procesado",
        productos: []
      });
      setEditData(null);

    } catch (error) {
      console.error("Error en handleSubmit:", error);
      setMensaje(`Error: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (compra) => {
    setEditData(compra);
    setFormData({
      barrio: compra.barrio,
      observaciones: compra.observaciones || "",
      usuario_id: compra.usuario_id,
      metodo_pago_id: compra.metodo_pago_id,
      estado_pedido: compra.estado_pedido,
      productos: compra.productos || []
    });
  };

  const handleDelete = async (id) => {
    if (!window.confirm("¿Estás seguro de eliminar esta compra?")) return;
    
    setLoading(true);
    setMensaje("");

    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setMensaje("No hay token de autenticación.");
        return;
      }

      await enviarNotificacion(id, "Cancelado");

      const response = await fetch(`http://127.0.0.1:5000/compras/${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.mensaje || "Error al eliminar la compra");
      }

      setMensaje("Compra eliminada correctamente ✅");
      fetchCompras();

    } catch (error) {
      console.error("Error en handleDelete:", error);
      setMensaje(`Error: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const estadosCompra = [
    "Procesado",
    "Enviado",
    "Entregado",
    "Cancelado"
  ];

  const getNombreUsuario = (userId) => {
    const usuario = usuarios.find(u => u.id == userId);
    return usuario ? `${usuario.nombre} ${usuario.apellido || ''}` : "Usuario no encontrado";
  };

  const getMetodoPago = (metodoId) => {
    const metodo = metodosPago.find(m => m.id == metodoId);
    return metodo ? metodo.tipo : "Método no encontrado";
  };

  return (
    <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
      <div className="container">
        <h1 data-aos="fade-down" data-aos-duration="1000">Gestión de Compras</h1>

        {mensaje && (
          <div className={`alert ${mensaje.includes("✅") ? "alert-success" : "alert-danger"}`} data-aos="fade-in">
            {mensaje}
          </div>
        )}

        <div className="form-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>{editData ? "Editar Compra" : "Crear Compra"}</h2>
          <form onSubmit={handleSubmit} className="form-style">
            <div className="form-group">
              <label>Barrio:</label>
              <input
                className="input-field"
                type="text"
                name="barrio"
                placeholder="Barrio"
                value={formData.barrio}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label>Observaciones:</label>
              <input
                className="input-field"
                type="text"
                name="observaciones"
                placeholder="Observaciones (opcional)"
                value={formData.observaciones}
                onChange={handleChange}
              />
            </div>

            <div className="form-group">
              <label>Estado:</label>
              <select
                className="input-field"
                name="estado_pedido"
                value={formData.estado_pedido}
                onChange={handleChange}
                required
              >
                {estadosCompra.map(estado => (
                  <option key={estado} value={estado}>{estado}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>Método de Pago:</label>
              <select
                name="metodo_pago_id"
                value={formData.metodo_pago_id}
                onChange={handleChange}
                className="input-field"
                required
              >
                <option value="">Seleccione un método de pago</option>
                {metodosPago.map((metodo) => (
                  <option key={metodo.id} value={metodo.id}>
                    {metodo.tipo}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>Usuario:</label>
              <select
                className="input-field"
                name="usuario_id"
                value={formData.usuario_id}
                onChange={handleChange}
                required
              >
                <option value="">Seleccione un usuario</option>
                {usuarios.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.nombre} {u.apellido || ''}
                  </option>
                ))}
              </select>
            </div>

            <button type="submit" className="btn-primary" disabled={loading}>
              {loading ? "Procesando..." : editData ? "Guardar Cambios" : "Crear Compra"}
            </button>
          </form>
        </div>

        <div className="table-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>Lista de Compras</h2>
          {loading ? (
            <div className="loading">Cargando compras...</div>
          ) : (
            <table className="table-style">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Barrio</th>
                  <th>Observaciones</th>
                  <th>Estado</th>
                  <th>Usuario</th>
                  <th>Método Pago</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {compras.length > 0 ? (
                  compras.map((compra) => (
                    <tr key={compra.id}>
                      <td>{compra.id}</td>
                      <td>{compra.barrio}</td>
                      <td>{compra.observaciones || "-"}</td>
                      <td>{compra.estado_pedido}</td>
                      <td>{getNombreUsuario(compra.usuario_id)}</td>
                      <td>{getMetodoPago(compra.metodo_pago_id)}</td>
                      <td className="actions">
                        <button 
                          onClick={() => handleEdit(compra)} 
                          className="btn-edit"
                        >
                          Editar
                        </button>
                        <button 
                          onClick={() => handleDelete(compra.id)} 
                          className="btn-delete"
                        >
                          Eliminar
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="7" className="no-data">No hay compras registradas</td>
                  </tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdminCompras;