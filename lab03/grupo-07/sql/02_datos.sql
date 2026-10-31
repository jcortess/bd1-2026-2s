-- Archivo : 02_datos.sql
-- Propósito: carga inicial de datos ficticios (sin datos personales reales)
--
-- Los identificadores se dan explícitamente para que las consultas y las
-- pruebas tengan resultados esperados fijos. Al final se ajustan las
-- secuencias de identidad para que los INSERT siguientes continúen la
-- numeración sin chocar.
--
-- Escenarios cubiertos (uno por evento):
--   E1  Boda, CERRADO, totalmente pagado. Un pago cubre varios cargos y un
--       cargo se paga en varios pagos (N:M en ambos sentidos). Incluye un
--       servicio prestado parcialmente, una penalización aprobada y una
--       rechazada.
--   E2  Empresarial de una ORGANIZACIÓN, CONFIRMADO, adelanto completo y
--       saldo parcial.
--   E3  Familiar, CONFIRMADO, sin pagos: adelanto pendiente; tiene un cargo
--       aún pendiente de aprobación que no cuenta para el saldo.
--   E4  Comunitario, CANCELADO: servicio anulado y penalización por
--       cancelación sin pagar.
--   Además: un cliente con una solicitud en evaluación y sin evento, y una
--   versión de propuesta superada.

BEGIN;

-- PERSONA
INSERT INTO persona (id_persona, identificacion, nombre_completo) VALUES
    (1, '1-1111-0001', 'Ana Rojas Mora'),
    (2, '2-0745-0312', 'Luis Vargas Solís'),
    (3, '4-0222-0456', 'María Jiménez Castro'),
    (4, '1-0987-0654', 'Carlos Méndez Arias'),
    (5, '2-0555-0777', 'Sofía Alfaro Quesada'),   
    (6, '3-0333-0999', 'Diego Chaves Rojas'),
    (7, '5-0111-0222', 'Valeria Solano Pérez');

-- CLIENTE (3 personas y 2 organizaciones)
INSERT INTO cliente (id_cliente, tipo_cliente, id_persona, identificacion_juridica, razon_social) VALUES
    (1, 'Persona',      1,    NULL,           NULL),
    (2, 'Persona',      2,    NULL,           NULL),
    (3, 'Organización', NULL, '3-101-456789', 'Café del Valle S.A.'),
    (4, 'Persona',      4,    NULL,           NULL),
    (5, 'Organización', NULL, '3-102-778899', 'Cooperativa Agrícola Norte R.L.');

-- ESPACIO (dos propios y uno de terceros)
INSERT INTO espacio (id_espacio, nombre, tipo_propiedad, ubicacion, capacidad, propietario_externo, divisible) VALUES
    (1, 'Salón Arenal',     'Propio',      'La Fortuna, San Carlos',     250, NULL,                FALSE),
    (2, 'Finca El Roble',   'De terceros', 'Ciudad Quesada, San Carlos', 400, 'Hacienda El Roble', FALSE),
    (3, 'Terraza Mirador',  'Propio',      'La Fortuna, San Carlos',      80, NULL,                FALSE);

-- SOLICITUD
INSERT INTO solicitud (id_solicitud, id_cliente, fecha_solicitud, tipo_evento, fecha_desde, fecha_hasta,
                       horario_aproximado, asistentes_esperados, ubicacion_preferida,
                       necesidades_conocidas, estado_solicitud) VALUES
    (1, 1, '2026-07-15', 'boda',        '2026-09-19', '2026-09-26', '17:00 a 24:00', 150, 'San Carlos', 'Menú con opción vegetariana', 'Aprobada'),
    (2, 3, '2026-08-25', 'empresarial', '2026-11-06', '2026-11-06', '08:00 a 17:00',  80, NULL,         'Proyector y sonido',          'Aprobada'),
    (3, 2, '2026-09-28', 'familiar',    '2026-11-21', '2026-11-21', '18:00 a 23:00',  60, 'La Fortuna', NULL,                          'Aprobada'),
    (4, 4, '2026-08-10', 'comunitario', '2026-10-17', '2026-10-17', '09:00 a 15:00', 300, NULL,         'Tarima y sonido',             'Aprobada'),
    (5, 5, '2026-10-20', 'empresarial', '2026-12-04', '2026-12-11', '08:00 a 13:00', 120, NULL,         NULL,                          'En evaluación');

