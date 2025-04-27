import React, { useState } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import "./IniciarSesion.css";

const IniciarSesion = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    if (name === "email") setEmail(value);
    if (name === "password") setPassword(value);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!email || !password) {
      setMensaje("Por favor completa todos los campos");
      return;
    }
  
    setLoading(true);
  
    try {
      const response = await axios.post("http://127.0.0.1:5000/login", {
        email,
        password,
      });
  
      const { token, usuario } = response.data;
  
      // Guardar todo en localStorage
      localStorage.setItem("token", token);
      localStorage.setItem("id_usuario", usuario.id);
      localStorage.setItem("nombre_usuario", usuario.nombre);
      localStorage.setItem("email_usuario", usuario.email);
      localStorage.setItem("direccion_usuario", usuario.direccion);
  
      // Mensaje y navegación
      if (email === "superadmin@example.com" && password === "superadmin123") {
        setMensaje("¡Inicio de sesión exitoso como administrador!");
        navigate("/Administrador");
      } else {
        setMensaje("¡Inicio de sesión exitoso!");
        navigate("/");
      }
  
    } catch (error) {
      setMensaje(
        error.response?.data?.mensaje || 
        "Error al iniciar sesión. Verifica tus credenciales."
      );
    } finally {
      setLoading(false);
    }
  };
  

  return (
    <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
    <div className="auth-page-container">
      <div className="auth-container">
        <h2>Inicia Sesión</h2>
        <form onSubmit={handleSubmit} className="auth-form">
          <div className="form-group">
            <label htmlFor="email">Correo Electrónico</label>
            <input
              type="email"
              id="email"
              name="email"
              value={email}
              onChange={handleChange}
              placeholder="Ingresa tu correo"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="password">Contraseña</label>
            <input
              type={showPassword ? "text" : "password"}
              id="password"
              name="password"
              value={password}
              onChange={handleChange}
              placeholder="Ingresa tu contraseña"
              required
            />
          </div>

            {/* Mostrar Contraseña */}
            <div className="show-password">
            <input
              type="checkbox"
              id="showPassword"
              onChange={togglePasswordVisibility}
            />
            <label htmlFor="showPassword">Mostrar contraseña</label>
          </div>

          <button 
            type="submit" 
            className="auth-button"
            disabled={loading}
          >
            {loading ? (
              <>
                <span className="spinner"></span> Iniciando sesión...
              </>
            ) : "Iniciar Sesión"}
          </button>
        </form>

        {mensaje && (
          <div className={`auth-message ${mensaje.includes("éxito") ? "success" : ""}`}>
            {mensaje}
          </div>
        )}

        <div className="auth-links">
          <a href="/ForgotPassword">¿Olvidaste tu contraseña?</a>
          <p>¿No tienes cuenta? <a href="/registro">Regístrate</a></p>
        </div>
      </div>
    </div>
    </div>
  );
};

export default IniciarSesion;