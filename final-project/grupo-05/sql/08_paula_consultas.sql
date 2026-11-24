\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = huellas, pg_catalog;

-- Validación de los antecedentes cargados antes de declarar la instalación lista.
DO $$ BEGIN
    IF EXISTS (SELECT FROM ingreso i WHERE NOT EXISTS (SELECT FROM evaluacion_salud e
        WHERE e.ingreso_id=i.id_ingreso AND e.tipo_evaluacion='INICIAL')) THEN
        RAISE EXCEPTION USING ERRCODE='P2013',MESSAGE='Instalación incompleta: ingreso sin evaluación inicial';
    END IF;
END $$;

CREATE VIEW estado_actual_solicitud AS
SELECT s.*,e.id_evento_solicitud AS decision_id,e.fecha AS fecha_decision,
    e.estado_resultante AS estado,e.responsable_id,e.razon,
    NOT EXISTS (SELECT FROM solicitud_animal a WHERE a.solicitud_id=s.id_solicitud) AS es_general
FROM solicitud_adopcion s
JOIN LATERAL (SELECT * FROM evento_solicitud WHERE solicitud_id=s.id_solicitud AND estado_resultante IS NOT NULL
    ORDER BY fecha DESC,id_evento_solicitud DESC LIMIT 1) e ON true;

CREATE VIEW historial_solicitud AS
SELECT e.*,s.solicitante_id,p.nombre_identificacion AS responsable
FROM evento_solicitud e JOIN solicitud_adopcion s ON s.id_solicitud=e.solicitud_id
JOIN persona p ON p.id_persona=e.responsable_id;

CREATE VIEW compatibilidad_vigente AS
SELECT DISTINCT ON (solicitud_id,animal_codigo,ingreso_id) *
FROM compatibilidad_animal_hogar
ORDER BY solicitud_id,animal_codigo,ingreso_id,fecha DESC,id_compatibilidad DESC;

CREATE VIEW contexto_compatibilidad AS
SELECT c.*,s.solicitante_id,s.informacion_vivienda,s.integrantes_hogar,s.experiencia_animales,s.condiciones_cuidado,
    e.tipo_evento AS tipo_actividad,e.resultado_actividad,e.observaciones AS observaciones_actividad,
    es.estado AS estado_solicitud,es.decision_id
FROM compatibilidad_animal_hogar c JOIN solicitud_adopcion s ON s.id_solicitud=c.solicitud_id
LEFT JOIN evento_solicitud e ON e.id_evento_solicitud=c.actividad_contexto_id
JOIN estado_actual_solicitud es ON es.id_solicitud=c.solicitud_id;

CREATE VIEW disponibilidad_actual AS
SELECT DISTINCT ON (animal_codigo,ingreso_id) * FROM cambio_disponibilidad
ORDER BY animal_codigo,ingreso_id,fecha DESC,id_cambio DESC;

-- Q01 de Lab03 adaptada: agrega ingreso, conserva iniciales sin diagnóstico.
CREATE VIEW historial_evaluaciones AS
SELECT e.id_evaluacion,e.animal_codigo,e.ingreso_id,e.fecha_evaluacion,e.tipo_evaluacion,
    e.veterinario_id,e.registro_veterinario_id,e.motivo,e.observaciones,e.peso,e.recomendaciones,
    coalesce(string_agg(d.nombre_estandarizado || ' (' || dr.estado_diagnostico || ')',
        ', ' ORDER BY d.nombre_estandarizado),'Sin diagnóstico') AS diagnosticos
FROM evaluacion_salud e LEFT JOIN diagnostico_revision dr ON dr.evaluacion_id=e.id_evaluacion
LEFT JOIN diagnostico d ON d.id_diagnostico=dr.diagnostico_id GROUP BY e.id_evaluacion;

-- Q03 de Lab03 conservada en su significado: cuenta apariciones confirmadas.
CREATE VIEW resumen_revisiones AS
SELECT a.codigo_interno,count(DISTINCT e.id_evaluacion) FILTER
    (WHERE e.tipo_evaluacion='REVISION_VETERINARIA') AS revisiones,
    count(dr.diagnostico_id) FILTER (WHERE dr.estado_diagnostico='CONFIRMADO') AS registros_confirmados