-- ALTERNATIVA_SOLICITUD (la solicitud 1 evaluó dos espacios)
INSERT INTO alternativa_solicitud (id_alternativa, id_solicitud, fecha_desde, fecha_hasta, id_espacio, estado_alternativa) VALUES
    (1, 1, '2026-09-19', '2026-09-19', 2, 'En evaluación'),   -- elegida en E1
    (2, 1, '2026-09-26', '2026-09-26', 1, 'Descartada'),
    (3, 2, '2026-11-06', '2026-11-06', 1, 'En evaluación'),   -- elegida en E2
    (4, 3, '2026-11-21', '2026-11-21', 3, 'En evaluación'),   -- elegida en E3
    (5, 4, '2026-10-17', '2026-10-17', 2, 'En evaluación'),   -- elegida en E4
    (6, 5, '2026-12-04', '2026-12-04', 1, 'En evaluación');

-- PROPUESTA (la solicitud 1 tuvo dos versiones)
INSERT INTO propuesta (id_propuesta, id_solicitud, numero_version, fecha_version, vigencia_hasta, condiciones, estado_propuesta) VALUES
    (1, 1, 1, '2026-07-25', '2026-08-10', 'Adelanto de 500 000 al confirmar',                       'Superada'),
    (2, 1, 2, '2026-08-12', '2026-08-31', 'Adelanto de 500 000 al confirmar; saldo antes del evento', 'Vigente'),
    (3, 2, 1, '2026-09-05', '2026-09-30', 'Adelanto de 300 000; saldo 15 días después',              'Vigente'),
    (4, 3, 1, '2026-10-02', '2026-10-20', 'Adelanto de 150 000 al confirmar',                       'Vigente'),
    (5, 4, 1, '2026-08-20', '2026-09-05', 'Adelanto de 200 000; cancelación con 30 días de aviso',  'Vigente'),
    (6, 5, 1, '2026-10-25', '2026-11-15', 'Adelanto de 400 000 al confirmar',                       'Vigente');

-- EVENTO (propuestas confirmadas)
INSERT INTO evento (id_evento, id_propuesta, id_alternativa, id_persona_autorizada, fecha_aceptacion,
                    monto_adelanto_requerido, tipo_evento, fecha_inicio, fecha_fin, estado_evento, fecha_cierre) VALUES
    (1, 2, 1, 6, '2026-08-20', 500000.00, 'boda',        '2026-09-19', '2026-09-19', 'Cerrado',    '2026-09-21'),
    (2, 3, 3, 3, '2026-09-15', 300000.00, 'empresarial', '2026-11-06', '2026-11-06', 'Confirmado', NULL),
    (3, 4, 4, 2, '2026-10-10', 150000.00, 'familiar',    '2026-11-21', '2026-11-21', 'Confirmado', NULL),
    (4, 5, 5, 4, '2026-09-01', 200000.00, 'comunitario', '2026-10-17', '2026-10-17', 'Cancelado',  NULL);

-- SERVICIO
INSERT INTO servicio (id_servicio, nombre, categoria, modo_suministro) VALUES
    (1, 'Banquete',                'alimentación', 'Propio'),
    (2, 'Fotografía',              'fotografía',   'Externo'),
    (3, 'Sonido y DJ',             'sonido',       'Externo'),
    (4, 'Decoración floral',       'decoración',   'Externo'),
    (5, 'Coordinación del evento', 'coordinación', 'Propio');

