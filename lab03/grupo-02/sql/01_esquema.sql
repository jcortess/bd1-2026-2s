
-- LABORATORIO 3 - TALLER RUTA 27
-- Creación de las tablas

-- Tabla 1: CLIENTE

CREATE TABLE cliente (
    cliente_id INTEGER PRIMARY KEY
        CHECK (cliente_id > 0),

    identificacion VARCHAR(30) NOT NULL UNIQUE
        CHECK (TRIM(identificacion) <> ''),

    nombre_razon_social VARCHAR(150) NOT NULL
        CHECK (TRIM(nombre_razon_social) <> ''),

    tipo_cliente VARCHAR(20) NOT NULL
        CHECK (tipo_cliente IN ('Persona', 'Organización'))
);
