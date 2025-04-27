import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import './Confirmación.css';

const Confirmacion = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const [compraId, setCompraId] = useState('');
    const [fechaCompra, setFechaCompra] = useState('');

    useEffect(() => {
        // Obtener datos de la compra si se pasaron por navigate
        if (location.state?.compraId) {
            setCompraId(location.state.compraId);
        }
        
        // Establecer fecha actual
        const ahora = new Date();
        setFechaCompra(ahora.toLocaleDateString('es-ES', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }));
    }, [location]);

    const volverInicio = () => {
        navigate('/');
    };

    return (
        <div className="confirmacion-container">
            <div className="mensaje-confirmacion">
                <h1>¡Compra realizada con éxito! 🎉</h1>
                <div className="detalles-compra">
                    {compraId && <p><strong>Número de pedido:</strong> #{compraId}</p>}
                    <p><strong>Fecha:</strong> {fechaCompra}</p>
                    <p>Hemos recibido tu pedido correctamente y lo estamos procesando.</p>
                    <p>Recibirás una confirmación adicional por correo electrónico.</p>
                </div>

                <div className="acciones-confirmacion">
                    <button className="boton-primario" onClick={volverInicio}>
                        Volver al inicio
                    </button>
                    <button 
                        className="boton-secundario" 
                        onClick={() => navigate('/mis-compras')} // Ajusta esta ruta según tu app
                    >
                        Ver mis compras
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Confirmacion;