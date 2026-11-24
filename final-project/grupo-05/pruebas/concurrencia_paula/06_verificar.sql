\set ON_ERROR_STOP on
SET search_path=huellas,pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
DO $$ DECLARE v_id bigint; v_actual bigint; v_recepcion bigint;
BEGIN
    SELECT id_solicitud,decision_id INTO STRICT v_id,v_actual FROM estado_actual_solicitud
        WHERE clave_operacion='050c0000-0000-0000-0000-000000000001' AND estado='APROBADA' AND responsable_id=1;
    IF (SELECT count(*) FROM evento_solicitud WHERE solicitud_id=v_id)<>2
       OR EXISTS (SELECT FROM evento_solicitud WHERE clave_operacion='050c0000-0000-0000-0000-000000000004') THEN
        RAISE EXCEPTION 'C-P01: historia o exclusión de B incorrectas';
    END IF;
    SELECT id_evento_solicitud INTO STRICT v_recepcion FROM evento_solicitud
        WHERE solicitud_id=v_id AND tipo_evento='RECEPCION';
    -- Reenvío ciego del COMMIT perdido: no duplica. Se consulta primero su clave.
    IF NOT EXISTS (SELECT FROM evento_solicitud WHERE clave_operacion='050c0000-0000-0000-0000-000000000003'
        AND id_evento_solicitud=v_actual) THEN RAISE EXCEPTION 'C-P03: falta la decisión confirmada'; END IF;
    BEGIN
        PERFORM decidir_solicitud('050c0000-0000-0000-0000-000000000003',v_id,v_recepcion,
            '2026-10-12 09:00',1,'APROBADA','Decisión concurrente A');
        RAISE EXCEPTION 'C-P03: reenvío ciego aceptado';
    EXCEPTION WHEN SQLSTATE 'P2021' THEN RAISE NOTICE 'C-P03 reintento sin efectos: % %',SQLSTATE,SQLERRM;
    END;
    -- Una nueva decisión informada preserva A como antecedente; no sobrescribe.
    PERFORM decidir_solicitud('050c0000-0000-0000-0000-000000000007',v_id,v_actual,
        '2026-10-12 11:00',7,'PENDIENTE_INFORMACION','Revisión informada posterior al conflicto');
    IF (SELECT count(*) FROM evento_solicitud WHERE solicitud_id=v_id)<>3 THEN
        RAISE EXCEPTION 'C-P03: se perdió una decisión';
    END IF;
    SELECT id_solicitud INTO STRICT v_id FROM estado_actual_solicitud
        WHERE clave_operacion='050c0000-0000-0000-0000-000000000002' AND estado='RECHAZADA' AND responsable_id=7;
    IF (SELECT count(*) FROM evento_solicitud WHERE solicitud_id=v_id)<>2
       OR EXISTS (SELECT FROM evento_solicitud WHERE clave_operacion='050c0000-0000-0000-0000-000000000005') THEN
        RAISE EXCEPTION 'C-P02: efectos de A revertida o decisión de B incorrectos';
    END IF;
END $$;
-- El DO anterior se confirma por autocommit; lectura posterior en nueva sentencia.
SELECT e.solicitud_id,e.id_evento_solicitud,e.antecedente_decision_id,e.fecha,e.estado_resultante,e.responsable_id,e.razon
FROM evento_solicitud e JOIN solicitud_adopcion s ON s.id_solicitud=e.solicitud_id
WHERE s.clave_operacion IN ('050c0000-0000-0000-0000-000000000001','050c0000-0000-0000-0000-000000000002')
ORDER BY e.solicitud_id,e.fecha,e.id_evento_solicitud;
SELECT id_solicitud,estado,decision_id FROM estado_actual_solicitud
WHERE clave_operacion IN ('050c0000-0000-0000-0000-000000000001','050c0000-0000-0000-0000-000000000002');
