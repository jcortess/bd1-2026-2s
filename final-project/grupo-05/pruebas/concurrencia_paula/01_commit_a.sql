\set ON_ERROR_STOP on
SET application_name='huellas_g05_paula_commit_a';
SET search_path=huellas,pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE huellas_g05_operador;
SELECT id_solicitud AS solicitud,decision_id AS antecedente FROM estado_actual_solicitud
    WHERE clave_operacion='050c0000-0000-0000-0000-000000000001' \gset
SELECT pg_backend_pid() AS pid_a,decidir_solicitud('050c0000-0000-0000-0000-000000000003',
    :solicitud,:antecedente,'2026-10-12 09:00',1,'APROBADA','Decisión concurrente A') AS decision_a;
\echo PAULA_A_LISTA
\prompt 'Compruebe B esperando desde otra sesión; pulse Intro para COMMIT de A: ' confirmar
COMMIT;
