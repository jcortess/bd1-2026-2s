-- =====================================================================
-- 02_datos.sql
-- Proyecto final IC-4301 - Grupo 08: Envíos Conecta
-- Datos ficticios o "quemados" de preparación. Requiere 01_esquema.sql sobre una base
-- nueva y vacía. No contiene resultados de los procesos P01, P02 ni P03:
-- esos datos los crean las rutinas.
-- =====================================================================


-- =====================================================================
-- PARTE 1. DIRECTORIO (origen: Lab03, con CAM-001 y CAM-010)
-- =====================================================================

INSERT INTO cliente (tipo_id, numero_id, nombre_razon_social, tipo_cliente, condicion_contractual)
VALUES
    ('CEDULA_FISICA',   '1-1111-1111',  'María Fernández Solano',  'PERSONA_FISICA',   'CONTRATO_ESTANDAR'),
    ('CEDULA_FISICA',   '2-2222-2222',  'Carlos Jiménez Rojas',    'PERSONA_FISICA',   'SIN_CONTRATO'),
    ('CEDULA_JURIDICA', '3-101-111111', 'Distribuidora Tica S.A.', 'PERSONA_JURIDICA', 'CONTRATO_CORPORATIVO'),
    ('CEDULA_JURIDICA', '3-102-222222', 'Café Montaña S.R.L.',     'PERSONA_JURIDICA', 'CONTRATO_ESTANDAR'),
    ('DIMEX',           '155800000001', 'Ana Lucía Pérez Gómez',   'PERSONA_FISICA',   'SIN_CONTRATO'),
    ('PASAPORTE',       'X1234567',     'John Smith',              'PERSONA_FISICA',   'SIN_CONTRATO');

INSERT INTO medio_contacto_cliente (tipo_id, numero_id, tipo_medio, valor, descripcion_medio)
VALUES
    ('CEDULA_FISICA',   '1-1111-1111',  'TELEFONO', '2441-0001', NULL),
    ('CEDULA_FISICA',   '1-1111-1111',  'TELEFONO', '8888-0001', NULL),
    ('CEDULA_FISICA',   '1-1111-1111',  'CORREO',   'maria.fernandez@ejemplo.com', NULL),
    ('CEDULA_FISICA',   '2-2222-2222',  'WHATSAPP', '8888-0002', NULL),
    ('CEDULA_JURIDICA', '3-101-111111', 'CORREO',   'info@distribuidoratica.example', NULL),
    ('CEDULA_JURIDICA', '3-101-111111', 'TELEFONO', '2222-0003', NULL),
    ('CEDULA_JURIDICA', '3-102-222222', 'WHATSAPP', '8888-0004', NULL),
    ('CEDULA_JURIDICA', '3-102-222222', 'OTRO',     '@cafemontana', 'Telegram');   -- [CAM-010]

INSERT INTO direccion_habitual
    (tipo_id, numero_id, num_direccion, provincia, canton, distrito,
     otras_senas, instrucciones_acceso, referencia_geografica, activa)
VALUES
    ('CEDULA_FISICA',   '1-1111-1111',  1, 'ALAJUELA', 'Alajuela',  'San José',
     '100 m norte de la iglesia', 'Tocar el timbre dos veces', NULL, TRUE),
    ('CEDULA_FISICA',   '1-1111-1111',  2, 'SAN_JOSE', 'Escazú',    'San Rafael',
     'Edificio azul, apartamento 4', NULL, 'Frente al parque', TRUE),
    ('CEDULA_FISICA',   '1-1111-1111',  3, 'HEREDIA',  'Heredia',   'Mercedes',
     'Casa esquinera de portón verde', NULL, NULL, FALSE),
    ('CEDULA_JURIDICA', '3-101-111111', 1, 'SAN_JOSE', 'San José',  'Pavas',
     'Bodega 12, zona industrial', 'Presentarse en la garita con cédula', 'Contiguo a la gasolinera', TRUE),
    ('CEDULA_JURIDICA', '3-101-111111', 2, 'CARTAGO',  'Cartago',   'Oriental',
     '200 m sur de la basílica', NULL, NULL, TRUE),
    ('CEDULA_JURIDICA', '3-102-222222', 1, 'ALAJUELA', 'San Ramón', 'Central',
     'Local comercial 3', NULL, 'Costado oeste del mercado', TRUE);

