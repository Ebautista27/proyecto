import React, { useState } from "react";
import axios from "axios";
import "./Registro.css"; // Asegúrate de que tu archivo CSS esté bien configurado

const Registro = () => {
  // Estado para almacenar los datos del formulario
  const [formData, setFormData] = useState({
    nombre: "",
    email: "",
    password: "",
    direccion: "",
    num_cel: "",
  });

  // Estado para manejar los mensajes de éxito o error
  const [mensaje, setMensaje] = useState("");

  // Maneja los cambios en los campos del formulario
  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  // Maneja el envío del formulario
  const handleSubmit = async (e) => {
    e.preventDefault(); // Previene el comportamiento por defecto (recargar la página)

    try {
      // Enviar los datos al backend utilizando Axios
      const response = await axios.post("http://127.0.0.1:5000/registro", formData);

      // Mostrar mensaje de éxito
      setMensaje(response.data.mensaje || "¡Registro exitoso!");
      // Redirigir a la página de inicio de sesión
      window.location.href = "/iniciarSesion";
    } catch (error) {
      // Manejar errores
      setMensaje(error.response?.data?.mensaje || "Error al registrarse");
    }
  };

  return (
    <div style={{ backgroundColor: "#E5E1DA", minHeight: "100vh", padding: "20px" }}>
      <div className="registro-container">
        <h2>Regístrate</h2>
        <form onSubmit={handleSubmit}>
          <label htmlFor="nombre">Nombre</label>
          <input
            type="text"
            id="nombre"
            name="nombre"
            value={formData.nombre}
            onChange={handleChange}
            placeholder="Ingrese su nombre"
            maxLength="30"
            pattern="[a-zA-Z]+"
            title="Ingresa su nombre"
            required
          />

          <label htmlFor="email">Correo Electrónico</label>
          <input
            type="email"
            id="email"
            name="email"
            value={formData.email}
            onChange={handleChange}
            placeholder="Ingrese su correo"
            maxLength="30"
            pattern="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
            title="Ingresa su correo electrónico"
            required
          />

          <label htmlFor="password">Contraseña</label>
          <input
            type="password"
            id="password"
            name="password"
            value={formData.password}
            onChange={handleChange}
            minLength="10"
            maxLength="20"
            placeholder="Ingrese su contraseña"
            pattern="[A-Za-z0-9]+"
            title="Ingrese una contraseña válida"
            required
          />

          <label htmlFor="direccion">Dirección</label>
          <input
            type="text"
            id="direccion"
            name="direccion"
            value={formData.direccion}
            onChange={handleChange}
            placeholder="Ingrese su dirección"
            maxLength="50"
            pattern="[a-zA-Z0-9\\s,.-#]+"
            title="Ingrese una dirección válida"
            required
          />

          <label htmlFor="num_cel">Número de celular</label>
          <input
            type="text"
            id="num_cel"
            name="num_cel"
            value={formData.num_cel}
            onChange={handleChange}
            maxLength="10"
            placeholder="Ingrese su número de celular"
            pattern="[0-9]*"
            title="Ingrese su número de celular"
            required
          />

          <button type="submit">Registrarse</button>
        </form>

        {/* Mostrar el mensaje de éxito o error */}
        {mensaje && <p>{mensaje}</p>}

        <div className="link_registro">
          <p>
            ¿Ya tienes una cuenta creada? <a href="/iniciarSesion">Inicia Sesión</a>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Registro;
