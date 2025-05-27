import React, { useRef, useState, useEffect } from "react";
import { Carousel } from "react-bootstrap";
import { Link } from "react-router-dom";
import axios from "axios";
import "./CustomCarousel.css";

const CustomCarousel = () => {
  const videoRefs = useRef([]);
  const [productos, setProductos] = useState([]);
  const [loading, setLoading] = useState(true);

  // Función para obtener la URL correcta de la imagen
  const getImageUrl = (imagenUrl) => {
    if (!imagenUrl) return '/public/productos/default.jpg';
    
    // Si ya es una URL completa de Cloudinary
    if (imagenUrl.includes('res.cloudinary.com')) {
      return imagenUrl;
    }
    
    // Si es solo el public_id (sin URL completa)
    if (!imagenUrl.startsWith('http')) {
      return `https://res.cloudinary.com/dodecmh9s/image/upload/${imagenUrl}`;
    }
    
    return imagenUrl;
  };

  useEffect(() => {
    const cargarProductosDestacados = async () => {
      try {
        const ids = [21, 22, 23]; // IDs de los productos destacados
        const responses = await Promise.all(
          ids.map(id => axios.get(`http://127.0.0.1:5000/productos/${id}`))
        );
        
        // Procesamos los productos para asegurar las URLs de imágenes
        const productosProcesados = responses.map(res => ({
          ...res.data,
          imagen_url: getImageUrl(res.data.imagen_url)
        }));
        
        setProductos(productosProcesados);
      } catch (error) {
        console.error("Error al cargar productos destacados:", error);
      } finally {
        setLoading(false);
      }
    };

    cargarProductosDestacados();
  }, []);

  const handleVideoPlay = (index) => {
    videoRefs.current.forEach((video, i) => {
      if (i === index) {
        video.play();
      } else {
        video.pause();
        video.currentTime = 0;
      }
    });
  };

  if (loading) {
    return <div className="loading-carousel">Cargando productos destacados...</div>;
  }

  const videos = [
    {
      img: productos[0]?.imagen_url || "/public/productos/default.jpg",
      video: "/Videos/video_principal.mp4",
      alt: productos[0]?.nombre || "Chaqueta Azul Nike x NOCTA",
      ruta: `/productos/21`,
    },
    {
      img: productos[1]?.imagen_url || "/public/productos/default.jpg",
      video: "/Videos/video_chaqueta_negra_carrusel.mp4",
      alt: productos[1]?.nombre || "Black Fleece Jacket 2.0 Trendt Vision",
      ruta: `/productos/22`,
    },
    {
      img: productos[2]?.imagen_url || "/public/productos/default.jpg",
      video: "/Videos/video_camiseta_carrusel.mp4",
      alt: productos[2]?.nombre || "TIDAL BLUE Paneled Oversized Jersey",
      ruta: `/productos/23`,
    },
  ];

  return (
    <div className="carousel-container">
      <Carousel onSlide={(index) => handleVideoPlay(index)} interval={null}>
        {videos.map((item, index) => (
          <Carousel.Item key={index}>
            <div className="carousel-slide">
              {/* Imagen con enlace */}
              <div className="carousel-content">
                <Link to={item.ruta}>
                  <img 
                    src={item.img} 
                    alt={item.alt} 
                    className="carousel-image"
                    onError={(e) => {
                      e.target.src = '/public/productos/default.jpg';
                      console.error('Error cargando imagen del carrusel:', item.img);
                    }}
                  />
                </Link>
              </div>
              {/* Video */}
              <div className="carousel-content">
                <video
                  ref={(el) => (videoRefs.current[index] = el)}
                  controls
                  className="carousel-video"
                  muted // Añadido muted para que los videos puedan autoplay en algunos navegadores
                >
                  <source src={item.video} type="video/mp4" />
                  Tu navegador no soporta este video.
                </video>
              </div>
            </div>
          </Carousel.Item>
        ))}
      </Carousel>
    </div>
  );
};

export default CustomCarousel;