-- Contactos: solo de organizaciones (RN-02, CAM-011).
-- Se insertan con su primera facultad en la misma transacción (S-02).
BEGIN;
INSERT INTO contacto (tipo_id, numero_id, nombre)
VALUES
    ('CEDULA_JURIDICA', '3-101-111111', 'Laura Mora Campos'),
    ('CEDULA_JURIDICA', '3-101-111111', 'Pedro Vargas Soto'),
    ('CEDULA_JURIDICA', '3-102-222222', 'Sofía Araya León'),
    ('CEDULA_JURIDICA', '3-102-222222', 'Rosa Solano Díaz');

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
COMMIT;

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

-- Participantes con tipo de identificación (CAM-001)
INSERT INTO participante (tipo_identificacion, identificacion, nombre, tipo_id, numero_id)
VALUES
    ('CEDULA_FISICA',   '1-1111-1111',  'María Fernández Solano',  'CEDULA_FISICA',   '1-1111-1111'),
    ('CEDULA_JURIDICA', '3-101-111111', 'Distribuidora Tica S.A.', 'CEDULA_JURIDICA', '3-101-111111'),
    ('CEDULA_FISICA',   '4-4444-4444',  'Jorge Castro Brenes',     NULL, NULL),
    ('CEDULA_FISICA',   '5-5555-5555',  'Elena Quesada Vega',      NULL, NULL);

INSERT INTO medio_contacto_participante (id_participante, tipo_medio, valor)
SELECT p.id_participante, v.tipo_medio, v.valor
FROM (VALUES
        ('Jorge Castro Brenes', 'TELEFONO', '8888-0009'),
        ('Jorge Castro Brenes', 'CORREO',   'jorge.castro@ejemplo.com'),
        ('Elena Quesada Vega',  'WHATSAPP', '8888-0010')
     ) AS v(nombre, tipo_medio, valor)
JOIN participante p ON p.nombre = v.nombre;


-- =====================================================================
-- PARTE 2. CATÁLOGOS (no los crea ningún proceso)
-- =====================================================================

INSERT INTO sede (nombre, tipo, provincia, canton, distrito, otras_senas, zona)
VALUES
    ('Centro de Distribución Pavas', 'CENTRO_DISTRIBUCION', 'SAN_JOSE',   'San José', 'Pavas',   'Zona industrial, bodega 5', 'GAM'),
    ('Sucursal Liberia',             'SUCURSAL',            'GUANACASTE', 'Liberia',  'Liberia', 'Barrio La Victoria, local 2', 'CHOROTEGA'),
    ('Sucursal Limón',               'SUCURSAL',            'LIMON',      'Limón',    'Limón',   'Frente al muelle', 'HUETAR_CARIBE');

INSERT INTO personal (identificacion, nombre)
VALUES
    ('1-0101-0101', 'Andrés Mora Vega'),
    ('1-0202-0202', 'Luis Chaves Solís'),
    ('1-0303-0303', 'Paula Rojas Núñez'),
    ('1-0404-0404', 'Sergio Alfaro Mena'),
    ('1-0505-0505', 'Karla Vindas Arias'),
    ('1-0606-0606', 'Diego Calvo Brenes');

-- Luis tiene dos funciones (S-14)
INSERT INTO funcion_personal (id_personal, funcion)
SELECT p.id_personal, v.funcion
FROM (VALUES
        ('1-0101-0101', 'CONDUCTOR'),
        ('1-0202-0202', 'CONDUCTOR'),
        ('1-0202-0202', 'MENSAJERO'),
        ('1-0303-0303', 'MENSAJERO'),
        ('1-0404-0404', 'OPERADOR_SEDE'),
        ('1-0505-0505', 'OPERADOR_SEDE'),
        ('1-0606-0606', 'CONDUCTOR')
     ) AS v(identificacion, funcion)
JOIN personal p ON p.identificacion = v.identificacion;

