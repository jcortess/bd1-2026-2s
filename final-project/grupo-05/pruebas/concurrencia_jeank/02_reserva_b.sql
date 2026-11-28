\set ON_ERROR_STOP on

SET application_name = 'jeank_reserva_b';

SELECT pg_backend_pid() AS pid_b;

BEGIN ISOLATION LEVEL READ COMMITTED;

SET LOCAL ROLE huellas_g05_operador;

\echo SESION B: INTENTANDO RESERVAR HS-01

DO $$
BEGIN
    BEGIN
        PERFORM huellas.registrar_reserva(
            '13000000-0000-0000-0000-000000000002',
            2,
            'HS-01',
            1,
            '2026-10-07 13:00:00-06',
            1
        );

        RAISE EXCEPTION
            'FALLO: la segunda reserva fue aceptada';

    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM = 'El animal ya tiene una reserva vigente' THEN
                RAISE NOTICE
                    'RECHAZO ESPERADO: % - SQLSTATE: %',
                    SQLERRM, SQLSTATE;
            ELSE
                RAISE;
            END IF;
    END;
END;
$$;

ROLLBACK;

\echo SESION B: PRUEBA FINALIZADA