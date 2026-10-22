-- ============================================================
-- Laboratorio 3 · grupo-test
-- 01_esquema.sql — Definición del esquema físico (PostgreSQL)
-- Proceso de negocio: registro y despacho de pedidos de una tienda.
-- Versión de PostgreSQL utilizada: 16.x
-- ============================================================
-- Ejecutar sobre una base de datos vacía. No depende de objetos
-- creados manualmente; crea todo lo necesario desde cero.

BEGIN;

CREATE TABLE clientes (
    cliente_id      SERIAL PRIMARY KEY,
    nombre          VARCHAR(80)  NOT NULL,
    correo          VARCHAR(120) NOT NULL UNIQUE,
    creado_en       TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE productos (
    producto_id     SERIAL PRIMARY KEY,
    nombre          VARCHAR(80)     NOT NULL,
    precio          NUMERIC(10,2)   NOT NULL CHECK (precio > 0),
    existencias     INTEGER         NOT NULL DEFAULT 0 CHECK (existencias >= 0)
);

CREATE TABLE pedidos (
    pedido_id       SERIAL PRIMARY KEY,
    cliente_id      INTEGER     NOT NULL REFERENCES clientes(cliente_id),
    estado          VARCHAR(20) NOT NULL DEFAULT 'pendiente'
                        CHECK (estado IN ('pendiente', 'confirmado', 'despachado', 'cancelado')),
    creado_en       TIMESTAMP   NOT NULL DEFAULT now()
);

-- Relación muchos-a-muchos entre pedidos y productos, materializada
-- como tabla de detalle (uno-a-muchos desde pedidos y desde productos).
CREATE TABLE detalle_pedido (
    pedido_id       INTEGER       NOT NULL REFERENCES pedidos(pedido_id)   ON DELETE CASCADE,
    producto_id     INTEGER       NOT NULL REFERENCES productos(producto_id),
    cantidad        INTEGER       NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario > 0),
    PRIMARY KEY (pedido_id, producto_id)
);

-- Índice adicional: las consultas de negocio filtran pedidos por cliente
-- y por estado con frecuencia; la PK de pedidos no cubre ese acceso.
CREATE INDEX idx_pedidos_cliente_estado ON pedidos (cliente_id, estado);

COMMIT;
