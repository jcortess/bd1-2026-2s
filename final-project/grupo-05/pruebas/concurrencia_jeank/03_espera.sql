\set ON_ERROR_STOP on

SELECT
    pid,
    application_name,
    state,
    wait_event_type,
    wait_event,
    pg_blocking_pids(pid) AS bloqueadores
FROM pg_stat_activity
WHERE datname = current_database()
  AND application_name IN (
      'jeank_reserva_a',
      'jeank_reserva_b'
  )
ORDER BY application_name;

SELECT
    a.pid AS pid_a,
    b.pid AS pid_b,
    a.pid = ANY(pg_blocking_pids(b.pid))
        AS a_bloquea_b
FROM pg_stat_activity a
CROSS JOIN pg_stat_activity b
WHERE a.datname = current_database()
  AND b.datname = current_database()
  AND a.application_name = 'jeank_reserva_a'
  AND b.application_name = 'jeank_reserva_b';