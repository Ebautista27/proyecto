import React, { useEffect, useState } from 'react';
import './Comprar.css';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Swal from 'sweetalert2';

const Comprar = () => {
    const [metodosPago, setMetodosPago] = useState([]);
    const [metodoSeleccionado, setMetodoSeleccionado] = useState('');
    const [barrio, setBarrio] = useState('');
    const [observaciones, setObservaciones] = useState('');
    const [error, setError] = useState('');
    const [successMessage, setSuccessMessage] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [carrito, setCarrito] = useState([]);
    const [isLoadingCarrito, setIsLoadingCarrito] = useState(true);
    const [nombreUsuario, setNombreUsuario] = useState('');
    const navigate = useNavigate();

    const token = localStorage.getItem('token');
    const correoUsuario = localStorage.getItem('email_usuario');
    const usuario_actual_id = localStorage.getItem('id_usuario');

    useEffect(() => {
        const fetchDatosUsuario = async () => {
            try {
                const [carritoResponse, usuarioResponse] = await Promise.all([
                    axios.get('http://localhost:5000/api/carritos/productos', {
                        headers: { 'Authorization': `Bearer ${token}` }
                    }),
                    axios.get(`http://localhost:5000/usuarios/${usuario_actual_id}`, {
                        headers: { 'Authorization': `Bearer ${token}` }
                    })
                ]);

                if (carritoResponse.data.carrito) {
                    setCarrito(carritoResponse.data.carrito.productos.map(item => ({
                        ...item,
                        id_talla: item.id_talla, // Asegurar que id_talla está presente
                        talla: item.talla // Mantener para mostrar al usuario
                    })));
                } else {
                    setCarrito([]);
                }

                if (usuarioResponse.data) {
                    setNombreUsuario(usuarioResponse.data.nombre);
                }
            } catch (error) {
                console.error('Error al obtener datos:', error);
                setCarrito([]);
            } finally {
                setIsLoadingCarrito(false);
            }
        };

        const fetchMetodosPago = async () => {
            try {
                const response = await axios.get('http://localhost:5000/metodos_pago', {
                    headers: { 'Authorization': `Bearer ${token}` }
                });
                setMetodosPago(response.data);
            } catch (error) {
                console.error('Error al obtener métodos de pago:', error);
                setError('No se pudieron cargar los métodos de pago');
            }
        };

        if (token) {
            fetchDatosUsuario();
            fetchMetodosPago();
        } else {
            setError('Debes iniciar sesión para realizar una compra');
            setIsLoadingCarrito(false);
            navigate('/login');
        }
    }, [token, navigate, usuario_actual_id]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setSuccessMessage('');
        setIsLoading(true);

        if (!barrio || !metodoSeleccionado || carrito.length === 0) {
            setError('Por favor complete todos los campos requeridos y asegúrese de tener productos en el carrito');
            setIsLoading(false);
            return;
        }

        try {
            // Preparar datos para la compra usando id_talla
            const productosCompra = carrito.map(item => ({
                id_producto: item.id_producto,
                id_talla: item.id_talla, // Usar id_talla en lugar de talla
                cantidad: item.cantidad,
                precio_unitario: item.precio_unitario
            }));

            // Registrar la compra
            const response = await axios.post('http://localhost:5000/Crearcompras', {
                barrio,
                observaciones: observaciones || null,
                metodo_pago_id: parseInt(metodoSeleccionado),
                productos: productosCompra
            }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });

            const resultado = response.data;

            // Enviar correo de confirmación
            if (correoUsuario) {
                try {
                    const metodoPago = metodosPago.find(m => m.id === parseInt(metodoSeleccionado))?.tipo || '';
                    const fechaCompra = new Date().toLocaleDateString('es-ES', { 
                        weekday: 'long', 
                        day: 'numeric', 
                        month: 'long',
                        year: 'numeric'
                    });
                    
                    const detalleProductos = carrito.map(item => 
                        `✔ ${item.nombre} (Talla: ${item.talla})  ${item.cantidad} x $${item.precio_unitario.toLocaleString()} = $${(item.precio_unitario * item.cantidad).toLocaleString()}`
                    ).join('\n');
                    
                    await axios.post('http://localhost:5000/notificaciones', {
                        asunto: `¡${nombreUsuario}, tu compra en STAY IN STYLE fue exitosa! 🎉`,
                        mensaje: `¡Felicitaciones ${nombreUsuario}! 🎉\n\nTu pedido está confirmado.\n\n📅 Fecha: ${fechaCompra}\n📦 Detalles de envío:\n📍 Barrio: ${barrio}\n💳 Método de pago: ${metodoPago}\n📝 Observaciones: ${observaciones || 'Ninguna'}\n\n🛍️ Productos:\n${detalleProductos}\n\n💰 Total: $${resultado.total.toLocaleString()}\n\nTu pedido estará listo en 5-8 días hábiles.\n\n¿Necesitas ayuda?\n📧 contacto@stayinstyle.com\n📞 +57 315 460 1332\n\n¡Gracias por comprar en STAY IN STYLE!`,
                        destinatarios: [correoUsuario],
                        incluir_local: true
                    }, {
                        headers: { 'Authorization': `Bearer ${token}` }
                    });
                } catch (emailError) {
                    console.error('Error al enviar correo:', emailError);
                }
            }

            // Limpiar carrito después de la compra
            try {
                await axios.delete('http://localhost:5000/api/carritos/productos', {
                    headers: { 'Authorization': `Bearer ${token}` },
                    data: { producto_id: 'all' }
                });
            } catch (error) {
                console.error('Error al vaciar carrito:', error);
            }

            setSuccessMessage('¡Compra realizada con éxito! Redirigiendo...');
            
            setTimeout(() => {
                navigate('/Confirmación', { 
                    state: { 
                        compraId: resultado.compra_id,
                        productos: carrito,
                        total: resultado.total,
                        barrio,
                        metodoPago: metodosPago.find(m => m.id === parseInt(metodoSeleccionado))?.tipo || '',
                        fecha: new Date().toISOString(),
                        nombreUsuario
                    } 
                });
            }, 2000);

        } catch (error) {
            console.error('Error al procesar compra:', error);
            const errorMessage = error.response?.data?.mensaje || 'Ocurrió un error al procesar tu compra';
            setError(errorMessage);
            
            if (error.response?.status === 401 || error.response?.status === 403) {
                Swal.fire({
                    title: 'Error de autenticación',
                    text: 'Tu sesión ha expirado o no tienes permisos. Serás redirigido al login.',
                    icon: 'error',
                    confirmButtonText: 'Entendido'
                }).then(() => {
                    navigate('/login');
                });
            }
        } finally {
            setIsLoading(false);
        }
    };

    if (isLoadingCarrito) {
        return (
            <div className="loading-screen">
                <div className="spinner"></div>
                <p>Cargando tu carrito...</p>
            </div>
        );
    }

    return (
        <div className="checkout-container">
            <h1 className="checkout-title">Finalizar Compra</h1>
            {error && <div className="alert error">{error}</div>}
            {successMessage && <div className="alert success">{successMessage}</div>}
            
            {carrito.length === 0 ? (
                <div className="empty-cart">
                    <p>No tienes productos en tu carrito</p>
                    <button 
                        className="btn-shop"
                        onClick={() => navigate('/')}
                    >
                        Volver a la tienda
                    </button>
                </div>
            ) : (
                <div className="checkout-content">
                    <div className="order-section">
                        <h2 className="section-title">Resumen de tu pedido</h2>
                        <div className="products-list">
                            {carrito.map((producto, index) => (
                                <div key={index} className="product-item">
                                    <img 
                                        src={producto.imagen_url || 'https://via.placeholder.com/100'} 
                                        alt={producto.nombre}
                                        className="product-image"
                                        onError={(e) => e.target.src = 'https://via.placeholder.com/100'}
                                    />
                                    <div className="product-details">
                                        <h3 className="product-name">{producto.nombre}</h3>
                                        <p className="product-info">Talla: {producto.talla}</p>
                                        <p className="product-info">Cantidad: x{producto.cantidad}</p>
                                        <p className="product-price">
                                            ${(producto.precio_unitario * producto.cantidad).toLocaleString()}
                                        </p>
                                    </div>
                                </div>
                            ))}
                        </div>

                        <div className="total-section">
                            <p className="total-text">
                                <span>Total:</span>
                                <span className="total-amount">
                                    ${carrito.reduce((total, item) => total + (item.precio_unitario * item.cantidad), 0).toLocaleString()}
                                </span>
                            </p>
                        </div>
                    </div>

                    <form onSubmit={handleSubmit} className="checkout-form">
                        <div className="form-section">
                            <h2 className="section-title">Información de Entrega</h2>
                            
                            <div className="form-group">
                                <label>Barrio *</label>
                                <input
                                    type="text"
                                    value={barrio}
                                    onChange={(e) => setBarrio(e.target.value)}
                                    required
                                    placeholder="Ej: Chapinero, Usaquén, etc."
                                />
                            </div>
                            
                            <div className="form-group">
                                <label>Observaciones</label>
                                <textarea
                                    value={observaciones}
                                    onChange={(e) => setObservaciones(e.target.value)}
                                    placeholder="Instrucciones especiales para la entrega (opcional)"
                                    rows="4"
                                />
                            </div>
                        </div>

                        <div className="form-section">
                            <h2 className="section-title">Método de Pago *</h2>
                            
                            <div className="payment-options">
                                {metodosPago.length > 0 ? (
                                    metodosPago.map((metodo) => (
                                        <div 
                                            key={metodo.id}
                                            className={`payment-option ${metodoSeleccionado === metodo.id.toString() ? 'selected' : ''}`}
                                            onClick={() => setMetodoSeleccionado(metodo.id.toString())}
                                        >
                                            <input
                                                type="radio"
                                                id={`metodo-${metodo.id}`}
                                                name="metodoPago"
                                                value={metodo.id}
                                                checked={metodoSeleccionado === metodo.id.toString()}
                                                onChange={() => {}}
                                                required
                                            />
                                            <label htmlFor={`metodo-${metodo.id}`}>
                                                <span className="payment-type">{metodo.tipo}</span>
                                                <span className="payment-desc">{metodo.detalle}</span>
                                            </label>
                                        </div>
                                    ))
                                ) : (
                                    <p className="no-payment">No hay métodos de pago disponibles</p>
                                )}
                            </div>
                        </div>

                        <button 
                            type="submit" 
                            className="checkout-btn"
                            disabled={isLoading || carrito.length === 0}
                        >
                            {isLoading ? (
                                <>
                                    <span className="btn-spinner"></span>
                                    Procesando...
                                </>
                            ) : (
                                `Confirmar Compra (${carrito.length} ${carrito.length === 1 ? 'producto' : 'productos'})`
                            )}
                        </button>
                    </form>
                </div>
            )}
        </div>
    );
};

export default Comprar;