-- Capacidad de peso en kg y de volumen en m3 (CAM-009)
INSERT INTO vehiculo (placa, tipo, capacidad_peso, capacidad_volumen, refrigerado, condicion_operativa)
VALUES
    ('BCD123',    'PANEL',       800.000,  6.000000, FALSE, 'OPERATIVO'),
    ('CL-245678', 'CAMION',     3000.000, 20.000000, TRUE,  'OPERATIVO'),
    ('MOT456',    'MOTOCICLETA',  30.000,  0.150000, FALSE, 'OPERATIVO'),
    ('BCF987',    'PANEL',       800.000,  6.000000, FALSE, 'EN_MANTENIMIENTO');

-- Un periodo pasado ya cerrado y uno abierto (vehículo en mantenimiento)
INSERT INTO periodo_fuera_servicio (id_interno, inicio, fin)
SELECT v.id_interno, x.inicio, x.fin
FROM (VALUES
        ('BCD123', TIMESTAMPTZ '2026-10-01 08:00-06', TIMESTAMPTZ '2026-10-03 17:00-06'),
        ('BCF987', TIMESTAMPTZ '2026-11-20 08:00-06', NULL::TIMESTAMPTZ)
     ) AS x(placa, inicio, fin)
JOIN vehiculo v ON v.placa = x.placa;

-- Rutas hacia una sede y hacia una zona (CAM-017)
INSERT INTO ruta (id_sede_origen, id_sede_destino, nombre, zona_destino)
SELECT o.id_sede, d.id_sede, x.nombre, x.zona
FROM (VALUES
        ('Centro de Distribución Pavas', 'Sucursal Liberia', 'Pavas - Liberia', 'CHOROTEGA'),
        ('Centro de Distribución Pavas', 'Sucursal Limón',   'Pavas - Limón',   NULL),
        ('Centro de Distribución Pavas', NULL,               'Reparto Escazú',  'GAM_OESTE')
     ) AS x(origen, destino, nombre, zona)
JOIN sede o ON o.nombre = x.origen
LEFT JOIN sede d ON d.nombre = x.destino;

-- Tarifas: generales vigentes, una de contrato y una vencida (CAM-013).
-- Precio en colones; no es una fórmula tarifaria real (anexo G08-P01-L).
INSERT INTO tarifa
    (tipo_id, numero_id, nivel_servicio, zona_origen, zona_destino,
     rango_peso_min, rango_peso_max, rango_volumen_min, rango_volumen_max,
     condicion_especial, precio, vigencia_inicio, vigencia_fin)
VALUES
    (NULL, NULL, 'ESTANDAR', 'GAM', 'CHOROTEGA',     0, 30,  0, 0.5, NULL,           4500.00, '2026-01-01', NULL),
    (NULL, NULL, 'EXPRESS',  'GAM', 'HUETAR_CARIBE', 0, 30,  0, 0.5, NULL,           7200.00, '2026-01-01', NULL),
    (NULL, NULL, 'ESTANDAR', 'GAM', 'GAM',           0, 30,  0, 0.5, 'REFRIGERACION', 6800.00, '2026-01-01', NULL),
    ('CEDULA_JURIDICA', '3-101-111111',
                 'ESTANDAR', 'GAM', 'HUETAR_CARIBE', 0, 100, 0, 2.0, NULL,           3800.00, '2026-01-01', '2026-12-31'),
    (NULL, NULL, 'ECONOMICO','GAM', 'GAM',           0, 30,  0, 0.5, NULL,           2500.00, '2025-01-01', '2025-12-31');

-- =====================================================================
-- PARTE 3. ENVÍOS Y PAQUETES PREVIOS (hechos previos, no resultado de P01)
-- Preparan datos para P02 y P03 y para las pruebas de integridad.
-- P01 se demuestra aparte, creando envíos nuevos con su rutina.
-- Los identificadores asumen una base nueva (IDENTITY empieza en 1):
--   solicitudes 1-7, participantes 1-4, sedes 1-3, personal 1-6,
--   tarifas 1-5 (parte 2) y 6 (abajo).
-- Cada envío se inserta con sus paquetes en una transacción (CAM-012).
-- Volumen = largo x ancho x alto / 1 000 000 (m3, CAM-009).
-- =====================================================================

