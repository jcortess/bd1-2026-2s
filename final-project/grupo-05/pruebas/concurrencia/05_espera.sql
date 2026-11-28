\set ON_ERROR_STOP on
-- Ejecutar desde una tercera conexión con -v caso=cupo o -v caso=animal.
SELECT a.pid AS pid_a, a.state AS estado_a, b.pid AS pid_b, b.state AS estado_b,
       b.wait_event_type, b.wait_event, pg_blocking_pids(b.pid) AS bloqueadores,
       a.pid = ANY (pg_blocking_pids(b.pid)) AS a_bloquea_b
FROM pg_stat_activity a
CROSS JOIN pg_stat_activity b
WHERE a.datname = current_database() AND b.datname = a.datname
  AND a.application_name = 'huellas_g05_' || :'caso' || '_a'
  AND b.application_name = 'huellas_g05_' || :'caso' || '_b';
