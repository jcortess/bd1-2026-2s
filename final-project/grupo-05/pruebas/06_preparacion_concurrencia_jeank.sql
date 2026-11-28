
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path = huellas, pg_catalog;
SET LOCAL TIME ZONE 'America/Costa_Rica';

-- Habilitar HS-03 para las pruebas.

INSERT INTO cambio_disponibilidad (
    animal_codigo,
    ingreso_id,
    fecha,
    estado_disponibilidad,
    responsable_id,
    participacion_responsable_id,
    observacion_general,
    valoracion_sanitaria
)
VALUES (
    'HS-03',
    3,
    '2026-10-08 08:00',
    'HABILITADO',
    1,
    1,
    'Habilitacion ficticia para pruebas',
    'Condiciones sanitarias adecuadas para adopcion'
);

SET LOCAL ROLE huellas_g05_operador;

-- Crear alojamiento para HS-03.

SELECT mover_animal(
    3, NULL, 1,
    '2026-10-08 08:30',
    1, 'CONVIVENCIA'
) AS estancia_c \gset

-- Solicitud de la persona con restriccion vigente.

SELECT crear_solicitud(
    '09000000-0000-0000-0000-000000000001',
    103,
    '2026-10-08 09:00',
    'Casa con espacio adecuado',
    'Dos adultos',
    'Experiencia con mascotas',
    'Cuidados diarios',
    1,
    ARRAY['HS-03']
) AS solicitud_c \gset

SELECT decision_id AS recepcion_c
FROM estado_actual_solicitud
WHERE id_solicitud = :solicitud_c \gset

SELECT registrar_actividad(
    '09000000-0000-0000-0000-000000000002',
    :solicitud_c,
    '2026-10-08 10:00',
    1,
    'ENTREVISTA',
    'Entrevista favorable',
    'Valoracion ficticia del hogar'
) AS entrevista_c \gset

SELECT decidir_solicitud(
    '09000000-0000-0000-0000-000000000003',
    :solicitud_c,
    :recepcion_c,
    '2026-10-08 11:00',
    1,
    'APROBADA',
    'Condiciones generales adecuadas'
) AS aprobacion_c \gset

SELECT evaluar_compatibilidad(
    '09000000-0000-0000-0000-000000000004',
    :solicitud_c,
    'HS-03',
    3,
    '2026-10-08 12:00',
    1,
    'FAVORABLE',
    'Hogar compatible con el animal',
    'Valoracion favorable del hogar',
    'Escenario de prueba de restriccion',
    :entrevista_c
) AS compatibilidad_c \gset

COMMIT;

SELECT * FROM huellas.estado_actual_solicitud;

SELECT *
FROM huellas.compatibilidad_animal_hogar
WHERE animal_codigo = 'HS-03';

\echo PREPARACION COMPLETADA
\echo Solicitud restringida: :solicitud_c
\echo Estancia HS-03: :estancia_c