-- Tarifa general adicional para el envío histórico EC-2026-000090
INSERT INTO tarifa
    (tipo_id, numero_id, nivel_servicio, zona_origen, zona_destino,
     rango_peso_min, rango_peso_max, rango_volumen_min, rango_volumen_max,
     condicion_especial, precio, vigencia_inicio, vigencia_fin)
VALUES
    (NULL, NULL, 'EXPRESS', 'GAM', 'GAM', 0, 30, 0, 0.5, NULL, 5200.00, '2026-01-01', NULL);   -- id 6

-- ---------------------------------------------------------------------
-- Contexto 1: EC-2026-000101 (María, solicitud 1) a Liberia.
-- Remitente cliente; destinatario NO cliente (Jorge).
-- Paquete 1 con dos valores: declarado y una medición aplicada.
-- ---------------------------------------------------------------------
BEGIN;
INSERT INTO envio (numero_guia, id_solicitud, id_recoleccion,
    tipo_id_pagador, numero_id_pagador,
    id_participante_remitente, id_participante_destinatario, id_tarifa,
    fecha_creacion, servicio,
    origen_provincia, origen_canton, origen_distrito, origen_otras_senas,
    destino_provincia, destino_canton, destino_distrito, destino_otras_senas,
    precio_cotizado, cotiz_zona_origen, cotiz_zona_destino, cotiz_peso, cotiz_volumen, cotiz_condiciones)
VALUES ('EC-2026-000101', 1, NULL,
    'CEDULA_FISICA', '1-1111-1111',
    1, 3, 1,
    '2026-10-01', 'ESTANDAR',
    'ALAJUELA', 'Alajuela', 'San José', '100 m norte de la iglesia',
    'GUANACASTE', 'Liberia', 'Liberia', 'Barrio La Victoria, casa 14',
    4500.00, 'GAM', 'CHOROTEGA', 3.500, 0.009000, NULL);

INSERT INTO paquete (numero_guia, num_paquete, peso_declarado, largo_declarado, ancho_declarado, alto_declarado,
    descripcion, politica_contenido, documento_respaldo,
    revision_fecha_hora, revision_resultado, revision_razon, id_personal_revisor)
VALUES
    ('EC-2026-000101', 1, 2.500, 30, 20, 10, 'Libros',         'PERMITIDO', NULL,
     '2026-10-02 09:30-06', 'ACEPTADO', NULL, 4),
    ('EC-2026-000101', 2, 1.000, 20, 15, 10, 'Ropa de algodón', 'PERMITIDO', NULL,
     '2026-10-02 09:35-06', 'ACEPTADO', NULL, 4);
COMMIT;

-- ---------------------------------------------------------------------
-- Contexto 2: EC-2026-000102 (Distribuidora, solicitud 4) a Limón,
-- con tarifa de contrato del propio pagador.
-- Paquetes: aceptado, con respaldo aceptado, prohibido rechazado y retenido.
-- ---------------------------------------------------------------------
BEGIN;
INSERT INTO envio (numero_guia, id_solicitud, id_recoleccion,
    tipo_id_pagador, numero_id_pagador,
    id_participante_remitente, id_participante_destinatario, id_tarifa,
    fecha_creacion, servicio,
    origen_provincia, origen_canton, origen_distrito, origen_otras_senas,
    destino_provincia, destino_canton, destino_distrito, destino_otras_senas,
    precio_cotizado, cotiz_zona_origen, cotiz_zona_destino, cotiz_peso, cotiz_volumen, cotiz_condiciones)
VALUES ('EC-2026-000102', 4, NULL,
    'CEDULA_JURIDICA', '3-101-111111',
    2, 4, 4,
    '2026-09-20', 'ESTANDAR',
    'SAN_JOSE', 'San José', 'Pavas', 'Bodega 12, zona industrial',
    'LIMON', 'Limón', 'Limón', 'Bodega portuaria 3',
    3800.00, 'GAM', 'HUETAR_CARIBE', 29.000, 0.129000, NULL);

