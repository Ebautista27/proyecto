import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import './Pedido.css';

const Pedido = () => {
    const [pedidos, setPedidos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [expandedPedido, setExpandedPedido] = useState(null);
    const navigate = useNavigate();

    // Mapeo de estados con íconos y colores
    const estadoConfig = {
        'pendiente': {
            texto: 'Pendiente de confirmación',
            icono: '⏳',
            color: '#FFC107',
            bgColor: '#FFF3CD'
        },
        'confirmado': {
            texto: 'Pedido confirmado',
            icono: '✅',
            color: '#17A2B8',
            bgColor: '#D1ECF1'
        },
        'preparando': {
            texto: 'En preparación',
            icono: '👨‍🍳',
            color: '#007BFF',
            bgColor: '#CCE5FF'
        },
        'enviado': {
            texto: 'En camino',
            icono: '🚚',
            color: '#28A745',
            bgColor: '#D4EDDA'
        },
        'entregado': {
            texto: 'Entregado',
            icono: '📦',
            color: '#6C757D',
            bgColor: '#E2E3E5'
        },
        'cancelado': {
            texto: 'Cancelado',
            icono: '❌',
            color: '#DC3545',
            bgColor: '#F8D7DA'
        }
    };

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) {
            navigate('/login');
            return;
        }

        const fetchPedidos = async () => {
            try {
                const response = await fetch('http://localhost:5000/api/mis-compras', {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!response.ok) {
                    throw new Error('Error al obtener los pedidos');
                }

                const data = await response.json();
                setPedidos(data.compras || []);
            } catch (err) {
                console.error('Error al obtener pedidos:', err);
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        fetchPedidos();
    }, [navigate]);

    const toggleExpandPedido = (id) => {
        setExpandedPedido(expandedPedido === id ? null : id);
    };

    const formatFecha = (fecha) => {
        const options = { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' };
        return new Date(fecha).toLocaleDateString('es-ES', options);
    };

    const calcularTiempoEstimado = (estado, fecha) => {
        const fechaPedido = new Date(fecha);
        const ahora = new Date();
        const diffHoras = Math.abs(ahora - fechaPedido) / 36e5;
        
        if (estado === 'pendiente') return 'Confirmación pendiente';
        if (estado === 'confirmado') return `En preparación (${Math.floor(diffHoras)}h)`;
        if (estado === 'preparando') return `Listo para envío en ~${24 - Math.floor(diffHoras)}h`;
        if (estado === 'enviado') return `Entrega estimada: ${new Date(fechaPedido.getTime() + (48 * 60 * 60 * 1000)).toLocaleDateString()}`;
        if (estado === 'entregado') return `Entregado el ${formatFecha(fecha)}`;
        if (estado === 'cancelado') return 'Pedido cancelado';
        
        return 'Tiempo estimado no disponible';
    };

    if (loading) {
        return (
            <div className="loading-container">
                <div className="spinner"></div>
                <p>Cargando tus pedidos...</p>
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

    if (pedidos.length === 0) {
        return (
            <div className="empty-history">
                <h2>No tienes pedidos realizados</h2>
                <p>Cuando hagas un pedido, aparecerá aquí con su estado actual.</p>
                <button onClick={() => navigate('/')}>Explorar productos</button>
            </div>
        );
    }

    return (
        <div className="pedido-container">
            <h1>Seguimiento de tus Pedidos</h1>
            <p className="subtitle">Revisa el estado de tus compras y los detalles de envío</p>
            
            <div className="timeline-container">
                {pedidos.map((pedido) => (
                    <div key={pedido.id} className={`pedido-card ${expandedPedido === pedido.id ? 'expanded' : ''}`}>
                        <div className="pedido-header" onClick={() => toggleExpandPedido(pedido.id)}>
                            <div className="pedido-info">
                                <span className="pedido-id">Pedidos</span>
                                <span className="pedido-fecha">{formatFecha(pedido.fecha)}</span>
                            </div>
                            <div className="pedido-estado-container">
                                <span 
                                    className="pedido-estado"
                                    style={{
                                        color: estadoConfig[pedido.estado.toLowerCase()]?.color || '#000',
                                        backgroundColor: estadoConfig[pedido.estado.toLowerCase()]?.bgColor || '#EEE'
                                    }}
                                >
                                    {estadoConfig[pedido.estado.toLowerCase()]?.icono || '📦'} 
                                    {estadoConfig[pedido.estado.toLowerCase()]?.texto || pedido.estado}
                                </span>
                                <span className="pedido-total">
                                    ${pedido.total.toFixed(2)}
                                    <span className="toggle-icon">
                                        {expandedPedido === pedido.id ? '▲' : '▼'}
                                    </span>
                                </span>
                            </div>
                        </div>
                        
                        {expandedPedido === pedido.id && (
                            <div className="pedido-details">
                                <div className="pedido-progreso">
    <div className="progress-bar">
        {/* Paso 1 - Confirmado */}
        <div className={`progress-step ${
            ['confirmado', 'preparando', 'enviado', 'entregado'].includes(pedido.estado.toLowerCase()) ? 'active' : ''
        }`}>
            <span>1</span>
            <p>Confirmado</p>
        </div>
        
        {/* Paso 2 - Preparando */}
        <div className={`progress-step ${
            ['preparando', 'enviado', 'entregado'].includes(pedido.estado.toLowerCase()) ? 'active' : ''
        }`}>
            <span>2</span>
            <p>Preparando</p>
        </div>
        
        {/* Paso 3 - Enviado */}
        <div className={`progress-step ${
            ['enviado', 'entregado'].includes(pedido.estado.toLowerCase()) ? 'active' : ''
        }`}>
            <span>3</span>
            <p>Enviado</p>
        </div>
        
        {/* Paso 4 - Entregado */}
        <div className={`progress-step ${
            pedido.estado.toLowerCase() === 'entregado' ? 'active' : ''
        }`}>
            <span>4</span>
            <p>Entregado</p>
        </div>
    </div>
    <div className="tiempo-estimado">
        <span>⏱️ {calcularTiempoEstimado(pedido.estado.toLowerCase(), pedido.fecha)}</span>
    </div>
</div>
                                
                                <div className="detalle-envio">
                                    <h3>📦 Información de envío</h3>
                                    <div className="envio-info">
                                        <p><strong>Dirección:</strong> {pedido.barrio || 'No especificado'}</p>
                                        {pedido.observaciones && (
                                            <p><strong>Instrucciones:</strong> {pedido.observaciones}</p>
                                        )}
                                        <p><strong>Método de pago:</strong> {pedido.metodo_pago || 'No especificado'}</p>
                                    </div>
                                </div>
                                
                                <h3>🛒 Productos en este pedido</h3>
                                <div className="productos-list">
                                    {pedido.productos.map((producto) => (
                                        <div key={`${pedido.id}-${producto.id}`} className="producto-item">
                                            <img 
                                                src={producto.imagen || '/images/product-placeholder.jpg'} 
                                                alt={producto.nombre} 
                                                onError={(e) => {
                                                    e.target.src = '/images/product-placeholder.jpg';
                                                }}
                                            />
                                            <div className="producto-info">
                                                <h4>{producto.nombre}</h4>
                                                <div className="producto-detalle">
                                                    <span>Talla: {producto.talla}</span>
                                                    <span>Cantidad: {producto.cantidad}</span>
                                                </div>
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

export default Pedido;