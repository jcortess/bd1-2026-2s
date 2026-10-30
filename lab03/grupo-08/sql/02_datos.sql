-- =====================================================================
-- 02_datos.sql
-- Datos ficticios para el proceso: registro de clientes y solicitudes
-- Requiere haber ejecutado 01_esquema.sql sobre una base vacía.
-- Todos los datos son inventados (no corresponden a personas reales).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CLIENTES (6): 2 tipos de cliente, 3 condiciones, 4 tipos de id
-- ---------------------------------------------------------------------
INSERT INTO cliente (tipo_id, numero_id, nombre_razon_social, tipo_cliente, condicion_contractual)
VALUES
    ('CEDULA_FISICA',   '1-1111-1111',  'María Fernández Solano',  'PERSONA_FISICA',   'CONTRATO_ESTANDAR'),
    ('CEDULA_FISICA',   '2-2222-2222',  'Carlos Jiménez Rojas',    'PERSONA_FISICA',   'SIN_CONTRATO'),
    ('CEDULA_JURIDICA', '3-101-111111', 'Distribuidora Tica S.A.', 'PERSONA_JURIDICA', 'CONTRATO_CORPORATIVO'),
    ('CEDULA_JURIDICA', '3-102-222222', 'Café Montaña S.R.L.',     'PERSONA_JURIDICA', 'CONTRATO_ESTANDAR'),
    ('DIMEX',           '155800000001', 'Ana Lucía Pérez Gómez',   'PERSONA_FISICA',   'SIN_CONTRATO'),
    ('PASAPORTE',       'X1234567',     'John Smith',              'PERSONA_FISICA',   'SIN_CONTRATO');

-- ---------------------------------------------------------------------
-- 2. MEDIOS DE CONTACTO DE CLIENTE
--    Cliente 1: varios medios (2 teléfonos + correo)
--    Cliente 5 y 6: ninguno
-- ---------------------------------------------------------------------
INSERT INTO medio_contacto_cliente (tipo_id, numero_id, tipo_medio, valor)
VALUES
    ('CEDULA_FISICA',   '1-1111-1111',  'TELEFONO', '2441-0001'),
    ('CEDULA_FISICA',   '1-1111-1111',  'TELEFONO', '8888-0001'),
    ('CEDULA_FISICA',   '1-1111-1111',  'CORREO',   'maria.fernandez@ejemplo.com'),
    ('CEDULA_FISICA',   '2-2222-2222',  'WHATSAPP', '8888-0002'),
    ('CEDULA_JURIDICA', '3-101-111111', 'CORREO',   'info@distribuidoratica.example'),
    ('CEDULA_JURIDICA', '3-101-111111', 'TELEFONO', '2222-0003'),
    ('CEDULA_JURIDICA', '3-102-222222', 'WHATSAPP', '8888-0004');

-- ---------------------------------------------------------------------
-- 3. DIRECCIONES HABITUALES (num_direccion es consecutivo por cliente)
--    Cliente 1: tres (una inactiva) | Cliente 3: dos | Cliente 4: una
--    Clientes 2, 5 y 6: ninguna (participación parcial 0..N)
-- ---------------------------------------------------------------------
INSERT INTO direccion_habitual
    (tipo_id, numero_id, num_direccion, provincia, canton, distrito,
     otras_senas, instrucciones_acceso, referencia_geografica, activa)
VALUES
    ('CEDULA_FISICA',   '1-1111-1111',  1, 'ALAJUELA', 'Alajuela', 'San José',
     '100 m norte de la iglesia', 'Tocar el timbre dos veces', NULL, TRUE),
    ('CEDULA_FISICA',   '1-1111-1111',  2, 'SAN_JOSE', 'Escazú',   'San Rafael',
     'Edificio azul, apartamento 4', NULL, 'Frente al parque', TRUE),
    ('CEDULA_FISICA',   '1-1111-1111',  3, 'HEREDIA',  'Heredia',  'Mercedes',
     'Casa esquinera de portón verde', NULL, NULL, FALSE),
    ('CEDULA_JURIDICA', '3-101-111111', 1, 'SAN_JOSE', 'San José', 'Pavas',
     'Bodega 12, zona industrial', 'Presentarse en la garita con cédula', 'Contiguo a la gasolinera', TRUE),
    ('CEDULA_JURIDICA', '3-101-111111', 2, 'CARTAGO',  'Cartago',  'Oriental',
     '200 m sur de la basílica', NULL, NULL, TRUE),
    ('CEDULA_JURIDICA', '3-102-222222', 1, 'ALAJUELA', 'San Ramón', 'Central',
     'Local comercial 3', NULL, 'Costado oeste del mercado', TRUE);

-- ---------------------------------------------------------------------
-- 4. CONTACTOS (id_contacto lo genera PostgreSQL)
--    Cliente 3: dos contactos | Cliente 4: uno | Cliente 1: uno
-- ---------------------------------------------------------------------
INSERT INTO contacto (tipo_id, numero_id, nombre)
VALUES
    ('CEDULA_JURIDICA', '3-101-111111', 'Laura Mora Campos'),
    ('CEDULA_JURIDICA', '3-101-111111', 'Pedro Vargas Soto'),
    ('CEDULA_JURIDICA', '3-102-222222', 'Sofía Araya León'),
    ('CEDULA_JURIDICA', '3-102-222222', 'Rosa Solano Díaz');

