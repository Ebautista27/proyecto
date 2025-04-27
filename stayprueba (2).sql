-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 27-04-2025 a las 16:10:34
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `stayprueba`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alembic_version`
--

CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `alembic_version`
--

INSERT INTO `alembic_version` (`version_num`) VALUES
('693b01f1fd03');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `carritos`
--

CREATE TABLE `carritos` (
  `id` int(11) NOT NULL,
  `total` float DEFAULT NULL,
  `estado` varchar(20) DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `carrito_productos`
--

CREATE TABLE `carrito_productos` (
  `id` int(11) NOT NULL,
  `id_carrito` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `subtotal` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id`, `nombre`) VALUES
(1, 'chaqueta'),
(2, 'camisa vintage'),
(3, 'jjj');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id` int(11) NOT NULL,
  `barrio` varchar(100) NOT NULL,
  `observaciones` text DEFAULT NULL,
  `fecha_compra` datetime DEFAULT NULL,
  `usuario_id` int(11) NOT NULL,
  `metodo_pago_id` int(11) NOT NULL,
  `estado_pedido` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `compras`
--

INSERT INTO `compras` (`id`, `barrio`, `observaciones`, `fecha_compra`, `usuario_id`, `metodo_pago_id`, `estado_pedido`) VALUES
(3, 'Usmequistan', 'porfavor que llegue bien:c', '2025-04-23 15:05:23', 2, 1, 'Enviado'),
(5, 'se', 'sees', '2025-04-23 15:13:08', 1, 1, NULL),
(6, 'Chapinero', 'Entrega rápida', '2025-04-23 16:12:49', 1, 1, 'Procesado'),
(7, 'el huebo mio', 'sdasdsssssssssssssssssssssssssaaaaaaaaaaaa', '2025-04-23 22:34:06', 1, 1, 'Procesado'),
(9, 'el diablo', 'asdddddddddddasssssss', '2025-04-23 22:36:25', 1, 1, 'Procesado'),
(10, 'el diablo', 'eeeeee', '2025-04-23 22:39:22', 1, 1, 'Procesado'),
(11, 'el diablo', '2333333333334', '2025-04-23 22:46:20', 1, 1, 'Procesado'),
(12, 'el diablo', 'el diablo', '2025-04-23 22:49:47', 1, 1, 'Procesado'),
(14, 'el diablo', '3423432', '2025-04-23 22:58:49', 1, 1, 'Procesado'),
(15, 'el diablo', 'ererwer', '2025-04-23 23:03:52', 1, 1, 'Procesado'),
(16, 'usme', 'dilan', '2025-04-23 23:09:49', 1, 1, 'Procesado'),
(17, 'usme', 'sisi', '2025-04-23 23:12:13', 1, 1, 'Procesado');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compra_producto`
--

CREATE TABLE `compra_producto` (
  `compra_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `precio_unitario` float NOT NULL,
  `cantidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_facturas`
--

CREATE TABLE `detalle_facturas` (
  `id` int(11) NOT NULL,
  `id_factura` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `facturas`
--

CREATE TABLE `facturas` (
  `id` int(11) NOT NULL,
  `id_pedido` int(11) DEFAULT NULL,
  `monto_total` float NOT NULL,
  `fecha_emision` datetime DEFAULT NULL,
  `estado` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `metodos_pago`
--

CREATE TABLE `metodos_pago` (
  `id` int(11) NOT NULL,
  `tipo` varchar(50) NOT NULL,
  `detalle` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `metodos_pago`
--

INSERT INTO `metodos_pago` (`id`, `tipo`, `detalle`) VALUES
(1, 'nequi', 'nequi');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id` int(11) NOT NULL,
  `fecha_pedido` date DEFAULT NULL,
  `estado_pedido` varchar(50) DEFAULT NULL,
  `total_pedido` float NOT NULL,
  `direccion_envio` varchar(100) NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `id_metodo_pago` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pedidos`
--

INSERT INTO `pedidos` (`id`, `fecha_pedido`, `estado_pedido`, `total_pedido`, `direccion_envio`, `id_usuario`, `id_metodo_pago`) VALUES
(1, '2025-04-10', 'Procesado', 1, 'asdads', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `precio` float NOT NULL,
  `estado` varchar(10) DEFAULT NULL,
  `id_categoria` int(11) DEFAULT NULL,
  `imagen` varchar(255) DEFAULT NULL,
  `meta_data` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id`, `nombre`, `descripcion`, `precio`, `estado`, `id_categoria`, `imagen`, `meta_data`) VALUES
