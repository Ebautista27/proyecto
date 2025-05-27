import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import './HistorialComprasPrueba.css';


const HistorialCompras = () => {
    const [compras, setCompras] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [expandedCompra, setExpandedCompra] = useState(null);
    const navigate = useNavigate();

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) {
            navigate('/login');
            return;
        }

        const fetchCompras = async () => {
            try {
                const response = await fetch('http://localhost:5000/api/mis-compras', {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!response.ok) {
                    throw new Error('Error al obtener el historial');
                }

                const data = await response.json();
                setCompras(data.compras || []);
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        fetchCompras();
    }, [navigate]);

    const toggleExpandCompra = (id) => {
        setExpandedCompra(expandedCompra === id ? null : id);
    };

    const formatFecha = (fecha) => {
        const options = { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' };
        return new Date(fecha).toLocaleDateString('es-ES', options);
    };

    if (loading) {
        return (
            <div className="loading-container">
                <div className="spinner"></div>
                <p>Cargando tu historial de compras...</p>
            </div>
        );
    }

    if (error) {
        return (
            <div className="error-container">
                <h2>Error</h2>
                <p>{error}</p>
                <button onClick={() => window.location.reload()}>Intentar de nuevo</button>
            </div>
        );
    }

    if (compras.length === 0) {
        return (
            <div className="empty-history">
                
                <h2>Aún no has realizado compras</h2>
                <p>Cuando hagas una compra, aparecerá aquí.</p>
                <button onClick={() => navigate('/')}>Explorar productos</button>
            </div>
        );
    }

    return (
        <div className="historial-container">
            <h1>Mi Historial de Compras</h1>
            
            <div className="compras-list">
                {compras.map((compra) => (
                    <div key={compra.id} className={`compra-card ${expandedCompra === compra.id ? 'expanded' : ''}`}>
                        <div className="compra-header" onClick={() => toggleExpandCompra(compra.id)}>
                            <div className="compra-info">
                                <span className="compra-id">Productos Comprados</span>
                                <span className="compra-fecha">{formatFecha(compra.fecha)}</span>
                               
                            </div>
                            <div className="compra-total">
                                ${compra.total.toFixed(2)}
                                <span className="toggle-icon">
                                    {expandedCompra === compra.id ? '▲' : '▼'}
                                </span>
                            </div>
                        </div>
                        
                        {expandedCompra === compra.id && (
                            <div className="compra-details">
                                <div className="detalle-pago">
                                    <h3>Información de pago</h3>
                                    <p><strong>Método de pago:</strong> {compra.metodo_pago || 'No especificado'}</p>
                                    <p><strong>Barrio:</strong> {compra.barrio || 'No especificado'}</p>
                                    {compra.observaciones && (
                                        <p><strong>Observaciones:</strong> {compra.observaciones}</p>
                                    )}
                                </div>
                                
                                <h3>Productos</h3>
                                <div className="productos-list">
                                    {compra.productos.map((producto) => (
                                        <div key={`${compra.id}-${producto.id}`} className="producto-item2">
                                            <img 
                                                src={producto.imagen || '/images/product-placeholder.jpg'} 
                                                alt={producto.nombre} 
                                                onError={(e) => {
                                                    e.target.src = '/images/product-placeholder.jpg';
                                                }}
                                            />
                                            <div className="producto-info">
                                                <h4>{producto.nombre}</h4>
                                                <p>Talla: {producto.talla}</p>
                                                <p>Cantidad: {producto.cantidad}</p>
                                            </div>
                                            <div className="producto-precio">
                                                <p>${producto.precio.toFixed(2)} c/u</p>
                                                <p className="subtotal">Subtotal: ${producto.subtotal.toFixed(2)}</p>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
};

export default HistorialCompras;