-- SERVICIO_EVENTO
INSERT INTO servicio_evento (id_servicio_evento, id_evento, id_servicio, alcance, cantidad, inicio_servicio, fin_servicio,
                             precio_acordado, situacion_contratacion, estado_prestacion, cantidad_prestada, observacion_prestacion) VALUES
    (1, 1, 1, 'Cena para 150 invitados',       150, '2026-09-19 19:00', '2026-09-19 22:00',  12000.00, 'Propio',     'Prestado',              NULL, NULL),
    (2, 1, 2, 'Cobertura fotográfica de 6 h',    1, '2026-09-19 17:00', '2026-09-19 23:00', 450000.00, 'Contratado', 'Prestado',              NULL, NULL),
    (3, 1, 4, 'Arreglos florales de mesa',      15, '2026-09-19 15:00', '2026-09-19 23:59',  25000.00, 'Contratado', 'Prestado parcialmente',   12, 'Se entregaron 12 de 15 arreglos'),
    (4, 2, 1, 'Almuerzo ejecutivo',             80, '2026-11-06 12:00', '2026-11-06 13:30',   9500.00, 'Propio',     'Por verificar',         NULL, NULL),
    (5, 2, 3, 'Sonido para conferencia',         1, '2026-11-06 07:30', '2026-11-06 17:00', 350000.00, 'Contratado', 'Por verificar',         NULL, NULL),
    (6, 3, 1, 'Cena familiar',                  60, '2026-11-21 19:00', '2026-11-21 21:00',  11000.00, 'Propio',     'Por verificar',         NULL, NULL),
    (7, 3, 5, 'Coordinación general',            1, '2026-11-21 16:00', '2026-11-21 23:00', 200000.00, 'Propio',     'Por verificar',         NULL, NULL),
    (8, 4, 3, 'Tarima con sonido',               1, '2026-10-17 08:00', '2026-10-17 15:00', 300000.00, 'Cancelado',  'No prestado',           NULL, 'Evento cancelado');

-- CARGO
--   Solo los Aprobado cuentan para el saldo.
--   E1 aprobado = 1 800 000 + 450 000 + 300 000 + 60 000 = 2 610 000
--   E2 aprobado =   760 000 + 350 000                     = 1 110 000
--   E3 aprobado =   660 000   (el de 200 000 sigue pendiente de aprobación)
--   E4 aprobado =   200 000   (el servicio anulado no cuenta)
INSERT INTO cargo (id_cargo, id_evento, tipo_cargo, descripcion, monto, fecha_cargo, id_servicio_evento,
                   justificacion, id_cliente_responsable, estado_cargo, id_persona_aprueba, fecha_aprobacion) VALUES
    ( 1, 1, 'Componente',   'Banquete: 150 × 12 000',               1800000.00, '2026-08-20', 1, NULL,                                      1, 'Aprobado',                5, '2026-08-20'),
    ( 2, 1, 'Componente',   'Fotografía 6 h',                        450000.00, '2026-08-20', 2, NULL,                                      1, 'Aprobado',                5, '2026-08-20'),
    ( 3, 1, 'Componente',   'Decoración: 12 arreglos entregados',    300000.00, '2026-09-21', 3, NULL,                                      1, 'Aprobado',                5, '2026-09-21'),
    ( 4, 1, 'Penalización', 'Daño en mantelería',                     60000.00, '2026-09-21', NULL, 'Dos manteles con manchas permanentes', 1, 'Aprobado',                5, '2026-09-21'),
    ( 5, 1, 'Penalización', 'Hora extra de uso del espacio',          80000.00, '2026-09-21', NULL, 'Se solicitó extender una hora',        1, 'Rechazado',            NULL, NULL),
    ( 6, 2, 'Componente',   'Almuerzo ejecutivo: 80 × 9 500',        760000.00, '2026-09-15', 4, NULL,                                      3, 'Aprobado',                5, '2026-09-15'),
    ( 7, 2, 'Componente',   'Sonido para conferencia',               350000.00, '2026-09-15', 5, NULL,                                      3, 'Aprobado',                5, '2026-09-15'),
    ( 8, 3, 'Componente',   'Cena familiar: 60 × 11 000',            660000.00, '2026-10-10', 6, NULL,                                      2, 'Aprobado',                5, '2026-10-10'),
    ( 9, 3, 'Componente',   'Coordinación general',                  200000.00, '2026-10-26', 7, NULL,                                      2, 'Pendiente de aprobación', NULL, NULL),
    (10, 4, 'Componente',   'Tarima con sonido',                     300000.00, '2026-09-01', 8, NULL,                                      4, 'Anulado',              NULL, NULL),
    (11, 4, 'Penalización', 'Cancelación con menos de 30 días',      200000.00, '2026-09-20', NULL, 'Aviso de cancelación el 2026-09-20',   4, 'Aprobado',                5, '2026-09-20');

