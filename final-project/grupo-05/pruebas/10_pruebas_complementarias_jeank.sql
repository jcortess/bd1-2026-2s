\set ON_ERROR_STOP on

SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';

\echo ==== PRUEBAS COMPLEMENTARIAS JEANK ====

-- PJ-03: Persona con restriccion vigente.

BEGIN;

SET LOCAL ROLE huellas_g05_operador;

DO $$
BEGIN
    PERFORM registrar_reserva(
        '20000000-0000-0000-0000-000000000001',
        3,
        'HS-03',
        3,
        '2026-10-08 13:00:00-06',
        1
    );

    RAISE EXCEPTION
        'FALLO PJ-03: reserva aceptada';

EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM =
            'La persona tiene una restriccion vigente documentada'
        THEN
            RAISE NOTICE
                'PJ-03: SUPERADA - % - SQLSTATE: %',
                SQLERRM, SQLSTATE;
        ELSE
            RAISE;
        END IF;
END;
$$;

ROLLBACK;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM reserva
        WHERE solicitud_id = 3
          AND animal_codigo = 'HS-03'
    ) THEN
        RAISE EXCEPTION
            'FALLO PJ-03: quedaron efectos parciales';
    END IF;

    RAISE NOTICE
        'PJ-03: SIN EFECTOS PARCIALES';
END;
$$;

SELECT *
FROM restriccion_persona
WHERE persona_afectada_id = 103;

\echo ==== FIN DE PRUEBA DE RESTRICCION ====