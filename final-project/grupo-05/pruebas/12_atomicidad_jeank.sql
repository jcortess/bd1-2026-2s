
\set ON_ERROR_STOP on

SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';

\echo ==== PRUEBA DE ATOMICIDAD JEANK ====

-- Crear una reserva valida.
-- La persona 101 realizo anteriormente una
-- devolucion voluntaria.

BEGIN;

SET LOCAL ROLE huellas_g05_operador;

SELECT registrar_reserva(
    '21000000-0000-0000-0000-000000000001',
    4,
    'HS-03',
    3,
    '2026-10-11 13:00:00-06',
    1
) AS reserva_atomicidad \gset

COMMIT;

\echo RESERVA CREADA: :reserva_atomicidad

-- Verificar que la devolucion voluntaria
-- no impide realizar una nueva reserva.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM reserva
        WHERE solicitud_id = 4
          AND animal_codigo = 'HS-03'
          AND ingreso_id = 3
          AND fecha_fin_reserva IS NULL
    ) THEN
        RAISE EXCEPTION
            'FALLO: no existe la reserva esperada';
    END IF;

    RAISE NOTICE
        'PJ-09 COMPLEMENTARIA: NUEVA RESERVA PERMITIDA';
END;
$$;

-- Estado anterior al intento fallido.

\echo ==== ESTADO ANTERIOR ====

SELECT *
FROM reserva
WHERE animal_codigo = 'HS-03';

SELECT id_ingreso, animal_codigo, fecha_cierre
FROM ingreso
WHERE id_ingreso = 3;

SELECT id_estancia, ingreso_id, fecha_fin_real
FROM estancia
WHERE ingreso_id = 3;

-- PJ-11: Intentar formalizar la adopcion
-- utilizando una estancia incorrecta.

BEGIN;

SET LOCAL ROLE huellas_g05_operador;

DO $$
DECLARE
    v_reserva bigint;
BEGIN
    SELECT id_reserva
    INTO STRICT v_reserva
    FROM reserva
    WHERE clave_operacion =
        '21000000-0000-0000-0000-000000000001';

    PERFORM formalizar_adopcion(
        '21000000-0000-0000-0000-000000000002',
        v_reserva,
        1,
        '2026-10-11 14:00:00-06',
        'Condiciones de cuidado aceptadas',
        1,
        ARRAY[101]::bigint[]
    );

    RAISE EXCEPTION
        'FALLO PJ-11: adopcion incorrecta aceptada';

EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM =
            'La estancia vigente difiere de la esperada'
        THEN
            RAISE NOTICE
                'PJ-11: RECHAZO ESPERADO - % - SQLSTATE: %',
                SQLERRM, SQLSTATE;
        ELSE
            RAISE;
        END IF;
END;
$$;

ROLLBACK;

-- Verificar que no quedaron efectos parciales.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM adopcion
        WHERE ingreso_id = 3
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-11: quedo una adopcion parcial';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM adopcion_responsable ar
        LEFT JOIN adopcion a
          ON a.id_adopcion = ar.adopcion_id
        WHERE a.id_adopcion IS NULL
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-11: responsable sin adopcion';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM reserva
        WHERE clave_operacion =
            '21000000-0000-0000-0000-000000000001'
          AND fecha_fin_reserva IS NULL
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-11: la reserva fue alterada';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM ingreso
        WHERE id_ingreso = 3
          AND fecha_cierre IS NULL
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-11: el ingreso fue cerrado';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM estancia
        WHERE id_estancia = 3
          AND ingreso_id = 3
          AND fecha_fin_real IS NULL
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-11: la estancia fue alterada';
    END IF;

    RAISE NOTICE
        'PJ-11: SUPERADA - SIN EFECTOS PARCIALES';
END;
$$;

\echo ==== ESTADO POSTERIOR AL RECHAZO ====

SELECT *
FROM reserva
WHERE animal_codigo = 'HS-03';

SELECT id_ingreso, animal_codigo, fecha_cierre
FROM ingreso
WHERE id_ingreso = 3;

SELECT id_estancia, ingreso_id, fecha_fin_real
FROM estancia
WHERE ingreso_id = 3;

SELECT *
FROM adopcion
WHERE ingreso_id = 3;

-- Reintentar utilizando la estancia correcta.

BEGIN;

SET LOCAL ROLE huellas_g05_operador;

SELECT formalizar_adopcion(
    '21000000-0000-0000-0000-000000000003',
    :reserva_atomicidad,
    3,
    '2026-10-11 14:00:00-06',
    'Condiciones de cuidado aceptadas',
    1,
    ARRAY[101]::bigint[]
) AS adopcion_atomicidad \gset

COMMIT;

-- Comprobar el cierre consistente.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM v_control_adopciones_jeank
        WHERE animal_codigo = 'HS-03'
          AND ingreso_id = 3
          AND estado_integridad = 'CONSISTENTE'
    ) THEN
        RAISE EXCEPTION
            'FALLO: adopcion final inconsistente';
    END IF;

    RAISE NOTICE
        'PJ-11: REINTENTO CORRECTO SUPERADO';
END;
$$;

\echo ==== ESTADO FINAL ====

SELECT *
FROM v_control_adopciones_jeank
ORDER BY id_adopcion;

SELECT *
FROM adopcion_responsable
ORDER BY adopcion_id, persona_id;

SELECT id_estancia, ingreso_id, fecha_fin_real
FROM estancia
WHERE ingreso_id = 3;

\echo ==== FIN DE PRUEBA DE ATOMICIDAD ====
