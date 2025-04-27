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
  });

  const [editData, setEditData] = useState(null);
  const [mensaje, setMensaje] = useState("");

  useEffect(() => {
    AOS.init();
    fetchCompras();
    fetchMetodosPago();
    fetchUsuarios();
  }, []);

  const fetchCompras = async () => {
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
      console.error("Error fetching compras:", error);
      setMensaje("Error al cargar las compras.");
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
      console.error("Error fetching métodos de pago:", error);
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
        // Asegurándonos que data es un array y tiene la propiedad nombre
        setUsuarios(Array.isArray(data) ? data : []);
      } else {
        setMensaje(data.mensaje || "Error al cargar los usuarios.");
      }
    } catch (error) {
      setMensaje("Error al cargar los usuarios.");
      console.error("Error fetching usuarios:", error);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    const token = localStorage.getItem("token");
    if (!token) {
      setMensaje("No hay token de autenticación.");
      return;
    }

    const url = editData
      ? `http://127.0.0.1:5000/compras/${editData.id}`
      : "http://127.0.0.1:5000/Crearcompras";
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
        setMensaje(editData ? "Compra actualizada correctamente ✅" : "Compra creada correctamente ✅");
        fetchCompras();
        setFormData({
          barrio: "",
          observaciones: "",
          usuario_id: "",
          metodo_pago_id: "",
          estado_pedido: "Procesado",
        });
        setEditData(null);
      } else {
        const errorData = await response.json();
        setMensaje(errorData.mensaje || "Error al guardar la compra ❌");
      }
    } catch (error) {
      setMensaje("Error al guardar la compra.");
      console.error("Error:", error);
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
    });
  };

  const handleDelete = async (id) => {
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        setMensaje("No hay token de autenticación.");
        return;
      }

      const response = await fetch(`http://127.0.0.1:5000/compras/${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (response.ok) {
        setMensaje("Compra eliminada correctamente ✅");
        fetchCompras();
      } else {
        setMensaje("Error al eliminar la compra ❌");
      }
    } catch (error) {
      setMensaje("Error al eliminar la compra.");
      console.error("Error en la eliminación:", error);
    }
  };

  const estadosCompra = [
    "Procesado",
    "Enviado",
    "Entregado",
    "Cancelado"
  ];

  return (
    <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
      <div className="container">
        <h1 data-aos="fade-down" data-aos-duration="1000">Gestión de Compras</h1>

        {mensaje && <div className="alert alert-info" data-aos="fade-in">{mensaje}</div>}

        <div className="form-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>{editData ? "Editar Compra" : "Crear Compra"}</h2>
          <form onSubmit={handleSubmit} className="form-style">
            <input
              className="input-field"
              type="text"
              name="barrio"
              placeholder="Barrio"
              value={formData.barrio}
              onChange={handleChange}
              required
            />

            <input
              className="input-field"
              type="text"
              name="observaciones"
              placeholder="Observaciones (opcional)"
              value={formData.observaciones}
              onChange={handleChange}
            />

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
                  {metodo.id} - {metodo.tipo}
                </option>
              ))}
            </select>

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
                  {u.id} - {u.nombre} {u.apellido || ''} {/* Agregado apellido por si acaso */}
                </option>
              ))}
            </select>
            <button type="submit" className="btn-primary">
              {editData ? "Guardar Cambios" : "Crear Compra"}
            </button>
          </form>
        </div>

        <div className="table-container" data-aos="fade-up" data-aos-duration="1500">
          <h2>Lista de Compras</h2>
          <table className="table-style">
            <thead>
              <tr>
                <th>ID</th>
                <th>Barrio</th>
                <th>Observaciones</th>
                <th>Estado</th>
                <th>ID Usuario</th>
                <th>ID Método Pago</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {compras.map((compra) => (
                <tr key={compra.id}>
                  <td>{compra.id}</td>
                  <td>{compra.barrio}</td>
                  <td>{compra.observaciones || "-"}</td>
                  <td>{compra.estado_pedido}</td>
                  <td>{compra.usuario_id}</td>
                  <td>{compra.metodo_pago_id}</td>
                  <td>
                    <button onClick={() => handleEdit(compra)}>Editar</button>
                    <button onClick={() => handleDelete(compra.id)}>Eliminar</button>
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

export default AdminCompras;