\set ON_ERROR_STOP on

SET application_name = 'jeank_reserva_a';

SELECT pg_backend_pid() AS pid_a;

BEGIN ISOLATION LEVEL READ COMMITTED;

SET LOCAL ROLE huellas_g05_operador;

SELECT huellas.registrar_reserva(
    '13000000-0000-0000-0000-000000000001',
    1,
    'HS-01',
    1,
    '2026-10-07 13:00:00-06',
    1
) AS reserva_a;

\echo SESION A: RESERVA REGISTRADA SIN COMMIT

\prompt 'Presione ENTER cuando se confirme el bloqueo de B: ' continuar

COMMIT;

\echo SESION A: COMMIT EXITOSO