FROM animal a LEFT JOIN evaluacion_salud e ON e.animal_codigo=a.codigo_interno
LEFT JOIN diagnostico_revision dr ON dr.evaluacion_id=e.id_evaluacion GROUP BY a.codigo_interno;

-- Interfaz privada de consumo para P03. Verifica aprobación explícita + última
-- compatibilidad favorable de ESTA etapa; no reserva, no adopta ni decide disponibilidad.
CREATE FUNCTION _exigir_compatibilidad(p_solicitud bigint,p_animal text,p_ingreso bigint,p_fecha timestamptz)
RETURNS bigint LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_estado estado_actual_solicitud%ROWTYPE; v_compatibilidad compatibilidad_vigente%ROWTYPE;
BEGIN
    PERFORM _bloquear_alojamiento();
    PERFORM _contexto_solicitud_paula(p_solicitud,p_fecha);
    SELECT * INTO v_estado FROM estado_actual_solicitud WHERE id_solicitud=p_solicitud;
    IF v_estado.estado IS DISTINCT FROM 'APROBADA' OR v_estado.fecha_decision > p_fecha THEN
        RAISE EXCEPTION USING ERRCODE='P2024', MESSAGE='Se requiere una decisión general de aprobación válida';
    END IF;
    IF NOT EXISTS (SELECT FROM ingreso WHERE id_ingreso=p_ingreso AND animal_codigo=p_animal
        AND fecha_cierre IS NULL AND fecha_ingreso<=p_fecha) THEN
        RAISE EXCEPTION USING ERRCODE='P2025', MESSAGE='La adjudicación requiere la etapa abierta del animal indicado';
    END IF;
    SELECT * INTO v_compatibilidad FROM compatibilidad_vigente
        WHERE solicitud_id=p_solicitud AND animal_codigo=p_animal AND ingreso_id=p_ingreso;
    IF NOT FOUND OR v_compatibilidad.resultado<>'FAVORABLE' OR v_compatibilidad.fecha > p_fecha THEN
        RAISE EXCEPTION USING ERRCODE='P2026', MESSAGE='Interés o aprobación general no sustituyen compatibilidad favorable concreta vigente';
    END IF;
    RETURN v_compatibilidad.id_compatibilidad;
END $$;
REVOKE ALL ON FUNCTION _exigir_compatibilidad(bigint,text,bigint,timestamptz) FROM PUBLIC;
GRANT SELECT ON estado_actual_solicitud,historial_solicitud,compatibilidad_vigente,contexto_compatibilidad,
    disponibilidad_actual,historial_evaluaciones,resumen_revisiones TO huellas_g05_operador;
COMMIT;

SET TIME ZONE 'America/Costa_Rica';
SELECT * FROM huellas.estado_actual_solicitud ORDER BY id_solicitud;
SELECT solicitud_id,animal_codigo,fecha_interes FROM huellas.solicitud_animal ORDER BY solicitud_id,animal_codigo;
SELECT id_solicitud,solicitante_id,estado FROM huellas.estado_actual_solicitud WHERE es_general ORDER BY id_solicitud;
SELECT solicitud_id,fecha,id_evento_solicitud,tipo_evento,resultado_actividad,estado_resultante,responsable_id,razon
    FROM huellas.historial_solicitud ORDER BY solicitud_id,fecha,id_evento_solicitud;
SELECT * FROM huellas.contexto_compatibilidad ORDER BY solicitud_id,animal_codigo,fecha,id_compatibilidad;
SELECT anterior.id_solicitud AS rechazada,posterior.id_solicitud AS posterior,anterior.solicitante_id
    FROM huellas.estado_actual_solicitud anterior JOIN huellas.solicitud_adopcion posterior
        ON posterior.solicitante_id=anterior.solicitante_id AND posterior.fecha_solicitud>anterior.fecha_decision
    WHERE anterior.estado='RECHAZADA' ORDER BY anterior.id_solicitud,posterior.id_solicitud;
SELECT * FROM huellas.historial_evaluaciones WHERE animal_codigo='HS-01' ORDER BY fecha_evaluacion,id_evaluacion;
SELECT * FROM huellas.resumen_revisiones ORDER BY codigo_interno;
SELECT * FROM huellas.disponibilidad_actual ORDER BY animal_codigo,ingreso_id;
-- Consulta explícita del estado de integración: NULL hasta que Jean Carlos cree RESERVA.
SELECT to_regclass('huellas.reserva') AS relacion_reserva;
