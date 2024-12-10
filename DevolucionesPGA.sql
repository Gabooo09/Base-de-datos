/*
El procedimiento procesar_devolucion_venta realiza varias tareas críticas para garantizar la integridad de las transacciones.
Primero, verifica la existencia del cliente y del producto involucrado en la devolución, evitando errores que puedan surgir de datos incorrectos.
Luego, registra la devolución en la base de datos, incluyendo detalles como la cantidad devuelta y el motivo de la devolución. 
Adicionalmente, el código actualiza el inventario, incrementando la cantidad disponible de los productos devueltos y manteniendo un historial de todos los cambios.
Finalmente, ajusta el detalle de ventas para reflejar la devolución, asegurando que los registros de ventas sean precisos.
Este procedimiento no solo mejora la eficiencia en la gestión de devoluciones, sino que también fortalece la confianza de los clientes al saber que sus devoluciones 
son manejadas de manera profesional y precisa. 
Implementar una solución como esta es esencial para mantener la integridad del sistema de inventario y proporcionar 
una experiencia de usuario positiva en la plataforma de comercio electrónico de "El Corcho".
*/
CREATE OR REPLACE FUNCTION actualizar_inventario(
    _id_producto INT,
    _cantidad INT
) 
RETURNS VOID
AS 
$$
BEGIN
    -- Validar existencia del producto
    IF EXISTS (SELECT 1 FROM productos WHERE id_producto = _id_producto) THEN
        -- Actualizar el inventario
        UPDATE inventarios
        SET cantidad_disponible = cantidad_disponible + _cantidad,
            fecha_actualizacion = CURRENT_DATE
        WHERE id_producto = _id_producto;

        -- Registrar en el historial de inventario
        INSERT INTO historial_inventario (id_producto, cantidad_cambiada, fecha_cambio)
        VALUES (_id_producto, _cantidad, CURRENT_DATE);
    ELSE
        RAISE NOTICE 'No existe el producto con ID: %', _id_producto;
    END IF;
END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE PROCEDURE procesar_devolucion_venta(
    _cliente_id INT,
    _venta_id INT,
    _producto_id INT,
    _cantidad INT,
    _motivo VARCHAR(255)
)
AS
$$
BEGIN
    -- Verificar si el cliente existe
    IF EXISTS (SELECT 1 FROM clientes WHERE id_cliente = _cliente_id) THEN
        -- Verificar si el producto existe
        IF EXISTS (SELECT 1 FROM productos WHERE id_producto = _producto_id) THEN
            -- Insertar el registro de devolución
            INSERT INTO devoluciones_ventas (id_venta, id_producto, cantidad, motivo_devolucion, fecha_devolucion)
            VALUES (_venta_id, _producto_id, _cantidad, _motivo, CURRENT_DATE);

            -- Actualizar el inventario
            PERFORM actualizar_inventario(_producto_id, _cantidad);
            
            -- Actualizar el detalle de ventas 
            UPDATE detalle_ventas
            SET cantidad = cantidad - _cantidad
            WHERE id_venta = _venta_id AND id_producto = _producto_id;

        ELSE
            RAISE NOTICE 'No existe el producto con ID: %', _producto_id;
        END IF;
    ELSE
        RAISE NOTICE 'No existe el cliente con ID: %', _cliente_id;
    END IF;
END;
$$ 
LANGUAGE plpgsql;


CALL procesar_devolucion_venta(
    5,      -- _cliente_id: ID del cliente que realiza la devolución
    5,      -- _venta_id: ID de la venta original
    9,      -- _producto_id: ID del producto que se está devolviendo
    700000,      -- _cantidad: Cantidad de productos que se están devolviendo
    'Defectuoso'  -- _motivo: Motivo de la devolución
);


select * from historial_inventario;
select * from inventarios;
select * from devoluciones_ventas;
select * from detalle_ventas;


CREATE TABLE historial_inventario (
    id_historial SERIAL PRIMARY KEY,
    id_producto INT NOT NULL,
    cantidad_cambiada INT NOT NULL,
    fecha_cambio DATE NOT NULL,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);