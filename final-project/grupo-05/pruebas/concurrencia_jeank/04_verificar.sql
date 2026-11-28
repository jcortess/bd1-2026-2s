\set ON_ERROR_STOP on

SELECT
    id_reserva,
    solicitud_id,
    animal_codigo,
    ingreso_id,
    fecha_reserva,
    fecha_fin_reserva
FROM huellas.reserva
WHERE animal_codigo = 'HS-01';

SELECT
    id_compatibilidad,
    solicitud_id,
    animal_codigo,
    resultado
FROM huellas.compatibilidad_animal_hogar
WHERE animal_codigo = 'HS-01'
ORDER BY solicitud_id;

DO $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM huellas.reserva
        WHERE animal_codigo = 'HS-01'
          AND fecha_fin_reserva IS NULL
    ) <> 1 THEN
        RAISE EXCEPTION
            'FALLO: debe existir una sola reserva vigente';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM huellas.reserva
        WHERE animal_codigo = 'HS-01'
          AND solicitud_id = 1
          AND ingreso_id = 1
          AND fecha_fin_reserva IS NULL
    ) THEN
        RAISE EXCEPTION
            'FALLO: no se conserva la reserva de A';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM huellas.reserva
        WHERE animal_codigo = 'HS-01'
          AND solicitud_id = 2
    ) THEN
        RAISE EXCEPTION
            'FALLO: la sesion B dejo una reserva';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM huellas.compatibilidad_animal_hogar
        WHERE animal_codigo = 'HS-01'
          AND ingreso_id = 1
          AND solicitud_id IN (1, 2)
          AND resultado = 'FAVORABLE'
    ) <> 2 THEN
        RAISE EXCEPTION
            'FALLO: no se conservaron las compatibilidades';
    END IF;

    RAISE NOTICE
        'PJ-10: VERIFICACION FINAL SUPERADA';
END;
$$;