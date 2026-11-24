\set ON_ERROR_STOP on
-- Tercera conexión, mientras A está pausada y B ejecutando.
SELECT a.pid AS pid_a,a.application_name AS sesion_a,a.state AS estado_a,
    b.pid AS pid_b,b.application_name AS sesion_b,b.state AS estado_b,b.wait_event_type,b.wait_event,
    pg_blocking_pids(b.pid) AS bloqueadores,a.pid=ANY(pg_blocking_pids(b.pid)) AS a_bloquea_b
FROM pg_stat_activity a JOIN pg_stat_activity b ON a.datname=b.datname
WHERE a.datname=current_database() AND a.application_name LIKE 'huellas_g05_paula_%_a'
    AND b.application_name=left(a.application_name,length(a.application_name)-1)||'b';
