
\set ON_ERROR_STOP on

SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';

\echo ==== INTEGRIDAD FINAL JEANK ====

-- PC-06: Correccion de la anomalia A2.
-- Una indicacion no puede asociarse a otra evaluacion.

BEGIN;

DO $$
DECLARE
    v_restriccion text;
BEGIN
    INSERT INTO indicacion_diagnostico (
        indicacion_id,
        evaluacion_id,
        diagnostico_id
    )
    VALUES (2001, 1002, 2);

    RAISE EXCEPTION 'FALLO PC-06';

EXCEPTION
    WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS
            v_restriccion = CONSTRAINT_NAME;

        IF v_restriccion <>
            'indicacion_diagnostico_contexto_fk'
        THEN
            RAISE;
        END IF;

        RAISE NOTICE
            'PC-06: SUPERADA - SQLSTATE: % - Restriccion: %',
            SQLSTATE, v_restriccion;
END;
$$;

ROLLBACK;

-- PC-07: Asociacion dentro de la evaluacion correcta.

BEGIN;

INSERT INTO indicacion_diagnostico (
    indicacion_id,
    evaluacion_id,
    diagnostico_id
)
VALUES (2001, 1001, 2);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM indicacion_diagnostico
        WHERE indicacion_id = 2001
          AND evaluacion_id = 1001
          AND diagnostico_id = 2
    ) THEN
        RAISE EXCEPTION 'FALLO PC-07';
    END IF;

    RAISE NOTICE 'PC-07: SUPERADA';
END;
$$;

ROLLBACK;

-- PS-01: Seguimiento valido de una adopcion.

BEGIN;

INSERT INTO seguimiento_adopcion (
    adopcion_id,
    fecha_prevista,
    responsable_id,
    medio,
    estado_seguimiento
)
VALUES (
    2,
    '2026-10-12 09:00:00-06',
    1,
    'LLAMADA',
    'PENDIENTE'
)
RETURNING id_seguimiento AS seguimiento_a \gset

UPDATE seguimiento_adopcion
SET estado_seguimiento = 'REALIZADO',
    fecha_efectiva = '2026-10-12 09:30:00-06',
    resultado = 'Animal en buenas condiciones',
    acuerdo = 'Continuar seguimiento'
WHERE id_seguimiento = :seguimiento_a;

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM seguimiento_adopcion
        WHERE adopcion_id = 2
          AND estado_seguimiento = 'REALIZADO'
          AND fecha_efectiva IS NOT NULL
          AND resultado IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'FALLO PS-01';
    END IF;

    RAISE NOTICE 'PS-01: SUPERADA';
END;
$$;

-- PS-02: Seguimiento anterior a la adopcion.

BEGIN;

DO $$
BEGIN
    INSERT INTO seguimiento_adopcion (
        adopcion_id,
        fecha_prevista,
        responsable_id,
        medio,
        estado_seguimiento
    )
    VALUES (
        2,
        '2026-10-01 09:00:00-06',
        1,
        'LLAMADA',
        'PENDIENTE'
    );

    RAISE EXCEPTION 'FALLO PS-02';

EXCEPTION
    WHEN SQLSTATE 'P3045' THEN
        RAISE NOTICE 'PS-02: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PS-03: Proteger un seguimiento realizado.

BEGIN;

DO $$
BEGIN
    UPDATE seguimiento_adopcion
    SET resultado = 'Modificacion no permitida'
    WHERE adopcion_id = 2
      AND estado_seguimiento = 'REALIZADO';

    RAISE EXCEPTION 'FALLO PS-03';

EXCEPTION
    WHEN SQLSTATE 'P3042' THEN
        RAISE NOTICE 'PS-03: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PS-04: Reprogramacion valida.

BEGIN;

INSERT INTO seguimiento_adopcion (
    adopcion_id,
    fecha_prevista,
    responsable_id,
    medio,
    estado_seguimiento
)
VALUES (
    2,
    '2026-10-15 09:00:00-06',
    1,
    'VISITA',
    'PENDIENTE'
)
RETURNING id_seguimiento AS seguimiento_b \gset

UPDATE seguimiento_adopcion
SET estado_seguimiento = 'REPROGRAMADO'
WHERE id_seguimiento = :seguimiento_b;

INSERT INTO seguimiento_adopcion (
    adopcion_id,
    fecha_prevista,
    responsable_id,
    medio,
    estado_seguimiento,
    seguimiento_origen_id
)
VALUES (
    2,
    '2026-10-20 09:00:00-06',
    1,
    'VISITA',
    'PENDIENTE',
    :seguimiento_b
);

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM seguimiento_adopcion nuevo
        JOIN seguimiento_adopcion anterior
          ON anterior.id_seguimiento =
             nuevo.seguimiento_origen_id
        WHERE anterior.estado_seguimiento =
              'REPROGRAMADO'
          AND nuevo.estado_seguimiento =
              'PENDIENTE'
          AND nuevo.adopcion_id =
              anterior.adopcion_id
          AND nuevo.fecha_prevista >
              anterior.fecha_prevista
    ) THEN
        RAISE EXCEPTION 'FALLO PS-04';
    END IF;

    RAISE NOTICE 'PS-04: SUPERADA';
END;
$$;

-- PS-05: Reprogramacion asociada a otra adopcion.

BEGIN;

DO $$
DECLARE
    v_origen bigint;
BEGIN
    SELECT id_seguimiento
    INTO STRICT v_origen
    FROM seguimiento_adopcion
    WHERE adopcion_id = 2
      AND estado_seguimiento = 'REPROGRAMADO';

    INSERT INTO seguimiento_adopcion (
        adopcion_id,
        fecha_prevista,
        responsable_id,
        medio,
        estado_seguimiento,
        seguimiento_origen_id
    )
    VALUES (
        1,
        '2026-10-21 09:00:00-06',
        1,
        'VISITA',
        'PENDIENTE',
        v_origen
    );

    RAISE EXCEPTION 'FALLO PS-05';

EXCEPTION
    WHEN SQLSTATE 'P3048' THEN
        RAISE NOTICE 'PS-05: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- PP-01: El operador no puede modificar
-- directamente el historial clinico.

BEGIN;

SET LOCAL ROLE huellas_g05_operador;

DO $$
BEGIN
    UPDATE indicacion
    SET descripcion = 'Cambio directo no autorizado'
    WHERE id_indicacion = 2001;

    RAISE EXCEPTION 'FALLO PP-01';

EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'PP-01: SUPERADA - %', SQLERRM;
END;
$$;

ROLLBACK;

-- Estado final persistido.

SELECT * FROM indicacion_diagnostico
ORDER BY indicacion_id, diagnostico_id;

SELECT * FROM seguimiento_adopcion
ORDER BY id_seguimiento;

SELECT * FROM v_control_adopciones_jeank;

\echo ==== FIN DE INTEGRIDAD FINAL  ====
