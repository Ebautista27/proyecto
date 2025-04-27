import React, { useState, useEffect } from 'react';
import './Comprar.css';
import { useNavigate } from 'react-router-dom';

const Comprar = () => {
    const [metodosPago, setMetodosPago] = useState([]);
    const [metodoSeleccionado, setMetodoSeleccionado] = useState('');
    const [barrio, setBarrio] = useState('');
    const [observaciones, setObservaciones] = useState('');
    const [error, setError] = useState('');
    const [successMessage, setSuccessMessage] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const navigate = useNavigate();

    // Obtener datos del usuario del localStorage
    const usuarioId = localStorage.getItem('userId') || 1;
    const carrito = JSON.parse(localStorage.getItem('carrito') || '[]');
    const correoUsuario = localStorage.getItem('email_usuario');
    const token = localStorage.getItem('token');

    useEffect(() => {
        const fetchMetodosPago = async () => {
            try {
                const response = await fetch('http://localhost:5000/metodos_pago', {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                if (!response.ok) {
                    throw new Error('Error al obtener métodos de pago');
                }
                const data = await response.json();
                setMetodosPago(data);
            } catch (error) {
                console.error('Error:', error);
                setError('No se pudieron cargar los métodos de pago');
            }
        };
        fetchMetodosPago();
    }, [token]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setSuccessMessage('');
        setIsLoading(true);

        // Validación básica
        if (!barrio || !metodoSeleccionado || carrito.length === 0) {
            setError('Por favor complete todos los campos requeridos y asegúrese de tener productos en el carrito');
            setIsLoading(false);
            return;
        }

        const compraData = {
            barrio,
            observaciones: observaciones || null,
            metodo_pago_id: parseInt(metodoSeleccionado),
            usuario_id: parseInt(usuarioId),
            productos: carrito
        };

        try {
            console.log('Datos de compra:', compraData);
            console.log('Email del usuario:', correoUsuario);

            // 1. Registrar la compra
            const response = await fetch('http://localhost:5000/Crearcompras', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(compraData),
            });

            const resultado = await response.json();
            
            if (!response.ok) {
                throw new Error(resultado.mensaje || 'Error al registrar la compra');
            }

            console.log('Compra registrada:', resultado);

            // 2. Enviar notificación por correo
            if (correoUsuario) {
                try {
                    console.log('Enviando correo a:', correoUsuario);
                    
                    const emailData = {
                        asunto: "Compra realizada con éxito 🛍️",
                        mensaje: `Hola,\n\nTu compra #${resultado.id} fue registrada correctamente.\n\nDetalles:\n- Barrio: ${barrio}\n- Método de pago: ${metodosPago.find(m => m.id === parseInt(metodoSeleccionado))?.tipo || ''}\n\n¡Gracias por comprar con nosotros!
                        Tu Compra llegara entre 10 a 15 días;) Feliz día`,
                        destinatarios: [correoUsuario],
                        incluir_local: true
                    };

                    console.log('Datos del correo:', emailData);

                    const notificacionResponse = await fetch('http://localhost:5000/notificaciones', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${token}`
                        },
                        body: JSON.stringify(emailData),
                    });

                    const notificacionResult = await notificacionResponse.json();
                    console.log('Respuesta del correo:', notificacionResult);

                    if (!notificacionResponse.ok) {
                        console.error('Error en respuesta del correo:', notificacionResult);
                        setSuccessMessage('Compra realizada! (El correo no pudo enviarse)');
                    } else {
                        setSuccessMessage('Compra realizada y correo enviado con éxito!');
                    }
                } catch (emailError) {
                    console.error('Error al enviar correo:', emailError);
                    setSuccessMessage('Compra realizada! (Error al enviar correo)');
                }
            } else {
                console.warn('No hay email del usuario para enviar notificación');
                setSuccessMessage('Compra realizada! (No se encontró email para notificación)');
            }

            // Limpiar carrito y redirigir
            localStorage.removeItem('carrito');
            setTimeout(() => {
                navigate('/Confirmación', { state: { compraId: resultado.id } });
            }, 2000);

        } catch (error) {
            console.error('Error completo:', error);
            setError(error.message || 'Ocurrió un error al procesar tu compra');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="page-container">
            <div className="comprar-container">
                <h1>Finalizar Compra</h1>
                {error && <div className="error-message">{error}</div>}
                {successMessage && <div className="success-message">{successMessage}</div>}
                
                <form onSubmit={handleSubmit} className="formulario-compra">
                    <div className="seccion-formulario">
                        <h2>Información de Entrega</h2>
                        
                        <div className="campo-formulario">
                            <label htmlFor="barrio">
                                Barrio <span className="required">*</span>
                            </label>
                            <input
                                id="barrio"
                                type="text"
                                value={barrio}
                                onChange={(e) => setBarrio(e.target.value)}
                                required
                                placeholder="Ej: Chapinero, Usaquén, etc."
                            />
                        </div>
                        
                        <div className="campo-formulario">
                            <label htmlFor="observaciones">Observaciones</label>
                            <textarea
                                id="observaciones"
                                value={observaciones}
                                onChange={(e) => setObservaciones(e.target.value)}
                                placeholder="Instrucciones especiales para la entrega (opcional)"
                                rows="4"
                            />
                        </div>
                    </div>

                    <div className="seccion-formulario">
                        <h2>Método de Pago <span className="required">*</span></h2>
                        
                        {metodosPago.length > 0 ? (
                            <div className="metodos-pago">
                                {metodosPago.map((metodo) => (
                                    <div key={metodo.id} className="opcion-pago">
                                        <input
                                            type="radio"
                                            id={`metodo-${metodo.id}`}
                                            name="metodoPago"
                                            value={metodo.id}
                                            checked={metodoSeleccionado === metodo.id.toString()}
                                            onChange={() => setMetodoSeleccionado(metodo.id.toString())}
                                            required
                                        />
                                        <label htmlFor={`metodo-${metodo.id}`}>
                                            <strong>{metodo.tipo}</strong> - {metodo.detalle}
                                        </label>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <p>Cargando métodos de pago...</p>
                        )}
                    </div>

                    <button 
                        type="submit" 
                        className="boton-confirmar"
                        disabled={isLoading}
                    >
                        {isLoading ? 'Procesando...' : 'Confirmar Compra'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default Comprar;