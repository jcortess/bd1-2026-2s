\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path = huellas, pg_catalog;
SET LOCAL TIME ZONE 'America/Costa_Rica';

SELECT id_adopcion AS adopcion_origen
FROM adopcion
WHERE animal_codigo = 'HS-01'
  AND ingreso_id = 1
  AND fecha_finalizacion IS NULL
\gset

UPDATE adopcion
SET tipo_finalizacion = 'DEVOLUCION_VOLUNTARIA',
    fecha_finalizacion = '2026-10-10 09:00:00-06'
WHERE id_adopcion = :adopcion_origen;

INSERT INTO ingreso (
    animal_codigo,
    fecha_ingreso,
    lugar_ingreso,
    condicion_general,
    circunstancia_ingreso,
    detalle_circunstancia,
    adopcion_origen_id,
    receptor_devolucion_id
)
VALUES (
    'HS-01',
    '2026-10-10 09:30:00-06',
    'Recepcion del refugio',
    'Animal alerta y estable',
    'DEVOLUCION',
    'Devolucion voluntaria por circunstancias familiares',
    :adopcion_origen,
    1
)
RETURNING id_ingreso AS nuevo_ingreso \gset

INSERT INTO evaluacion_salud (
    animal_codigo,
    ingreso_id,
    tipo_evaluacion,
    fecha_evaluacion,
    observaciones
)
VALUES (
    'HS-01',
    :nuevo_ingreso,
    'INICIAL',
    '2026-10-10 09:30:00-06',
    'Evaluacion inicial posterior a la devolucion'
);

COMMIT;

SET search_path = huellas, pg_catalog;

SELECT id_adopcion,
       animal_codigo,
       tipo_finalizacion,
       fecha_finalizacion
FROM adopcion
WHERE animal_codigo = 'HS-01';

SELECT id_ingreso,
       animal_codigo,
       circunstancia_ingreso,
       adopcion_origen_id,
       fecha_cierre
FROM ingreso
WHERE animal_codigo = 'HS-01';

SELECT *
FROM restriccion_persona
WHERE persona_afectada_id = 101;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM restriccion_persona
        WHERE persona_afectada_id = 101
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-09: se genero una restriccion';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM ingreso i
        JOIN adopcion a
          ON a.id_adopcion = i.adopcion_origen_id
        JOIN evaluacion_salud e
          ON e.ingreso_id = i.id_ingreso
         AND e.animal_codigo = i.animal_codigo
        WHERE i.animal_codigo = 'HS-01'
          AND i.circunstancia_ingreso = 'DEVOLUCION'
          AND i.fecha_cierre IS NULL
          AND a.tipo_finalizacion = 'DEVOLUCION_VOLUNTARIA'
          AND e.tipo_evaluacion = 'INICIAL'
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-09: reingreso inconsistente';
    END IF;

    RAISE NOTICE 'PJ-09: SUPERADA';
END;
$$;