INSERT INTO paquete (numero_guia, num_paquete, peso_declarado, largo_declarado, ancho_declarado, alto_declarado,
    descripcion, politica_contenido, documento_respaldo,
    revision_fecha_hora, revision_resultado, revision_razon, id_personal_revisor)
VALUES
    ('EC-2026-000102', 1, 20.000, 60, 40, 40, 'Repuestos automotrices', 'PERMITIDO', NULL,
     '2026-09-22 10:00-06', 'ACEPTADO', NULL, 5),
    ('EC-2026-000102', 2,  3.000, 30, 20, 20, 'Medicamentos veterinarios', 'EXIGE_RESPALDO', 'Permiso sanitario PS-2026-0045',
     '2026-09-22 10:05-06', 'ACEPTADO', NULL, 5),
    ('EC-2026-000102', 3,  2.000, 20, 15, 10, 'Baterías de litio sueltas', 'PROHIBIDO', NULL,
     '2026-09-22 10:10-06', 'RECHAZADO', 'Material prohibido para transporte terrestre', 5),
    ('EC-2026-000102', 4,  4.000, 40, 30, 15, 'Equipo electrónico', 'EXIGE_RESPALDO', NULL,
     '2026-09-22 10:15-06', 'RETENIDO', 'Falta la factura de respaldo', 5);
COMMIT;

-- ---------------------------------------------------------------------
-- Contexto 3: EC-2026-000103 (Distribuidora, solicitud 6) dentro de la GAM.
-- Paquete refrigerado aceptado y paquete con prueba de identidad sin revisar.
-- ---------------------------------------------------------------------
BEGIN;
INSERT INTO envio (numero_guia, id_solicitud, id_recoleccion,
    tipo_id_pagador, numero_id_pagador,
    id_participante_remitente, id_participante_destinatario, id_tarifa,
    fecha_creacion, servicio,
    origen_provincia, origen_canton, origen_distrito, origen_otras_senas,
    destino_provincia, destino_canton, destino_distrito, destino_otras_senas,
    precio_cotizado, cotiz_zona_origen, cotiz_zona_destino, cotiz_peso, cotiz_volumen, cotiz_condiciones)
VALUES ('EC-2026-000103', 6, NULL,
    'CEDULA_JURIDICA', '3-101-111111',
    2, 3, 3,
    '2026-10-28', 'ESTANDAR',
    'CARTAGO', 'Cartago', 'Oriental', '200 m sur de la basílica',
    'HEREDIA', 'Santo Domingo', 'Santo Tomás', 'Condominio Las Flores, casa 8',
    6800.00, 'GAM', 'GAM', 5.500, 0.037500, 'REFRIGERACION');

INSERT INTO paquete (numero_guia, num_paquete, peso_declarado, largo_declarado, ancho_declarado, alto_declarado,
    descripcion, politica_contenido, documento_respaldo,
    revision_fecha_hora, revision_resultado, revision_razon, id_personal_revisor)
VALUES
    ('EC-2026-000103', 1, 5.000, 40, 30, 30, 'Vacunas veterinarias', 'PERMITIDO', NULL,
     '2026-10-28 16:00-06', 'ACEPTADO', NULL, 4),
    ('EC-2026-000103', 2, 0.500, 30, 25,  2, 'Documentos legales',   'PERMITIDO', NULL,
     NULL, NULL, NULL, NULL);
COMMIT;

-- ---------------------------------------------------------------------
-- Envío histórico: EC-2026-000090 (María, solicitud 2) dentro de la GAM.
-- Sirve de base para la entrega y la devolución previas (parte 4).
-- ---------------------------------------------------------------------
BEGIN;
INSERT INTO envio (numero_guia, id_solicitud, id_recoleccion,
    tipo_id_pagador, numero_id_pagador,
    id_participante_remitente, id_participante_destinatario, id_tarifa,
    fecha_creacion, servicio,
    origen_provincia, origen_canton, origen_distrito, origen_otras_senas,
    destino_provincia, destino_canton, destino_distrito, destino_otras_senas,
    precio_cotizado, cotiz_zona_origen, cotiz_zona_destino, cotiz_peso, cotiz_volumen, cotiz_condiciones)
