\set ON_ERROR_STOP on
SET application_name='huellas_g05_paula_commit_b';
SET search_path=huellas,pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_backend_pid() AS pid_b,id_solicitud,decision_id,estado FROM estado_actual_solicitud
    WHERE clave_operacion='050c0000-0000-0000-0000-000000000001';
DO $$ DECLARE v_solicitud bigint; v_antecedente bigint;
BEGIN
    SELECT id_solicitud,decision_id INTO STRICT v_solicitud,v_antecedente FROM estado_actual_solicitud
        WHERE clave_operacion='050c0000-0000-0000-0000-000000000001';
    PERFORM decidir_solicitud('050c0000-0000-0000-0000-000000000004',v_solicitud,v_antecedente,
        '2026-10-12 10:00',7,'RECHAZADA','Decisión concurrente B basada en lectura anterior');
    RAISE EXCEPTION 'C-P01: B debía detectar antecedente desactualizado';
EXCEPTION WHEN SQLSTATE 'P2021' THEN RAISE NOTICE 'C-P01 rechazo real: % %',SQLSTATE,SQLERRM;
END $$;
COMMIT;
SELECT id_solicitud,decision_id,estado FROM estado_actual_solicitud
    WHERE clave_operacion='050c0000-0000-0000-0000-000000000001';
