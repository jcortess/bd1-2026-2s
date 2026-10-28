
-- LABORATORIO 3 - TALLER RUTA 27 / GRUPO 02
-- 01_esquema.sql | Responsable: Jimena
-- PostgreSQL 17. Ejecutar sobre una BASE DE DATOS VACÍA.
-- Subsistema: recepción, diagnóstico y seguimiento de órdenes.
-- El orden de las tablas respeta las dependencias de claves foráneas.

-- 1. Datos maestros: clientes.
CREATE TABLE cliente (
    cliente_id INTEGER PRIMARY KEY CHECK (cliente_id > 0),
    identificacion VARCHAR(30) NOT NULL UNIQUE
        CHECK (TRIM(identificacion) <> ''),
    nombre_razon_social VARCHAR(150) NOT NULL
        CHECK (TRIM(nombre_razon_social) <> ''),
    tipo_cliente VARCHAR(20) NOT NULL
        CHECK (tipo_cliente IN ('Persona', 'Organización'))
);

-- 2. Datos maestros: vehículos. El VIN es la clave estable (RN-02).
CREATE TABLE vehiculo (
    vin VARCHAR(17) PRIMARY KEY CHECK (CHAR_LENGTH(vin) = 17),
    placa VARCHAR(15) NOT NULL CHECK (TRIM(placa) <> ''),
    marca VARCHAR(60) NOT NULL CHECK (TRIM(marca) <> ''),
    modelo VARCHAR(60) NOT NULL CHECK (TRIM(modelo) <> ''),
    anio INTEGER NOT NULL CHECK (anio BETWEEN 1886 AND 2027),
    tipo_combustible VARCHAR(20) NOT NULL
        CHECK (tipo_combustible IN ('Gasolina', 'Diésel', 'Híbrido', 'Eléctrico', 'Otro'))
);
-- El tope 2027 corresponde al año de realización del caso (2026 + 1).
-- Si se reutiliza el esquema en años futuros, debe revisarse ese límite.

-- 3. Datos maestros: trabajadores del taller.
CREATE TABLE personal (
    personal_id INTEGER PRIMARY KEY CHECK (personal_id > 0),
    nombre VARCHAR(120) NOT NULL CHECK (TRIM(nombre) <> ''),
    rol VARCHAR(20) NOT NULL
        CHECK (rol IN ('Recepción', 'Técnico', 'Otro'))
);

-- 4. Una orden representa una visita concreta de un vehículo (RN-01).
CREATE TABLE orden_trabajo (
    orden_id INTEGER PRIMARY KEY CHECK (orden_id > 0),
    vin VARCHAR(17) NOT NULL REFERENCES vehiculo(vin),
    cliente_factura_id INTEGER NOT NULL REFERENCES cliente(cliente_id),
    entregado_por_cliente_id INTEGER NOT NULL REFERENCES cliente(cliente_id),
    autorizador_cliente_id INTEGER NOT NULL REFERENCES cliente(cliente_id),
    receptor_id INTEGER NOT NULL REFERENCES personal(personal_id),
    fecha_hora_recepcion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    kilometraje_ingreso INTEGER NOT NULL CHECK (kilometraje_ingreso >= 0),
    nivel_combustible VARCHAR(10) NOT NULL
        CHECK (nivel_combustible IN ('Vacío', '1/4', '1/2', '3/4', 'Lleno')),
    motivo_informado TEXT NOT NULL CHECK (TRIM(motivo_informado) <> ''),
    observaciones_visibles TEXT,
    fecha_prometida_actual TIMESTAMP
);

-- 5. Conservar cambios de estado: no sobrescribir estados anteriores (RN-08).
CREATE TABLE historial_orden (
    historial_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orden_id INTEGER NOT NULL REFERENCES orden_trabajo(orden_id),
    estado VARCHAR(35) NOT NULL
        CHECK (estado IN (
            'Recibida', 'En diagnóstico', 'Pendiente autorización',
            'Autorizada', 'En reparación', 'Lista entrega',
            'Entregada', 'Cancelada'
        )),
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    personal_id INTEGER NOT NULL REFERENCES personal(personal_id)
);
-- Se usa IDENTITY en historial_id para generar registros desde procedimientos
-- sin calcular MAX(id)+1 (que podría duplicarse en operaciones concurrentes).

-- 6. Hallazgos técnicos asociados a cada orden (RN-09).
CREATE TABLE hallazgo (
    hallazgo_id INTEGER PRIMARY KEY CHECK (hallazgo_id > 0),
    orden_id INTEGER NOT NULL REFERENCES orden_trabajo(orden_id),
    sintoma_comprobado TEXT NOT NULL CHECK (TRIM(sintoma_comprobado) <> ''),
    posible_causa TEXT,
    urgencia VARCHAR(12) NOT NULL
        CHECK (urgencia IN ('Baja', 'Media', 'Alta', 'Crítica')),
    recomendacion TEXT NOT NULL CHECK (TRIM(recomendacion) <> '')
);

-- Índice complementario útil para obtener el estado MÁS RECIENTE por orden.
-- No duplica el índice creado automáticamente por una clave primaria.
CREATE INDEX idx_historial_orden_ultimo
    ON historial_orden (orden_id, fecha_hora DESC, historial_id DESC);
