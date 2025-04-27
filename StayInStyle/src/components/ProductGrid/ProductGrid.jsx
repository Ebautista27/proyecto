import React from 'react';

const ProductGrid = () => {
    const productos = [
        { nombre: 'Chaqueta cargo 610', precio: '110.000 mil pesos', img: '/public/imagenes/chaqueta_cargo_610.jpg' },
        { nombre: 'Chaqueta ovejera blanca', precio: '105.000 mil pesos', img: '/public/imagenes/chaqueta_ovejera_blanca.jpeg' },
        { nombre: 'Camiseta Choize', precio: '90.000 mil pesos', img: '/public/imagenes/camiseta choize.jpeg' },
        { nombre: 'Camisa boxy fit', precio: '100.000 mil pesos', img: '/public/imagenes/camiseta bbs.jpeg' },
    ];

    return (
        <section className="vitrina">
            {productos.map((producto, index) => (
                <div className="producto" key={index}>
                    <a href="/detalle-producto">
                        <img src={producto.img} alt={producto.nombre} />
                    </a>
                    <h3>{producto.nombre}</h3>
                    <p>Precio: {producto.precio}</p>
                </div>
            ))}
        </section>
    );
};

export default ProductGrid;
