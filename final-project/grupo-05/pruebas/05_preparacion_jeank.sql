
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path = huellas, pg_catalog;
SET LOCAL TIME ZONE 'America/Costa_Rica';
SET LOCAL ROLE huellas_g05_operador;

-- ============================================================
-- PREPARACION DE PRUEBAS G05-P03
-- ============================================================

-- 1. Alojamiento de los animales.

SELECT mover_animal(
    1, NULL, 1,
    '2026-10-04 08:00',
    1, 'CONVIVENCIA'
) AS estancia_a \gset

SELECT mover_animal(
    2, NULL, 1,
    '2026-10-04 08:30',
    1, 'CONVIVENCIA'
) AS estancia_b \gset


-- 2. Solicitud de la familia A.
-- Interes en dos animales.

SELECT crear_solicitud(
    '06000000-0000-0000-0000-000000000001',
    101,
    '2026-10-07 08:00',
    'Casa con patio cerrado',
    'Dos adultos',
    'Experiencia con animales',
    'Alimentacion y atencion veterinaria',
    1,
    ARRAY['HS-01', 'HS-02']
) AS solicitud_a \gset

SELECT decision_id AS recepcion_a
FROM estado_actual_solicitud
WHERE id_solicitud = :solicitud_a \gset

SELECT registrar_actividad(
    '06000000-0000-0000-0000-000000000002',
    :solicitud_a,
    '2026-10-07 10:00',
    1,
    'ENTREVISTA',
    'Entrevista favorable',
    'Condiciones del hogar verificadas'
) AS entrevista_a \gset

SELECT decidir_solicitud(
    '06000000-0000-0000-0000-000000000003',
    :solicitud_a,
    :recepcion_a,
    '2026-10-07 11:00',
    1,
    'APROBADA',
    'Condiciones generales adecuadas'
) AS aprobacion_a \gset


-- 3. Compatibilidad de la familia A con HS-01.

SELECT evaluar_compatibilidad(
    '06000000-0000-0000-0000-000000000004',
    :solicitud_a,
    'HS-01',
    1,
    '2026-10-07 12:00',
    1,
    'FAVORABLE',
    'Hogar adecuado para el animal',
    'Condiciones compatibles',
    'Valoracion ficticia de prueba',
    :entrevista_a
) AS compatibilidad_a1 \gset


-- 4. Compatibilidad de la familia A con HS-02.

SELECT evaluar_compatibilidad(
    '06000000-0000-0000-0000-000000000005',
    :solicitud_a,
    'HS-02',
    2,
    '2026-10-07 12:00',
    1,
    'FAVORABLE',
    'Hogar adecuado para el segundo animal',
    'Condiciones compatibles',
    'Valoracion individual de prueba',
    :entrevista_a
) AS compatibilidad_a2 \gset


-- 5. Solicitud de la familia B.
-- Interes en el mismo animal HS-01.

SELECT crear_solicitud(
    '06000000-0000-0000-0000-000000000006',
    102,
    '2026-10-07 08:00',
    'Casa con espacio suficiente',
    'Dos adultos',
    'Experiencia previa con mascotas',
    'Cuidados diarios y seguimiento',
    1,
    ARRAY['HS-01']
) AS solicitud_b \gset

SELECT decision_id AS recepcion_b
FROM estado_actual_solicitud
WHERE id_solicitud = :solicitud_b \gset

SELECT registrar_actividad(
    '06000000-0000-0000-0000-000000000007',
    :solicitud_b,
    '2026-10-07 10:00',
    1,
    'ENTREVISTA',
    'Entrevista favorable',
    'Condiciones de cuidado verificadas'
) AS entrevista_b \gset

SELECT decidir_solicitud(
    '06000000-0000-0000-0000-000000000008',
    :solicitud_b,
    :recepcion_b,
    '2026-10-07 11:00',
    1,
    'APROBADA',
    'Condiciones generales adecuadas'
) AS aprobacion_b \gset


-- 6. Compatibilidad de la familia B con HS-01.

SELECT evaluar_compatibilidad(
    '06000000-0000-0000-0000-000000000009',
    :solicitud_b,
    'HS-01',
    1,
    '2026-10-07 12:00',
    1,
    'FAVORABLE',
    'Hogar adecuado para el animal',
    'Condiciones compatibles',
    'Segunda familia interesada',
    :entrevista_b
) AS compatibilidad_b1 \gset

COMMIT;

-- ============================================================
-- VERIFICACION DEL ESCENARIO
-- ============================================================

SELECT id_solicitud, solicitante_id, estado
FROM huellas.estado_actual_solicitud
ORDER BY id_solicitud;

SELECT
    id_compatibilidad,
    solicitud_id,
    animal_codigo,
    ingreso_id,
    resultado
FROM huellas.compatibilidad_animal_hogar
ORDER BY id_compatibilidad;

SELECT
    id_estancia,
    animal_codigo,
    ingreso_id,
    fecha_fin_real
FROM huellas.estancia
WHERE fecha_fin_real IS NULL;

\echo PREPARACION COMPLETADA
\echo Solicitud familia A: :solicitud_a
\echo Solicitud familia B: :solicitud_b
\echo Estancia HS-01: :estancia_a
\echo Estancia HS-02: :estancia_b
