import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import "./OlvidarContrasena.css";

export default function ResetPasswordPage() {
  const { token } = useParams();
  const navigate = useNavigate();
  const [contrasena, setContrasena] = useState('');
  const [confirmar, setConfirmar] = useState('');
  const [mensaje, setMensaje] = useState('');
  const [error, setError] = useState(false);
  const [exito, setExito] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (contrasena !== confirmar) {
      setError(true);
      setMensaje('Las contraseñas no coinciden.');
      return;
    }

    try {
      const response = await axios.post(`http://localhost:5000/reset-password/${token}`, {
        contrasena,
      });
      setExito(true);
      setMensaje(response.data.mensaje);
      setTimeout(() => navigate('/IniciarSesion'), 3000);
    } catch (err) {
      setError(true);
      setMensaje(err.response?.data?.mensaje || 'Ocurrió un error.');
    }
  };

  // Estilos mejorados
  const styles = {
    pageContainer: {
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: "#E5E1DA" ,
      color: 'white',
      padding: '20px',
      fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
    },
    card: {
      width: '100%',
      maxWidth: '450px',
      background: 'rgba(235, 12, 12, 0.05)',
      backdropFilter: 'blur(10px)',
      borderRadius: '16px',
      padding: '30px',
      boxShadow: '0 8px 32px 0 rgba(31, 38, 135, 0.37)',
      border: '1px solid rgba(255, 255, 255, 0.18)',
      animation: 'fadeIn 0.5s ease-in-out'
    },
    title: {
      fontSize: '28px',
      fontWeight: '700',
      marginBottom: '25px',
      textAlign: 'center',
      color: '#f8bb86',
      textShadow: '0 2px 4px rgba(0,0,0,0.2)'
    },
    message: {
      marginBottom: '20px',
      padding: '12px 15px',
      borderRadius: '8px',
      fontSize: '14px',
      fontWeight: '500',
      textAlign: 'center',
      transition: 'all 0.3s ease'
    },
    error: {
      backgroundColor: 'rgba(109, 52, 45, 0.8)'
    },
    success: {
      backgroundColor: 'rgba(46, 204, 113, 0.8)'
    },
    form: {
      display: 'flex',
      flexDirection: 'column',
      gap: '20px'
    },
    input: {
      padding: '14px 16px',
      borderRadius: '8px',
      background: 'rgba(255, 255, 255, 0.1)',
      border: '1px solid rgba(255, 255, 255, 0.2)',
      color: 'white',
      fontSize: '15px',
      transition: 'all 0.3s',
      outline: 'none'
    },
    inputFocus: {
      borderColor: '#f8bb86',
      boxShadow: '0 0 0 3px rgba(248, 187, 134, 0.3)',
      background: 'rgba(255, 255, 255, 0.15)'
    },
    button: {
      padding: '14px',
      borderRadius: '8px',
      background: 'linear-gradient(135deg, #f8bb86 0%, #f5a623 100%)',
      color: '#1a1a2e',
      fontWeight: '600',
      fontSize: '16px',
      border: 'none',
      cursor: 'pointer',
      transition: 'all 0.3s',
      boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
      marginTop: '10px'
    },
    buttonHover: {
      transform: 'translateY(-2px)',
      boxShadow: '0 6px 12px rgba(0, 0, 0, 0.15)'
    }
  };

  return (
    <div style={styles.pageContainer}>
      <div style={styles.card}>
      <h1 className="text-3xl font-bold mb-6 text-center text-black">Restablecer Contraseña</h1>

        {mensaje && (
          <div style={{
            ...styles.message,
            ...(error ? styles.error : styles.success)
          }}>{mensaje}</div>
        )}

        <form onSubmit={handleSubmit} style={styles.form}>
          <input
            type="password"
            placeholder="Nueva contraseña"
            style={styles.input}
            value={contrasena}
            onChange={(e) => setContrasena(e.target.value)}
            required
            onFocus={(e) => e.target.style = {...styles.input, ...styles.inputFocus}}
            onBlur={(e) => e.target.style = styles.input}
          />
          <input
            type="password"
            placeholder="Confirmar contraseña"
            style={styles.input}
            value={confirmar}
            onChange={(e) => setConfirmar(e.target.value)}
            required
            onFocus={(e) => e.target.style = {...styles.input, ...styles.inputFocus}}
            onBlur={(e) => e.target.style = styles.input}
          />
          <button
            type="submit"
            style={styles.button}
            onMouseEnter={(e) => e.target.style = {...styles.button, ...styles.buttonHover}}
            onMouseLeave={(e) => e.target.style = styles.button}
          >
            Restablecer
          </button>
        </form>
      </div>
    </div>
  );
}