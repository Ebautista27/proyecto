import React, { useState } from 'react';
import axios from 'axios';

const ForgotPassword = () => {
  const [email, setEmail] = useState('');
  const [mensaje, setMensaje] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMensaje('');
    setError('');

    try {
      const response = await axios.post('http://localhost:5000/forgot-password', { email });
      setMensaje(response.data.mensaje);
    } catch (err) {
      if (err.response && err.response.data && err.response.data.mensaje) {
        setError(err.response.data.mensaje);
      } else {
        setError('Ocurrió un error al enviar la solicitud.');
      }
    }
  };

  // Objeto de estilos
  const styles = {
    container: {
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      backgroundColor: '#f5f5f5',
      fontFamily: 'Arial, sans-serif'
    },
    formContainer: {
      backgroundColor: 'white',
      padding: '2rem',
      borderRadius: '8px',
      boxShadow: '0 2px 10px rgba(0, 0, 0, 0.1)',
      width: '100%',
      maxWidth: '400px'
    },
    title: {
      textAlign: 'center',
      color: '#333',
      marginBottom: '1.5rem'
    },
    form: {
      display: 'flex',
      flexDirection: 'column',
      gap: '1rem'
    },
    label: {
      fontSize: '0.9rem',
      color: '#555',
      marginBottom: '-0.5rem'
    },
    input: {
      padding: '0.8rem',
      border: '1px solid #ddd',
      borderRadius: '4px',
      fontSize: '1rem',
      outline: 'none',
      transition: 'border 0.3s',
    },
    inputFocus: {
      border: '1px solid #4a90e2'
    },
    button: {
      padding: '0.8rem',
      backgroundColor: '#4a90e2',
      color: 'white',
      border: 'none',
      borderRadius: '4px',
      fontSize: '1rem',
      cursor: 'pointer',
      transition: 'background-color 0.3s',
      marginTop: '0.5rem'
    },
    buttonHover: {
      backgroundColor: '#357ab8'
    },
    mensajeExito: {
      color: '#28a745',
      marginTop: '1rem',
      textAlign: 'center'
    },
    mensajeError: {
      color: '#dc3545',
      marginTop: '1rem',
      textAlign: 'center'
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.formContainer}>
        <h2 style={styles.title}>Recuperar contraseña</h2>
        <form onSubmit={handleSubmit} style={styles.form}>
          <label htmlFor="email" style={styles.label}>Correo electrónico</label>
          <input
            type="email"
            id="email"
            placeholder="Ingresa tu correo"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            style={styles.input}
          />
          <button type="submit" style={styles.button}>Enviar enlace</button>
        </form>

        {mensaje && <p style={styles.mensajeExito}>{mensaje}</p>}
        {error && <p style={styles.mensajeError}>{error}</p>}
      </div>
    </div>
  );
};

export default ForgotPassword;