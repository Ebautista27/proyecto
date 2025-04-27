import React, { useRef } from "react";
import { Carousel } from "react-bootstrap";
import { Link } from "react-router-dom"; // Importamos Link para la navegación
import "./CustomCarousel.css";

const CustomCarousel = () => {
  const videoRefs = useRef([]);

  const handleVideoPlay = (index) => {
    videoRefs.current.forEach((video, i) => {
      if (i === index) {
        video.play();
      } else {
        video.pause();
        video.currentTime = 0; // Reinicia el video
      }
    });
  };

  const videos = [
    {
      img: "/public/productos/prenda_video.jpeg",
      video: "/Videos/video_principal.mp4",
      alt: "Primera imagen con video",
      ruta: "/Productos/dealle_producto_destacado_chaqueta_azul", // Ruta a la página de detalle
    },
    {
      img: "/public/productos/chaqueta negra carrusel.jpeg",
      video: "/Videos/video_chaqueta_negra_carrusel.mp4",
      alt: "Segunda imagen con video",
      ruta: "/Productos/detalle_producto_destacado_chaqueta_negra", // Ruta a la página de detalle
    },
    {
      img: "/public/productos/camiseta carrusel.jpeg",
      video: "/Videos/video_camiseta_carrusel.mp4",
      alt: "Tercera imagen con video",
      ruta: "/Productos/detalle_producto_destacado_camiseta_azul", // Ruta a la página de detalle
    },
  ];

  return (
    <div className="carousel-container">
      <Carousel
        onSlide={(index) => handleVideoPlay(index)}
        interval={null} // Desactiva el cambio automático
      >
        {videos.map((item, index) => (
          <Carousel.Item key={index}>
            <div className="carousel-slide">
              {/* Imagen con enlace */}
              <div className="carousel-content">
                <Link to={item.ruta}>
                  <img src={item.img} alt={item.alt} className="carousel-image" />
                </Link>
              </div>
              {/* Video */}
              <div className="carousel-content">
                <video
                  ref={(el) => (videoRefs.current[index] = el)}
                  controls
                  className="carousel-video"
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