-- PAGO
INSERT INTO pago (id_pago, id_evento, fecha_pago, monto, medio_pago, referencia, es_adelanto) VALUES
    (1, 1, '2026-08-21',  500000.00, 'SINPE Móvil',   'SP-10001', TRUE),
    (2, 1, '2026-09-10', 1500000.00, 'Transferencia', 'TR-55001', FALSE),
    (3, 1, '2026-09-22',  610000.00, 'Efectivo',      NULL,       FALSE),
    (4, 2, '2026-09-16',  300000.00, 'Transferencia', 'TR-55120', TRUE),
    (5, 2, '2026-10-20',  200000.00, 'Tarjeta',       'TJ-8841',  FALSE);

-- APLICACION_PAGO (N:M)
--   Pago 2 cubre los cargos 1 y 2; pago 3 cubre los cargos 2, 3 y 4.
--   Cargo 1 se pagó con los pagos 1 y 2; cargo 2 con los pagos 2 y 3.
INSERT INTO aplicacion_pago (id_pago, id_cargo, id_evento, monto_aplicado) VALUES
    (1, 1, 1,  500000.00),
    (2, 1, 1, 1300000.00),
    (2, 2, 1,  200000.00),
    (3, 2, 1,  250000.00),
    (3, 3, 1,  300000.00),
    (3, 4, 1,   60000.00),
    (4, 6, 2,  300000.00),
    (5, 6, 2,  200000.00);

-- Ajuste de las secuencias de identidad
SELECT setval(pg_get_serial_sequence('persona',               'id_persona'),         (SELECT MAX(id_persona)         FROM persona));
SELECT setval(pg_get_serial_sequence('cliente',               'id_cliente'),         (SELECT MAX(id_cliente)         FROM cliente));
SELECT setval(pg_get_serial_sequence('espacio',               'id_espacio'),         (SELECT MAX(id_espacio)         FROM espacio));
SELECT setval(pg_get_serial_sequence('solicitud',             'id_solicitud'),       (SELECT MAX(id_solicitud)       FROM solicitud));
SELECT setval(pg_get_serial_sequence('alternativa_solicitud', 'id_alternativa'),     (SELECT MAX(id_alternativa)     FROM alternativa_solicitud));
SELECT setval(pg_get_serial_sequence('propuesta',             'id_propuesta'),       (SELECT MAX(id_propuesta)       FROM propuesta));
SELECT setval(pg_get_serial_sequence('evento',                'id_evento'),          (SELECT MAX(id_evento)          FROM evento));
SELECT setval(pg_get_serial_sequence('servicio',              'id_servicio'),        (SELECT MAX(id_servicio)        FROM servicio));
SELECT setval(pg_get_serial_sequence('servicio_evento',       'id_servicio_evento'), (SELECT MAX(id_servicio_evento) FROM servicio_evento));
SELECT setval(pg_get_serial_sequence('cargo',                 'id_cargo'),           (SELECT MAX(id_cargo)           FROM cargo));
SELECT setval(pg_get_serial_sequence('pago',                  'id_pago'),            (SELECT MAX(id_pago)            FROM pago));

COMMIT;