VALUES ('EC-2026-000090', 2, NULL,
    'CEDULA_FISICA', '1-1111-1111',
    1, 4, 6,
    '2026-10-15', 'EXPRESS',
    'SAN_JOSE', 'Escazú', 'San Rafael', 'Edificio azul, apartamento 4',
    'CARTAGO', 'Cartago', 'Oriental', 'Frente a la basílica, local 7',
    5200.00, 'GAM', 'GAM', 3.500, 0.011500, NULL);

INSERT INTO paquete (numero_guia, num_paquete, peso_declarado, largo_declarado, ancho_declarado, alto_declarado,
    descripcion, politica_contenido, documento_respaldo,
    revision_fecha_hora, revision_resultado, revision_razon, id_personal_revisor)
VALUES
    ('EC-2026-000090', 1, 2.000, 25, 20, 15, 'Artesanías de madera', 'PERMITIDO', NULL,
     '2026-10-16 09:00-06', 'ACEPTADO', NULL, 4),
    ('EC-2026-000090', 2, 1.500, 20, 20, 10, 'Juguetes',             'PERMITIDO', NULL,
     '2026-10-16 09:05-06', 'ACEPTADO', NULL, 4);
COMMIT;

-- ---------------------------------------------------------------------
-- Condiciones de manejo (RN-07)
-- ---------------------------------------------------------------------
INSERT INTO condicion_manejo_paquete (numero_guia, num_paquete, condicion)
VALUES
    ('EC-2026-000101', 1, 'FRAGIL'),
    ('EC-2026-000102', 2, 'FRAGIL'),
    ('EC-2026-000103', 1, 'REFRIGERACION'),
    ('EC-2026-000103', 2, 'PRUEBA_IDENTIDAD'),
    ('EC-2026-000090', 1, 'FRAGIL');

-- ---------------------------------------------------------------------
-- Mediciones (RN-10): se agregan sin reemplazar las anteriores.
-- EC-2026-000102 paquete 1 tiene dos mediciones; se aplica la segunda.
-- ---------------------------------------------------------------------
INSERT INTO medicion (numero_guia, num_paquete, num_medicion, id_sede, fecha_hora, peso, largo, ancho, alto)
VALUES
    ('EC-2026-000101', 1, 1, 1, '2026-10-02 09:40-06',  2.700, 31, 20, 10),
    ('EC-2026-000102', 1, 1, 1, '2026-09-22 10:20-06', 21.500, 61, 40, 40),
    ('EC-2026-000102', 1, 2, 1, '2026-09-22 10:40-06', 21.300, 60, 40, 40);

-- Medición usada para clasificar y cobrar (S-07)
UPDATE paquete SET num_medicion_aplicada = 1
WHERE numero_guia = 'EC-2026-000101' AND num_paquete = 1;

UPDATE paquete SET num_medicion_aplicada = 2
WHERE numero_guia = 'EC-2026-000102' AND num_paquete = 1;

-- =====================================================================
-- PARTE 4. HECHOS PREVIOS DE LAS DEMÁS TABLAS
-- Historia anterior a la demostración: no es resultado de P01, P02 ni P03.
-- Los envíos EC-2026-000101 y EC-2026-000103 quedan SIN salidas ni eventos,
-- para que P02 y P03 los usen desde cero.
-- Identificadores: personal 1 Andrés, 2 Luis, 3 Paula, 4 Sergio, 5 Karla,
-- 6 Diego; vehículos 1 BCD123, 2 CL-245678; sedes 1 Pavas, 3 Limón;
-- ruta 2 Pavas - Limón.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Recolección fallida y su reprogramación (RN-09, CAM-002)
-- ---------------------------------------------------------------------
INSERT INTO recoleccion (fecha, franja_inicio, franja_fin,
    direccion_provincia, direccion_canton, direccion_distrito, direccion_otras_senas,
    estado, id_recoleccion_anterior)