-- Facultades: un contacto con dos, otros con una
INSERT INTO facultad_contacto (id_contacto, facultad)
SELECT c.id_contacto, v.facultad
FROM (VALUES
        ('Laura Mora Campos', 'SOLICITAR_SERVICIOS'),
        ('Laura Mora Campos', 'AUTORIZAR_CARGOS'),
        ('Pedro Vargas Soto', 'RECIBIR_REPORTES'),
        ('Sofía Araya León',  'SOLICITAR_SERVICIOS'),
        ('Sofía Araya León',  'RECIBIR_REPORTES'),
        ('Rosa Solano Díaz',  'RECIBIR_REPORTES')
     ) AS v(nombre, facultad)
JOIN contacto c ON c.nombre = v.nombre;

-- Medios de contacto de cada contacto
INSERT INTO medio_contacto_contacto (id_contacto, tipo_medio, valor)
SELECT c.id_contacto, v.tipo_medio, v.valor
FROM (VALUES
        ('Laura Mora Campos', 'CORREO',   'laura.mora@distribuidoratica.example'),
        ('Laura Mora Campos', 'TELEFONO', '8888-0005'),
        ('Pedro Vargas Soto', 'TELEFONO', '8888-0006'),
        ('Sofía Araya León',  'WHATSAPP', '8888-0007'),
        ('Rosa Solano Díaz',  'TELEFONO', '8888-0008')
     ) AS v(nombre, tipo_medio, valor)
JOIN contacto c ON c.nombre = v.nombre;

-- ---------------------------------------------------------------------
-- 5. SOLICITUDES (id_solicitud lo genera PostgreSQL)
--    Cliente 3: tres | Cliente 1: dos | Clientes 2 y 4: una
--    Clientes 5 y 6: ninguna. Una solicitud sin observaciones (NULL).
-- ---------------------------------------------------------------------
INSERT INTO solicitud
    (tipo_id, numero_id, fecha,
     lugar_recoleccion_provincia, lugar_recoleccion_canton,
     lugar_recoleccion_distrito, lugar_recoleccion_otras_senas,
     periodo_previsto_inicio, periodo_previsto_fin,
     destino, nivel_servicio, observaciones)
VALUES
    ('CEDULA_FISICA', '1-1111-1111', '2026-10-01',
     'ALAJUELA', 'Alajuela', 'San José', '100 m norte de la iglesia',
     '2026-10-02 08:00-06', '2026-10-02 12:00-06',
     'Liberia, Guanacaste, barrio La Victoria', 'ESTANDAR', 'Paquete frágil'),
    ('CEDULA_FISICA', '1-1111-1111', '2026-10-15',
     'SAN_JOSE', 'Escazú', 'San Rafael', 'Edificio azul, apartamento 4',
     '2026-10-16 09:00-06', '2026-10-16 11:00-06',
     'Cartago centro, frente a la basílica', 'EXPRESS', NULL),
    ('CEDULA_FISICA', '2-2222-2222', '2026-10-05',
     'HEREDIA', 'Heredia', 'Mercedes', 'Casa esquinera de portón verde',
     '2026-10-06 14:00-06', '2026-10-06 18:00-06',
     'Puntarenas centro, muelle', 'ECONOMICO', 'Sin observaciones adicionales'),
    ('CEDULA_JURIDICA', '3-101-111111', '2026-09-20',
     'SAN_JOSE', 'San José', 'Pavas', 'Bodega 12, zona industrial',
     '2026-09-21 07:00-06', '2026-09-21 17:00-06',
     'Limón centro, bodega portuaria', 'ECONOMICO', 'Carga de 40 cajas'),
    ('CEDULA_JURIDICA', '3-101-111111', '2026-10-10',
     'SAN_JOSE', 'San José', 'Pavas', 'Bodega 12, zona industrial',
     '2026-10-11 07:00-06', '2026-10-11 09:00-06',
     'San Carlos, Ciudad Quesada', 'EXPRESS', NULL),
    ('CEDULA_JURIDICA', '3-101-111111', '2026-10-28',
     'CARTAGO', 'Cartago', 'Oriental', '200 m sur de la basílica',
     '2026-10-28 15:00-06', '2026-10-28 18:00-06',
     'Heredia, Santo Domingo', 'MISMO_DIA', 'Entrega urgente'),
    ('CEDULA_JURIDICA', '3-102-222222', '2026-10-12',
     'ALAJUELA', 'San Ramón', 'Central', 'Local comercial 3',
     '2026-10-13 08:00-06', '2026-10-13 12:00-06',
     'San José, Barrio Escalante', 'ESTANDAR', 'Sacos de café, 25 kg c/u');

-- ---------------------------------------------------------------------
-- 6. PARTICIPANTES (id_participante lo genera PostgreSQL)
--    Dos que SON clientes (tipo_id/numero_id con valor)
--    Dos que NO son clientes (ambos NULL)
-- ---------------------------------------------------------------------
INSERT INTO participante (identificacion, nombre, tipo_id, numero_id)
VALUES
    ('1-1111-1111',  'María Fernández Solano',  'CEDULA_FISICA',   '1-1111-1111'),
    ('3-101-111111', 'Distribuidora Tica S.A.', 'CEDULA_JURIDICA', '3-101-111111'),
    ('4-4444-4444',  'Jorge Castro Brenes',     NULL, NULL),
    ('5-5555-5555',  'Elena Quesada Vega',      NULL, NULL);

INSERT INTO medio_contacto_participante (id_participante, tipo_medio, valor)
SELECT p.id_participante, v.tipo_medio, v.valor
FROM (VALUES
        ('Jorge Castro Brenes', 'TELEFONO', '8888-0009'),
        ('Jorge Castro Brenes', 'CORREO',   'jorge.castro@ejemplo.com'),
        ('Elena Quesada Vega',  'WHATSAPP', '8888-0010')
     ) AS v(nombre, tipo_medio, valor)
JOIN participante p ON p.nombre = v.nombre;