
\set ON_ERROR_STOP on

SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';

\echo ==== PRUEBAS SECUENCIALES JEANK ====

-- PJ-01: Reserva valida.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

SELECT registrar_reserva(
    '19000000-0000-0000-0000-000000000001',
    1, 'HS-01', 1,
    '2026-10-07 13:00:00-06', 1
) AS reserva_a \gset

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM reserva
        WHERE solicitud_id = 1
          AND animal_codigo = 'HS-01'
          AND fecha_fin_reserva IS NULL
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-01';
    END IF;

    RAISE NOTICE 'PJ-01: SUPERADA';
END;
$$;

-- PJ-02: Segunda reserva del mismo animal.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

DO $$
BEGIN
    PERFORM registrar_reserva(
        '19000000-0000-0000-0000-000000000002',
        2, 'HS-01', 1,
        '2026-10-07 13:30:00-06', 1
    );

    RAISE EXCEPTION 'FALLO PJ-02: reserva duplicada aceptada';

EXCEPTION
    WHEN SQLSTATE 'P3021' THEN
        RAISE NOTICE 'PJ-02: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PJ-04: Formalizacion correcta.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

SELECT formalizar_adopcion(
    '19000000-0000-0000-0000-000000000003',
    :reserva_a,
    1,
    '2026-10-07 14:00:00-06',
    'Condiciones de cuidado aceptadas',
    1,
    ARRAY[101]::bigint[]
) AS adopcion_a \gset

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM v_control_adopciones_jeank
        WHERE animal_codigo = 'HS-01'
          AND estado_integridad = 'CONSISTENTE'
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-04';
    END IF;

    RAISE NOTICE 'PJ-04: SUPERADA';
END;
$$;

-- PJ-05: Adopcion duplicada.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

DO $$
DECLARE
    v_reserva bigint;
BEGIN
    SELECT id_reserva INTO STRICT v_reserva
    FROM reserva
    WHERE animal_codigo = 'HS-01';

    PERFORM formalizar_adopcion(
        '19000000-0000-0000-0000-000000000004',
        v_reserva,
        1,
        '2026-10-07 14:30:00-06',
        'Segundo intento de adopcion',
        1,
        ARRAY[101]::bigint[]
    );

    RAISE EXCEPTION 'FALLO PJ-05';

EXCEPTION
    WHEN SQLSTATE 'P3017' THEN
        RAISE NOTICE 'PJ-05: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PJ-06: Ingreso que no corresponde al animal.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

DO $$
BEGIN
    PERFORM registrar_reserva(
        '19000000-0000-0000-0000-000000000005',
        1, 'HS-02', 3,
        '2026-10-07 15:00:00-06', 1
    );

    RAISE EXCEPTION 'FALLO PJ-06';

EXCEPTION
    WHEN SQLSTATE 'P2025' THEN
        RAISE NOTICE 'PJ-06: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PJ-07: Adopciones individuales de una solicitud.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

SELECT registrar_reserva(
    '19000000-0000-0000-0000-000000000006',
    1, 'HS-02', 2,
    '2026-10-07 15:00:00-06', 1
) AS reserva_b \gset

SELECT formalizar_adopcion(
    '19000000-0000-0000-0000-000000000007',
    :reserva_b,
    2,
    '2026-10-07 16:00:00-06',
    'Condiciones de cuidado aceptadas',
    1,
    ARRAY[101]::bigint[]
);

COMMIT;

DO $$
BEGIN
    IF (
        SELECT count(*)
        FROM adopcion
        WHERE solicitud_id = 1
    ) <> 2 THEN
        RAISE EXCEPTION 'FALLO PJ-07';
    END IF;

    IF (
        SELECT count(*)
        FROM v_control_adopciones_jeank
        WHERE estado_integridad = 'CONSISTENTE'
    ) <> 2 THEN
        RAISE EXCEPTION 'FALLO PJ-07: cierre inconsistente';
    END IF;

    RAISE NOTICE 'PJ-07: SUPERADA';
END;
$$;

-- PJ-08: Resultados incompatibles.

BEGIN;

DO $$
BEGIN
    INSERT INTO resultado_etapa (
        ingreso_id,
        tipo_resultado,
        fecha,
        circunstancias,
        responsable_id
    )
    VALUES (
        1,
        'FALLECIMIENTO',
        '2026-10-07 14:00:00-06',
        'Prueba ficticia de resultado incompatible',
        1
    );

    RAISE EXCEPTION 'FALLO PJ-08';

EXCEPTION
    WHEN SQLSTATE 'P3022' THEN
        RAISE NOTICE 'PJ-08: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PC-01: Estado de aplicaciones clinicas.

DO $$
BEGIN
    IF estado_aplicacion(3001)
        IS DISTINCT FROM 'REALIZADA' THEN
        RAISE EXCEPTION 'FALLO PC-01';
    END IF;

    RAISE NOTICE 'PC-01: SUPERADA';
END;
$$;

-- PC-02: Impedir modificar una aplicacion realizada.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

DO $$
BEGIN
    CALL registrar_aplicacion(
        3001,
        '2026-10-05 12:00:00-06',
        7,
        'Segundo intento de registro'
    );

    RAISE EXCEPTION 'FALLO PC-02';

EXCEPTION
    WHEN SQLSTATE 'P3005' THEN
        RAISE NOTICE 'PC-02: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PC-03: Fecha planificada anterior a la evaluacion.

BEGIN;

DO $$
BEGIN
    INSERT INTO aplicacion_indicacion (
        indicacion_id,
        fecha_planificada
    )
    VALUES (
        2001,
        '2026-01-01 08:00:00-06'
    );

    RAISE EXCEPTION 'FALLO PC-03';

EXCEPTION
    WHEN SQLSTATE 'P3008' THEN
        RAISE NOTICE 'PC-03: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PC-04: Aplicacion sin responsable.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

DO $$
BEGIN
    CALL registrar_aplicacion(
        3002,
        '2026-10-07 10:00:00-06',
        NULL,
        'Prueba sin responsable'
    );

    RAISE EXCEPTION 'FALLO PC-04';

EXCEPTION
    WHEN SQLSTATE 'P3011' THEN
        RAISE NOTICE 'PC-04: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PC-05: Registro valido de una aplicacion.

BEGIN;
SET LOCAL ROLE huellas_g05_operador;

CALL registrar_aplicacion(
    3002,
    '2026-10-07 10:00:00-06',
    7,
    'Control veterinario realizado'
);

COMMIT;

DO $$
BEGIN
    IF estado_aplicacion(3002)
        IS DISTINCT FROM 'REALIZADA' THEN
        RAISE EXCEPTION 'FALLO PC-05';
    END IF;

    RAISE NOTICE 'PC-05: SUPERADA';
END;
$$;

-- Resultados persistidos.

SELECT * FROM v_control_adopciones_jeank;

SELECT id_aplicacion,
       estado_aplicacion(id_aplicacion) AS estado
FROM aplicacion_indicacion
ORDER BY id_aplicacion;

\echo ==== FIN DEL PRIMER BLOQUE SECUENCIAL ====