VALUES
    ('2026-09-21', '07:00', '11:00', 'SAN_JOSE', 'San José', 'Pavas', 'Bodega 12, zona industrial',
     'REPROGRAMADA', NULL),                                                   -- id 1
    ('2026-09-22', '07:00', '11:00', 'SAN_JOSE', 'San José', 'Pavas', 'Bodega 12, zona industrial',
     'COMPLETADA', 1);                                                        -- id 2, reemplaza a la 1

INSERT INTO intento_recoleccion (id_recoleccion, num_intento, fecha_hora, resultado, observacion)
VALUES
    (1, 1, '2026-09-21 09:00-06', 'FALLIDO', 'Bodega cerrada, nadie atendió'),
    (2, 1, '2026-09-22 08:30-06', 'EXITOSO', NULL);

-- El envío pasa a la recolección vigente (CAM-002, CAM-005)
UPDATE envio SET id_recoleccion = 2 WHERE numero_guia = 'EC-2026-000102';

-- ---------------------------------------------------------------------
-- Salida histórica Pavas - Limón con su manifiesto (RN-13)
-- ---------------------------------------------------------------------
INSERT INTO salida_ruta (id_ruta, fecha, estado)
VALUES (2, '2026-09-23', 'FINALIZADA');                                       -- id 1

INSERT INTO salida_paquete (id_salida, numero_guia, num_paquete, momento_registro)
VALUES
    (1, 'EC-2026-000102', 1, '2026-09-22 16:00-06'),
    (1, 'EC-2026-000102', 2, '2026-09-22 16:05-06');

-- ---------------------------------------------------------------------
-- Asignaciones históricas: dos de recolección y una de salida (CAM-008)
-- ---------------------------------------------------------------------
INSERT INTO asignacion (id_personal, id_vehiculo, id_recoleccion, id_salida,
    inicio, fin, funcion_ejercida, momento_registro)
VALUES
    (1, 1, 1,    NULL, '2026-09-21 07:00-06', '2026-09-21 11:00-06', 'CONDUCTOR', '2026-09-20 15:00-06'),
    (6, 1, 2,    NULL, '2026-09-22 07:00-06', '2026-09-22 11:00-06', 'CONDUCTOR', '2026-09-21 15:00-06'),
    (1, 2, NULL, 1,    '2026-09-23 06:00-06', '2026-09-23 14:00-06', 'CONDUCTOR', '2026-09-22 17:00-06');

-- ---------------------------------------------------------------------
-- Entrega histórica de EC-2026-000090 (RN-14, RN-15, CAM-022, CAM-023)
-- Paquete 1 entregado; paquete 2 rechazado por el destinatario.
-- Devolución del paquete 2 en la misma transacción (CAM-012, CAM-020).
-- ---------------------------------------------------------------------
BEGIN;
INSERT INTO entrega (id_personal, fecha_hora,
    direccion_provincia, direccion_canton, direccion_distrito, direccion_otras_senas,
    receptor_nombre, receptor_identificacion, documento_mostrado, constancia,
    motivo, evidencia, proxima_accion)
VALUES (3, '2026-10-17 10:00-06',
    'CARTAGO', 'Cartago', 'Oriental', 'Frente a la basílica, local 7',
    'Elena Quesada Vega', '5-5555-5555', NULL, 'Firma digital EC-090-01',
    'El destinatario rechazó el paquete 2 por daño en la caja', 'Fotografía EV-090-02',
    'DEVOLUCION_REMITENTE');                                                  -- id 1

INSERT INTO entrega_paquete (id_entrega, numero_guia, num_paquete, resultado, es_final)
VALUES
    (1, 'EC-2026-000090', 1, 'ENTREGADO', TRUE),
    (1, 'EC-2026-000090', 2, 'RECHAZADO', FALSE);

INSERT INTO devolucion (numero_guia, fecha, motivo)
VALUES ('EC-2026-000090', '2026-10-17', 'Paquete rechazado por el destinatario: caja dañada');   -- id 1

INSERT INTO devolucion_paquete (numero_guia, num_paquete, id_devolucion, id_entrega, resultado_entrega)
VALUES ('EC-2026-000090', 2, 1, 1, 'RECHAZADO');
COMMIT;

