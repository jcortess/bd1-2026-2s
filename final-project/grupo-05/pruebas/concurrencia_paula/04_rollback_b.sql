\set ON_ERROR_STOP on
SET application_name='huellas_g05_paula_rollback_b';
SET search_path=huellas,pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_backend_pid() AS pid_b,id_solicitud AS solicitud,decision_id AS antecedente FROM estado_actual_solicitud
    WHERE clave_operacion='050c0000-0000-0000-0000-000000000002' \gset
SELECT decidir_solicitud('050c0000-0000-0000-0000-000000000006',:solicitud,:antecedente,
    '2026-10-12 10:00',7,'RECHAZADA','Decisión B confirmada después del ROLLBACK de A');
COMMIT;
SELECT id_solicitud,decision_id,estado FROM estado_actual_solicitud
    WHERE clave_operacion='050c0000-0000-0000-0000-000000000002';
