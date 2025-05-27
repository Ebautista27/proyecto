import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import './Confirmación.css';

const Confirmacion = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const [compraInfo, setCompraInfo] = useState({
        id: '',
        fecha: '',
        productos: [],
        total: 0,
        barrio: '',
        metodoPago: ''
    });

    useEffect(() => {
        if (location.state) {
            const fechaFormateada = new Date(location.state.fecha || new Date()).toLocaleDateString('es-ES', {
                weekday: 'long',
                day: 'numeric',
                month: 'long',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
            
            setCompraInfo({
                id: location.state.compraId || '',
                fecha: fechaFormateada,
                productos: location.state.productos || [],
                total: location.state.total || 0,
                barrio: location.state.barrio || '',
                metodoPago: location.state.metodoPago || ''
            });
        } else {
            navigate('/');
        }
    }, [location, navigate]);

    const volverInicio = () => {
        navigate('/');
    };

    return (
        <div className="confirmacion-container">
            <div className="mensaje-confirmacion">
                <div className="icono-exito">
                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                        <polyline points="22 4 12 14.01 9 11.01"></polyline>
                    </svg>
                </div>
                <h1>¡Compra realizada con éxito! 🎉</h1>
                <p className="subtitulo">Tu pedido ha sido confirmado</p>
                
                <div className="detalles-compra">
                    <div className="resumen-pedido">
                        <div className="info-pedido">
                            <div className="info-item">
                                <span className="info-label">Fecha:</span>
                                <span className="info-value">{compraInfo.fecha}</span>
                            </div>
                            <div className="info-item">
                                <span className="info-label">Barrio de entrega:</span>
                                <span className="info-value">{compraInfo.barrio}</span>
                            </div>
                            <div className="info-item">
                                <span className="info-label">Método de pago:</span>
                                <span className="info-value">{compraInfo.metodoPago}</span>
                            </div>
                        </div>
                    </div>
                    
                    <div className="productos-compra">
                        <h3>Productos comprados</h3>
                        <ul className="lista-productos">
                            {compraInfo.productos.map((producto, index) => (
                                <li key={index} className="producto-item4">
                                    <div className="imagen-container">
                                        <img 
                                            src={producto.imagen_url || 'https://via.placeholder.com/300x300?text=Imagen+no+disponible'} 
                                            alt={producto.nombre}
                                            className="producto-imagen"
                                            onError={(e) => {
                                                e.target.onerror = null; 
                                                e.target.src = 'https://via.placeholder.com/300x300?text=Imagen+no+disponible'
                                            }}
                                        />
                                    </div>
                                    <div className="producto-info">
                                        <span className="producto-nombre">{producto.nombre}</span>
                                        <div className="detalles-producto">
                                            <span className="producto-talla">Talla: {producto.talla}</span>
                                            <span className="producto-cantidad">Cantidad: {producto.cantidad}</span>
                                        </div>
                                    </div>
                                    <div className="producto-precio">
                                        ${(producto.precio_unitario * producto.cantidad).toLocaleString()}
                                    </div>
                                </li>
                            ))}
                        </ul>
                    </div>
                    
                    <div className="total-final-simple">
                        <strong>Total: ${compraInfo.total.toLocaleString()}</strong>
                    </div>
                    
                    <div className="mensaje-final">
                        <p>Hemos recibido tu pedido correctamente y lo estamos procesando.</p>
                        <p>Recibirás una confirmación adicional por correo electrónico con los detalles de seguimiento.</p>
                        <p>¡Gracias por confiar en nosotros!</p>
                    </div>
                    
                    <div className="acciones-confirmacion">
                        <button className="boton-primario" onClick={volverInicio}>
                            Volver al inicio
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Confirmacion;