-- ---------------------------------------------------------------------
-- Incidencia histórica con resultado por paquete (RN-17, RN-18, CAM-021)
-- ---------------------------------------------------------------------
INSERT INTO incidencia (id_personal, tipo, fecha, descripcion, estado, resolucion)
VALUES (5, 'DANO', '2026-10-17', 'Caja dañada durante el reparto en Cartago',
        'RESUELTA', 'Se gestionó la devolución al remitente');                -- id 1

INSERT INTO incidencia_paquete (id_incidencia, numero_guia, num_paquete, resultado)
VALUES (1, 'EC-2026-000090', 2, 'RESUELTO');

-- ---------------------------------------------------------------------
-- Eventos históricos (RN-12, RN-24): en sede, en salida y fuera de sede
-- ---------------------------------------------------------------------
INSERT INTO evento_seguimiento (numero_guia, num_paquete, momento, momento_registro,
    id_personal, id_sede, descripcion_ubicacion, id_salida, id_devolucion,
    tipo_evento, situacion, condicion, observaciones)
VALUES
    -- EC-2026-000102: recepción, salida e ingreso en Limón
    ('EC-2026-000102', 1, '2026-09-22 10:00-06', '2026-09-22 10:01-06', 4, 1, NULL, NULL, NULL,
     'RECEPCION',    'EN_SEDE',       'BUEN_ESTADO', NULL),
    ('EC-2026-000102', 1, '2026-09-23 06:30-06', '2026-09-23 06:31-06', 1, 1, NULL, 1,    NULL,
     'SALIDA_SEDE',  'EN_TRANSITO',   'BUEN_ESTADO', NULL),
    ('EC-2026-000102', 1, '2026-09-23 13:30-06', '2026-09-23 13:32-06', 5, 3, NULL, 1,    NULL,
     'INGRESO_SEDE', 'EN_SEDE',       'BUEN_ESTADO', NULL),
    ('EC-2026-000102', 2, '2026-09-22 10:05-06', '2026-09-22 10:06-06', 4, 1, NULL, NULL, NULL,
     'RECEPCION',    'EN_SEDE',       'BUEN_ESTADO', NULL),
    ('EC-2026-000102', 2, '2026-09-23 06:30-06', '2026-09-23 06:31-06', 1, 1, NULL, 1,    NULL,
     'SALIDA_SEDE',  'EN_TRANSITO',   'BUEN_ESTADO', NULL),
    ('EC-2026-000102', 2, '2026-09-23 13:30-06', '2026-09-23 13:32-06', 5, 3, NULL, 1,    NULL,
     'INGRESO_SEDE', 'EN_SEDE',       'BUEN_ESTADO', NULL),
    -- EC-2026-000090: recepción, entrega fuera de sede y devolución
    ('EC-2026-000090', 1, '2026-10-16 09:00-06', '2026-10-16 09:01-06', 4, 1, NULL, NULL, NULL,
     'RECEPCION',    'EN_SEDE',       'BUEN_ESTADO', NULL),
    ('EC-2026-000090', 1, '2026-10-17 10:00-06', '2026-10-17 10:10-06', 3, NULL,
     'Domicilio del destinatario, Cartago', NULL, NULL,
     'ENTREGA',      'ENTREGADO',     'BUEN_ESTADO', NULL),
    ('EC-2026-000090', 2, '2026-10-16 09:05-06', '2026-10-16 09:06-06', 4, 1, NULL, NULL, NULL,
     'RECEPCION',    'EN_SEDE',       'BUEN_ESTADO', NULL),
    ('EC-2026-000090', 2, '2026-10-17 10:00-06', '2026-10-17 10:10-06', 3, NULL,
     'Domicilio del destinatario, Cartago', NULL, NULL,
     'INTENTO_ENTREGA', 'EN_DEVOLUCION', 'DANADO', 'Rechazado por el destinatario'),
    ('EC-2026-000090', 2, '2026-10-18 09:00-06', '2026-10-18 09:02-06', 4, 1, NULL, NULL, 1,
     'DEVOLUCION',   'EN_DEVOLUCION', 'DANADO', NULL);