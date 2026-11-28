
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path = huellas, pg_catalog;
SET LOCAL TIME ZONE 'America/Costa_Rica';
SET LOCAL ROLE huellas_g05_operador;

-- Solicitud de la familia A.

SELECT crear_solicitud(
    '10000000-0000-0000-0000-000000000001',
    101,
    '2026-10-11 08:00',
    'Casa con espacio adecuado',
    'Dos adultos',
    'Experiencia con animales',
    'Cuidados diarios y seguimiento',
    1,
    ARRAY['HS-03']
) AS solicitud_a \gset

SELECT decision_id AS recepcion_a
FROM estado_actual_solicitud
WHERE id_solicitud = :solicitud_a \gset

SELECT registrar_actividad(
    '10000000-0000-0000-0000-000000000002',
    :solicitud_a,
    '2026-10-11 09:00',
    1,
    'ENTREVISTA',
    'Entrevista favorable',
    'Condiciones del hogar verificadas'
) AS entrevista_a \gset

SELECT decidir_solicitud(
    '10000000-0000-0000-0000-000000000003',
    :solicitud_a,
    :recepcion_a,
    '2026-10-11 10:00',
    1,
    'APROBADA',
    'Condiciones generales adecuadas'
) AS aprobacion_a \gset

SELECT evaluar_compatibilidad(
    '10000000-0000-0000-0000-000000000004',
    :solicitud_a,
    'HS-03',
    3,
    '2026-10-11 11:00',
    1,
    'FAVORABLE',
    'Hogar compatible',
    'Valoracion favorable',
    'Prueba de concurrencia familia A',
    :entrevista_a
) AS compatibilidad_a \gset

-- Solicitud de la familia B.

SELECT crear_solicitud(
    '10000000-0000-0000-0000-000000000005',
    102,
    '2026-10-11 08:00',
    'Casa con espacio suficiente',
    'Dos adultos',
    'Experiencia con mascotas',
    'Cuidados diarios y veterinarios',
    1,
    ARRAY['HS-03']
) AS solicitud_b \gset

SELECT decision_id AS recepcion_b
FROM estado_actual_solicitud
WHERE id_solicitud = :solicitud_b \gset

SELECT registrar_actividad(
    '10000000-0000-0000-0000-000000000006',
    :solicitud_b,
    '2026-10-11 09:00',
    1,
    'ENTREVISTA',
    'Entrevista favorable',
    'Condiciones del hogar verificadas'
) AS entrevista_b \gset

SELECT decidir_solicitud(
    '10000000-0000-0000-0000-000000000007',
    :solicitud_b,
    :recepcion_b,
    '2026-10-11 10:00',
    1,
    'APROBADA',
    'Condiciones generales adecuadas'
) AS aprobacion_b \gset

SELECT evaluar_compatibilidad(
    '10000000-0000-0000-0000-000000000008',
    :solicitud_b,
    'HS-03',
    3,
    '2026-10-11 11:00',
    1,
    'FAVORABLE',
    'Hogar compatible',
    'Valoracion favorable',
    'Prueba de concurrencia familia B',
    :entrevista_b
) AS compatibilidad_b \gset

COMMIT;

SELECT
    id_solicitud,
    solicitante_id,
    estado
FROM huellas.estado_actual_solicitud
WHERE id_solicitud IN (:solicitud_a, :solicitud_b);

SELECT
    id_compatibilidad,
    solicitud_id,
    animal_codigo,
    ingreso_id,
    resultado
FROM huellas.compatibilidad_animal_hogar
WHERE solicitud_id IN (:solicitud_a, :solicitud_b);

SELECT *
FROM huellas.reserva
WHERE animal_codigo = 'HS-03';

\echo PREPARACION DE CONCURRENCIA COMPLETADA
\echo Solicitud familia A: :solicitud_a
\echo Solicitud familia B: :solicitud_b
