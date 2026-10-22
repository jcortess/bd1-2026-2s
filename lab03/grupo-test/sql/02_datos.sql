-- ============================================================
-- Laboratorio 3 · grupo-test
-- 02_datos.sql — Carga de datos de prueba
-- ============================================================
-- Datos ficticios, suficientes para observar las relaciones
-- cliente -> pedido -> detalle_pedido <- producto, y para que las
-- consultas y pruebas de 03_consultas.sql y 05_pruebas.sql tengan
-- resultados distintos entre sí.

BEGIN;

INSERT INTO clientes (nombre, correo) VALUES
    ('Ana Rojas',    'ana.rojas@example.com'),
    ('Luis Mora',    'luis.mora@example.com'),
    ('Carla Vega',   'carla.vega@example.com');

INSERT INTO productos (nombre, precio, existencias) VALUES
    ('Teclado mecánico', 35.00, 20),
    ('Mouse óptico',      12.50, 50),
    ('Monitor 24"',      150.00,  8),
    ('Audífonos USB',     18.00,  0);  -- sin existencias, para probar rechazo

INSERT INTO pedidos (cliente_id, estado) VALUES
    (1, 'despachado'),
    (1, 'pendiente'),
    (2, 'confirmado'),
    (3, 'cancelado');

INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
    (1, 1, 1, 35.00),
    (1, 2, 2, 12.50),
    (2, 3, 1, 150.00),
    (3, 2, 3, 12.50),
    (4, 4, 1, 18.00);


COMMIT;
