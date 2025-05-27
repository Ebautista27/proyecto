import React, { useState, useEffect } from "react";
import "./adminstock.css";

const AdminStock = () => {
  const [inventory, setInventory] = useState([]);
  const [products, setProducts] = useState([]);
  const [tallas, setTallas] = useState([]);
  const [historial, setHistorial] = useState([]);
  const [showHistorial, setShowHistorial] = useState(false);
  const [showHistorialGeneral, setShowHistorialGeneral] = useState(false);
  const [formData, setFormData] = useState({
    id_producto: "",
    id_talla: "",
    stock: 0,
    motivo: ""
  });
  const [editId, setEditId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [successMsg, setSuccessMsg] = useState(null);
  const token = localStorage.getItem("token");

  // Fetch inicial de datos
  useEffect(() => {
    const fetchInitialData = async () => {
      try {
        setLoading(true);
        
        const [productsRes, tallasRes] = await Promise.all([
          fetch('http://localhost:5000/productos', {
            headers: { 'Authorization': `Bearer ${token}` }
          }),
          fetch('http://localhost:5000/api/tallas', {
            headers: { 'Authorization': `Bearer ${token}` }
          })
        ]);

        if (!productsRes.ok) throw new Error(await productsRes.text());
        if (!tallasRes.ok) throw new Error(await tallasRes.text());

        const [productsData, tallasData] = await Promise.all([
          productsRes.json(),
          tallasRes.json()
        ]);

        setProducts(productsData);
        setTallas(tallasData.tallas || tallasData);

      } catch (err) {
        setError(`Error al cargar datos iniciales: ${err.message}`);
      } finally {
        setLoading(false);
      }
    };

    fetchInitialData();
  }, [token]);

  // Cargar inventario cuando se selecciona un producto
  useEffect(() => {
    if (formData.id_producto) {
      fetchInventory();
    }
  }, [formData.id_producto]);

  const fetchInventory = async () => {
    try {
      const res = await fetch(`http://localhost:5000/api/productos/${formData.id_producto}/inventario`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (!res.ok) throw new Error(await res.text());
      const data = await res.json();
      setInventory(data);
    } catch (err) {
      setError(`Error al cargar inventario: ${err.message}`);
    }
  };

  const fetchHistorialProducto = async () => {
    try {
      const res = await fetch(`http://localhost:5000/api/historial-stock/producto/${formData.id_producto}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (!res.ok) throw new Error(await res.text());
      const data = await res.json();
      setHistorial(data);
    } catch (err) {
      setError(`Error al cargar historial del producto: ${err.message}`);
    }
  };

  const fetchHistorialGeneral = async () => {
    try {
      const res = await fetch('http://localhost:5000/api/historial-stock', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (!res.ok) throw new Error(await res.text());
      const data = await res.json();
      setHistorial(data);
    } catch (err) {
      setError(`Error al cargar historial general: ${err.message}`);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      setError(null);
      setSuccessMsg(null);

      // Validaciones
      if (!formData.id_producto || !formData.id_talla) {
        throw new Error("Debes seleccionar un producto y una talla");
      }

      const stockNum = parseInt(formData.stock);
      if (isNaN(stockNum) || stockNum < 0) {
        throw new Error("El stock debe ser un número positivo");
      }

      let stockAnterior = 0;
      let response;
      let method;
      let url;

      if (editId) {
        // Modo edición
        const itemExistente = inventory.find(item => item.id === editId);
        if (!itemExistente) throw new Error("Registro no encontrado");
        
        stockAnterior = itemExistente.stock;
        method = 'PUT';
        url = `http://localhost:5000/api/inventario/${editId}`;
        response = await fetch(url, {
          method,
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            stock: stockNum
          })
        });
      } else {
        // Modo creación
        method = 'POST';
        url = `http://localhost:5000/api/productos/${formData.id_producto}/inventario`;
        response = await fetch(url, {
          method,
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            id_talla: parseInt(formData.id_talla),
            stock: stockNum
          })
        });
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.mensaje || "Error en la operación");
      }

      // Registrar en historial si hay cambio
      if (editId && stockAnterior !== stockNum) {
        await registerHistorialChange(
          editId,
          stockAnterior,
          stockNum,
          formData.motivo || "Actualización manual"
        );
      }

      setSuccessMsg(editId ? "¡Inventario actualizado!" : "¡Nuevo stock agregado!");
      
      // Refrescar datos
      await fetchInventory();
      if (showHistorial) await fetchHistorialProducto();
      if (showHistorialGeneral) await fetchHistorialGeneral();
      resetForm();
    } catch (err) {
      setError(err.message);
    }
  };

  const registerHistorialChange = async (inventoryId, oldStock, newStock, motivo) => {
    try {
      const response = await fetch('http://localhost:5000/api/historial-stock/crear', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          id_inventario: inventoryId,
          stock_anterior: oldStock,
          stock_nuevo: newStock,
          motivo: motivo
        })
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.mensaje || "Error al registrar en historial");
      }
    } catch (err) {
      console.error("Error al registrar en historial:", err);
      throw err;
    }
  };

  const handleEdit = (item) => {
    setFormData({
      id_producto: item.id_producto.toString(),
      id_talla: item.id_talla.toString(),
      stock: item.stock,
      motivo: ""
    });
    setEditId(item.id);
  };

  const handleDelete = async (id) => {
    if (!window.confirm("¿Estás seguro de eliminar este registro de inventario?")) return;
    
    try {
      const item = inventory.find(i => i.id === id);
      if (!item) throw new Error("Registro no encontrado");
      
      const response = await fetch(`http://localhost:5000/api/inventario/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.mensaje || "Error al eliminar");
      }

      // Registrar eliminación en el historial
      await registerHistorialChange(
        id,
        item.stock,
        0,
        "Eliminación de registro"
      );

      setSuccessMsg("¡Registro de inventario eliminado!");
      setInventory(prev => prev.filter(item => item.id !== id));
      if (showHistorial) await fetchHistorialProducto();
      if (showHistorialGeneral) await fetchHistorialGeneral();
    } catch (err) {
      setError(err.message);
    }
  };

  const resetForm = () => {
    setFormData({ id_producto: "", id_talla: "", stock: 0, motivo: "" });
    setEditId(null);
  };

  const getProductName = (id) => {
    return products.find(p => p.id === id)?.nombre || 'N/A';
  };

  const getProductImage = (id) => {
    const product = products.find(p => p.id === id);
    return product?.imagen_url || 'https://via.placeholder.com/50';
  };

  const getTallaName = (id) => {
    const talla = tallas.find(t => t.id === id);
    return talla ? talla.nombre : 'N/A';
  };

  const formatDate = (dateString) => {
    const options = { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' };
    return new Date(dateString).toLocaleDateString('es-ES', options);
  };

  if (loading) return <div className="loading">Cargando datos iniciales...</div>;

  return (
    <div className="admin-stock-container">
      <h1>Gestión de Stock</h1>
      
      {error && <div className="error-message">{error}</div>}
      {successMsg && <div className="success-message">{successMsg}</div>}

      <div className="form-section">
        <h2>{editId ? "Editar Registro" : "Agregar Stock"}</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Producto:</label>
            <select
              name="id_producto"
              value={formData.id_producto}
              onChange={handleChange}
              required
              disabled={editId !== null}
            >
              <option value="">Seleccionar producto</option>
              {products.map(product => (
                <option key={product.id} value={product.id}>
                  {product.nombre}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label>Talla:</label>
            <select
              name="id_talla"
              value={formData.id_talla}
              onChange={handleChange}
              required
              disabled={!formData.id_producto}
            >
              <option value="">Seleccionar talla</option>
              {tallas.map(t => (
                <option key={t.id} value={t.id}>
                  {t.nombre}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label>Cantidad:</label>
            <input
              type="number"
              name="stock"
              min="0"
              value={formData.stock}
              onChange={handleChange}
              required
            />
          </div>

          {editId && (
            <div className="form-group">
              <label>Motivo del cambio (opcional):</label>
              <input
                type="text"
                name="motivo"
                value={formData.motivo}
                onChange={handleChange}
                placeholder="Ej: Ajuste de inventario"
              />
            </div>
          )}

          <div className="form-actions">
            <button type="submit" className="btn-submit">
              {editId ? "Actualizar" : "Agregar"}
            </button>
            {editId && (
              <button type="button" onClick={resetForm} className="btn-cancel">
                Cancelar
              </button>
            )}
          </div>
        </form>
      </div>

      <div className="inventory-section">
        <div className="section-header">
          <h2>Inventario Actual</h2>
          <div className="historial-buttons">
            {formData.id_producto && (
              <button 
                onClick={() => {
                  setShowHistorial(!showHistorial);
                  setShowHistorialGeneral(false);
                  if (!showHistorial) fetchHistorialProducto();
                }} 
                className={`btn-historial ${showHistorial ? 'active' : ''}`}
              >
                {showHistorial ? "Ocultar Historial" : "Historial del Producto"}
              </button>
            )}
            <button 
              onClick={() => {
                setShowHistorialGeneral(!showHistorialGeneral);
                setShowHistorial(false);
                if (!showHistorialGeneral) fetchHistorialGeneral();
              }} 
              className={`btn-historial ${showHistorialGeneral ? 'active' : ''}`}
            >
              {showHistorialGeneral ? "Ocultar Historial General" : "Historial General"}
            </button>
          </div>
        </div>

        {(showHistorial || showHistorialGeneral) ? (
          <div className="historial-table">
            <table>
              <thead>
                <tr>
                  <th>Fecha</th>
                  <th>Producto</th>
                  <th>Talla</th>
                  <th>Stock Anterior</th>
                  <th>Stock Nuevo</th>
                  <th>Cambio</th>
                  <th>Motivo</th>
                </tr>
              </thead>
              <tbody>
                {historial.length > 0 ? (
                  historial.map(item => (
                    <tr key={item.id}>
                      <td>{formatDate(item.fecha_cambio)}</td>
                      <td>
                        <div className="product-info">
                          <img 
                            src={item.producto_imagen || 'https://via.placeholder.com/50'} 
                            alt={item.producto_nombre}
                            className="product-thumbnail"
                          />
                          <span>{item.producto_nombre || 'N/A'}</span>
                        </div>
                      </td>
                      <td>{item.talla_nombre || 'N/A'}</td>
                      <td>{item.stock_anterior}</td>
                      <td>{item.stock_nuevo}</td>
                      <td className={item.diferencia > 0 ? 'positive-change' : 'negative-change'}>
                        {item.diferencia > 0 ? `+${item.diferencia}` : item.diferencia}
                      </td>
                      <td>{item.motivo}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="7" className="no-data">No hay registros de historial</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        ) : (
          <>
            {formData.id_producto ? (
              inventory.length > 0 ? (
                <table className="inventory-table">
                  <thead>
                    <tr>
                      <th>Producto</th>
                      <th>Imagen</th>
                      <th>Talla</th>
                      <th>Stock</th>
                      <th>Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {inventory.map(item => (
                      <tr key={item.id}>
                        <td>{getProductName(item.id_producto)}</td>
                        <td>
                          <img 
                            src={getProductImage(item.id_producto)} 
                            alt={getProductName(item.id_producto)}
                            className="product-image"
                          />
                        </td>
                        <td>{getTallaName(item.id_talla)}</td>
                        <td className={item.stock > 0 ? 'in-stock' : 'out-of-stock'}>
                          {item.stock}
                        </td>
                        <td>
                          <button onClick={() => handleEdit(item)} className="btn-edit">
                            Editar
                          </button>
                          <button onClick={() => handleDelete(item.id)} className="btn-delete">
                            Eliminar
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <p className="no-data">No hay registros de inventario para este producto</p>
              )
            ) : (
              <p className="select-product-message">Selecciona un producto para ver su inventario</p>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default AdminStock;