(1, 'Chaqueta Negra', 'esta linda', 30000, 'Disponible', 1, NULL, NULL),
(2, 'camisa vintage', 'camisa vintage', 10000, 'activo', 2, NULL, NULL),
(4, 'Camisa Hombre 1', 'Camisa para hombre estilo casual de alta calidad', 29.99, 'Disponible', 1, '/assets/Imagenes/Camisa_H_1.jpg', NULL),
(5, 'Camisa Hombre 1', 'Camisa casual para hombre, algodón respirable', 29.99, 'Disponible', 1, '/productos/camisa_H_1.jpg', NULL),
(6, 'Camisa Hombre 2', 'Camisa formal clásica, ideal para oficina', 34.99, 'Disponible', 1, '/productos/Camisa_H_2.jpg', NULL),
(7, 'Camisa Hombre 3', 'Camisa manga larga, diseño moderno', 27.99, 'Disponible', 1, '/productos/Camisa_H_3.jpg', NULL),
(8, 'Camisa Hombre 4', 'Camisa estampada, estilo urbano', 25.99, 'Disponible', 1, '/productos/Camisa_H_4.jpg', NULL),
(9, 'Camisa Hombre 5', 'Camisa slim fit, ajuste premium', 32.99, 'Disponible', 1, '/productos/Camisa_H_5.jpg', NULL),
(10, 'Camisa Hombre 6', 'Camisa básica, múltiples colores', 22.99, 'Disponible', 1, '/productos/Camisa_H_6.jpg', NULL),
(11, 'Camisa Hombre 7', 'Camisa tejido resistente, durabilidad', 26.99, 'Disponible', 1, '/productos/Camisa_h_7.jpg', NULL),
(12, 'Camisa Mujer 1', 'Blusa elegante, corte femenino', 28.99, 'Disponible', 2, '/productos/Camisa_M_1.jpg', NULL),
(13, 'Camisa Mujer 2', 'Blusa de manga larga, estilo profesional', 33.99, 'Disponible', 2, '/productos/Camisa_M_2.jpg', NULL),
(14, 'Camisa Mujer 3', 'Blusa estampada, vibra bohemia', 26.99, 'Disponible', 2, '/productos/Camisa_M_3.jpg', NULL),
(15, 'Camisa Mujer 4', 'Blusa básica, comodidad garantizada', 30.99, 'Disponible', 2, '/productos/Camisa_M_4.jpg', NULL),
(16, 'Chaqueta Japón', 'Inspirada en moda Harajuku, edición limitada', 59.99, 'Disponible', 1, '/productos/chaqueta japon.jpeg', NULL),
(17, 'Chaqueta Cargo', 'Chaqueta utilitaria con bolsillos tácticos', 49.99, 'Disponible', 1, '/productos/chaqueta cargo.610.jpg', NULL),
(18, 'Chaqueta Ovejera', 'Abrigo acolchado, ideal para invierno', 65.99, 'Disponible', 2, '/productos/chaqueta_ovejera_blanca.jpeg', NULL),
(19, 'Chaqueta Kidway Plus Size', 'Jacket oversize con capucha y contrastes', 69.99, 'Disponible', 1, '/productos/Kidway Plus Size Men’s Elegant Contrast Color Hooded Jacket For Spring_autumn, Oversized Loose Fit Jacket Fo...', NULL),
(20, 'Pantalón Mujer 1', 'Pantalón slim fit, tela elástica', 39.99, 'Disponible', 3, '/productos/pantalon_M_1.jpeg', NULL),
(21, 'Pantalón Mujer 2', 'Pantalón de vestir, corte recto', 44.99, 'Disponible', 3, '/productos/Pantalon_M_2.jpg', NULL),
(22, 'Pantalón Mujer 3', 'Pantalón cargo, estilo militar', 47.99, 'Disponible', 3, '/productos/Pantalon_M_3.jpg', NULL),
(23, 'Pantalón Mujer 4', 'Pantalón wide leg, tendencia 2024', 42.99, 'Disponible', 3, '/productos/Pantalon_M_4.jpg', NULL),
(24, 'Pantalón Mujer 5', 'Pantalón jeans rotos, diseño vintage', 37.99, 'Disponible', 3, '/productos/Pantalon_M_5.jpg', NULL),
(25, 'Camiseta AE', 'Diseño gráfico exclusivo, colección urbana', 19.99, 'Disponible', 1, '/productos/camiseta ae.jpeg', NULL),
(26, 'Camiseta BBS', 'Estilo streetwear, oversized', 24.99, 'Disponible', 1, '/productos/camiseta bbs.jpeg', NULL),
(27, 'Camiseta Choize', 'Marca premium, algodón orgánico', 29.99, 'Disponible', 1, '/productos/camiseta choize.jpeg', NULL),
(28, 'Camiseta Gris BBS', 'Versión en gris, unisex', 22.99, 'Disponible', 1, '/productos/camiseta gris bbs.jpeg', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reseñas`
--

CREATE TABLE `reseñas` (
  `id` int(11) NOT NULL,
  `comentario` varchar(150) NOT NULL,
  `calificacion` int(11) NOT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `reseñas`
--

INSERT INTO `reseñas` (`id`, `comentario`, `calificacion`, `id_producto`, `id_usuario`) VALUES
(7, '332434', 5, 6, 2),
(14, 'ghgbh', 5, 7, 2),
(15, 'esta bien bonito', 5, 17, 2),
(17, 'jpjoijjj', 4, 17, 2),
(18, 'asddsaads', 3, 17, 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id`, `nombre`) VALUES
(1, 'Administrador'),
(2, 'Usuario');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tallas`
--

CREATE TABLE `tallas` (
  `id` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `categoria_talla` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `num_cel` varchar(50) DEFAULT NULL,
  `direccion` varchar(100) DEFAULT NULL,
  `contrasena_hash` varchar(255) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `estado` varchar(20) DEFAULT NULL,
  `reset_token` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `nombre`, `email`, `num_cel`, `direccion`, `contrasena_hash`, `id_rol`, `estado`, `reset_token`) VALUES
(1, 'Super Admin', 'superadmin@example.com', '3170000000', 'Calle Ficticia 123', 'pbkdf2:sha256:600000$sh5ID6d7MRDr87YE$f1bce04bc1fe6388ba5181f1be880cf68527f1a2a0bd73f1a98374edf4599fe2', 1, 'Activo', NULL),
(2, 'anderson', 'ande27e@gmail.com', '3656465', 'asdkksaddas', 'pbkdf2:sha256:600000$1hdciFa4Lkt3M36T$cec0e1b3335b37880e3e1247186905ed5109a8c82e6c578ba98743f2af26e249', 2, 'Activo', NULL),
(3, 'DilandakRg', 'dilandakrg@gmail.com', '317751000', 'asdkksadkdas', 'pbkdf2:sha256:600000$WPNUMZ6Yo2bHtIKO$112f3b118f39e18bb35d182fad258096fad9a1cbd39f1b64e2c6ed10ccc70640', 2, 'Activo', NULL),
(4, '2321344eeddd', 'e@gmail.com', '2323232324', 'calle 109 sur 23 4', 'pbkdf2:sha256:600000$0Ba0fQSmUGKIdiMS$1d4266a057fc8cce50ed593a69edd94d9c4773e80d0f04849aa606ea63f78ffc', 1, 'Activo', NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `alembic_version`
--
ALTER TABLE `alembic_version`
  ADD PRIMARY KEY (`version_num`);

--
-- Indices de la tabla `carritos`
--
ALTER TABLE `carritos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `carrito_productos`
--
ALTER TABLE `carrito_productos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_carrito` (`id_carrito`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`),
  ADD KEY `metodo_pago_id` (`metodo_pago_id`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `compra_producto`
--
ALTER TABLE `compra_producto`
  ADD PRIMARY KEY (`compra_id`,`producto_id`),
  ADD KEY `producto_id` (`producto_id`);

--
-- Indices de la tabla `detalle_facturas`
--
ALTER TABLE `detalle_facturas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_factura` (`id_factura`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `facturas`
--
ALTER TABLE `facturas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_pedido` (`id_pedido`);

--
-- Indices de la tabla `metodos_pago`
--
ALTER TABLE `metodos_pago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_metodo_pago` (`id_metodo_pago`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_categoria` (`id_categoria`);

--
-- Indices de la tabla `reseñas`
--
ALTER TABLE `reseñas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_producto` (`id_producto`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `tallas`
--
ALTER TABLE `tallas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `id_rol` (`id_rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `carritos`
--
ALTER TABLE `carritos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `carrito_productos`
--
ALTER TABLE `carrito_productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT de la tabla `detalle_facturas`
--
ALTER TABLE `detalle_facturas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `facturas`
--
ALTER TABLE `facturas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `metodos_pago`
--
ALTER TABLE `metodos_pago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT de la tabla `reseñas`
--
ALTER TABLE `reseñas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `tallas`
--
ALTER TABLE `tallas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `carritos`
--
ALTER TABLE `carritos`
  ADD CONSTRAINT `carritos_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `carrito_productos`
--
ALTER TABLE `carrito_productos`
  ADD CONSTRAINT `carrito_productos_ibfk_1` FOREIGN KEY (`id_carrito`) REFERENCES `carritos` (`id`),
  ADD CONSTRAINT `carrito_productos_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id`);

--
-- Filtros para la tabla `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `compras_ibfk_1` FOREIGN KEY (`metodo_pago_id`) REFERENCES `metodos_pago` (`id`),
  ADD CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `compra_producto`
--
ALTER TABLE `compra_producto`
  ADD CONSTRAINT `compra_producto_ibfk_1` FOREIGN KEY (`compra_id`) REFERENCES `compras` (`id`),
  ADD CONSTRAINT `compra_producto_ibfk_2` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`);

--
-- Filtros para la tabla `detalle_facturas`
--
ALTER TABLE `detalle_facturas`
  ADD CONSTRAINT `detalle_facturas_ibfk_1` FOREIGN KEY (`id_factura`) REFERENCES `facturas` (`id`),
  ADD CONSTRAINT `detalle_facturas_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id`);

--
-- Filtros para la tabla `facturas`
--
ALTER TABLE `facturas`
  ADD CONSTRAINT `facturas_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id`);

--
-- Filtros para la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_metodo_pago`) REFERENCES `metodos_pago` (`id`),
  ADD CONSTRAINT `pedidos_ibfk_2` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `productos_ibfk_1` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id`);

--
-- Filtros para la tabla `reseñas`
--
ALTER TABLE `reseñas`
  ADD CONSTRAINT `reseñas_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id`),
  ADD CONSTRAINT `reseñas_ibfk_2` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
