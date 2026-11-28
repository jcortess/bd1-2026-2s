
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path = huellas, pg_catalog;

-- ============================================================
-- HUELLAS SEGURAS - GRUPO 05
-- CONSULTAS 
-- ============================================================

-- 1. INDICACIONES VETERINARIAS

CREATE VIEW v_indicaciones_jeank AS
SELECT
    i.id_indicacion,
    e.animal_codigo,
    e.id_evaluacion,
    e.fecha_evaluacion,
    i.tipo_indicacion,
    i.descripcion,
    i.estado_indicacion,
    i.indicacion_sustituida_id
FROM indicacion i
JOIN evaluacion_salud e
    ON e.id_evaluacion = i.evaluacion_id;


-- 2. ESTADO DE APLICACIONES VETERINARIAS

CREATE VIEW v_aplicaciones_jeank AS
SELECT
    a.id_aplicacion,
    a.indicacion_id,
    e.animal_codigo,
    i.descripcion,
    a.fecha_planificada,
    a.fecha_real,
    a.responsable_id,
    a.observaciones,
    estado_aplicacion(a.id_aplicacion) AS estado
FROM aplicacion_indicacion a
JOIN indicacion i
    ON i.id_indicacion = a.indicacion_id
JOIN evaluacion_salud e
    ON e.id_evaluacion = i.evaluacion_id;


-- 3. REPORTE DE APLICACIONES PENDIENTES

CREATE FUNCTION generar_reporte_pendientes()
RETURNS TABLE (
    id_aplicacion bigint,
    animal_codigo text,
    descripcion text,
    fecha_planificada timestamptz,
    estado text
)
LANGUAGE sql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
    SELECT
        a.id_aplicacion,
        a.animal_codigo::text,
        a.descripcion::text,
        a.fecha_planificada::timestamptz,
        a.estado
    FROM v_aplicaciones_jeank a
    WHERE a.fecha_real IS NULL
    ORDER BY a.fecha_planificada, a.id_aplicacion;
$$;


-- 4. HISTORIAL DE RESERVAS

CREATE VIEW v_reservas_jeank AS
SELECT
    r.id_reserva,
    r.clave_operacion,
    r.solicitud_id,
    r.animal_codigo,
    r.ingreso_id,
    r.compatibilidad_id,
    r.fecha_reserva,
    r.fecha_fin_reserva,
    r.responsable_id,
    CASE
        WHEN a.id_adopcion IS NOT NULL
            THEN 'FORMALIZADA'
        WHEN r.fecha_fin_reserva IS NULL
            THEN 'VIGENTE'
        ELSE 'FINALIZADA'
    END AS estado_reserva
FROM reserva r
LEFT JOIN adopcion a
    ON a.reserva_id = r.id_reserva;


-- 5. RESERVAS VIGENTES

CREATE VIEW v_reservas_vigentes_jeank AS
SELECT *
FROM v_reservas_jeank
WHERE estado_reserva = 'VIGENTE';


-- 6. ADOPCIONES FORMALIZADAS

CREATE VIEW v_adopciones_jeank AS
SELECT
    a.id_adopcion,
    a.clave_operacion,
    a.reserva_id,
    a.solicitud_id,
    a.animal_codigo,
    a.ingreso_id,
    a.fecha_entrega,
    a.condiciones_aceptadas,
    a.responsable_entrega_id,
    a.tipo_finalizacion,
    a.fecha_finalizacion,
    i.fecha_cierre AS cierre_ingreso,
    CASE
        WHEN a.fecha_finalizacion IS NULL
            THEN 'ACTIVA'
        ELSE 'FINALIZADA'
    END AS estado_adopcion
FROM adopcion a
JOIN ingreso i
    ON i.id_ingreso = a.ingreso_id;


-- 7. RESPONSABLES POR ADOPCION

CREATE VIEW v_responsables_adopcion_jeank AS
SELECT
    a.id_adopcion,
    a.animal_codigo,
    a.fecha_entrega,
    COUNT(r.persona_id) AS cantidad_responsables,
    ARRAY_AGG(
        r.persona_id ORDER BY r.persona_id
    ) FILTER (
        WHERE r.persona_id IS NOT NULL
    ) AS responsables
FROM adopcion a
LEFT JOIN adopcion_responsable r
    ON r.adopcion_id = a.id_adopcion
GROUP BY
    a.id_adopcion,
    a.animal_codigo,
    a.fecha_entrega;


-- 8. RESTRICCIONES DOCUMENTADAS

CREATE VIEW v_restricciones_jeank AS
SELECT
    id_restriccion,
    persona_afectada_id,
    motivo,
    fecha_inicio,
    fecha_fin,
    responsable_decision_id,
    CASE
        WHEN fecha_inicio > CURRENT_TIMESTAMP
            THEN 'PROGRAMADA'
        WHEN fecha_fin IS NULL
            OR fecha_fin > CURRENT_TIMESTAMP
            THEN 'VIGENTE'
        ELSE 'FINALIZADA'
    END AS estado_restriccion
FROM restriccion_persona;


-- 9. SEGUIMIENTOS DE ADOPCION

CREATE VIEW v_seguimientos_jeank AS
SELECT
    s.id_seguimiento,
    s.adopcion_id,
    a.animal_codigo,
    s.fecha_prevista,
    s.fecha_efectiva,
    s.responsable_id,
    s.medio,
    s.resultado,
    s.acuerdo,
    s.estado_seguimiento,
    s.seguimiento_origen_id,
    CASE
        WHEN s.estado_seguimiento = 'PENDIENTE'
            AND s.fecha_prevista < CURRENT_TIMESTAMP
            THEN 'VENCIDO'
        ELSE s.estado_seguimiento
    END AS estado_consulta
FROM seguimiento_adopcion s
JOIN adopcion a
    ON a.id_adopcion = s.adopcion_id;


-- 10. RESULTADOS DE ETAPAS

CREATE VIEW v_resultados_etapa_jeank AS
SELECT
    i.id_ingreso,
    i.animal_codigo,
    i.fecha_ingreso,
    i.fecha_cierre,
    CASE
        WHEN a.id_adopcion IS NOT NULL
            THEN 'ADOPCION'
        WHEN r.id_resultado IS NOT NULL
            THEN r.tipo_resultado
        WHEN i.fecha_cierre IS NULL
            THEN 'ETAPA_ABIERTA'
        ELSE 'CIERRE_SIN_RESULTADO'
    END AS resultado,
    a.id_adopcion,
    r.id_resultado
FROM ingreso i
LEFT JOIN adopcion a
    ON a.ingreso_id = i.id_ingreso
LEFT JOIN resultado_etapa r
    ON r.ingreso_id = i.id_ingreso;


-- 11. HISTORIAL DE REINGRESOS

CREATE VIEW v_reingresos_jeank AS
SELECT
    i.id_ingreso,
    i.animal_codigo,
    i.fecha_ingreso,
    i.circunstancia_ingreso,
    i.detalle_circunstancia,
    i.adopcion_origen_id,
    a.fecha_entrega,
    a.tipo_finalizacion,
    a.fecha_finalizacion,
    i.receptor_devolucion_id
FROM ingreso i
JOIN adopcion a
    ON a.id_adopcion = i.adopcion_origen_id;


-- 12. CONTROL DE CONSISTENCIA DE ADOPCIONES

CREATE VIEW v_control_adopciones_jeank AS
SELECT
    a.id_adopcion,
    a.animal_codigo,
    a.ingreso_id,
    a.fecha_entrega,
    i.fecha_cierre,
    r.fecha_fin_reserva,
    CASE
        WHEN i.fecha_cierre
            IS DISTINCT FROM a.fecha_entrega
            THEN 'ERROR_CIERRE_INGRESO'

        WHEN r.fecha_fin_reserva
            IS DISTINCT FROM a.fecha_entrega
            THEN 'ERROR_CIERRE_RESERVA'

        WHEN NOT EXISTS (
            SELECT 1
            FROM adopcion_responsable ar
            WHERE ar.adopcion_id = a.id_adopcion
        )
            THEN 'ERROR_SIN_RESPONSABLES'

        WHEN EXISTS (
            SELECT 1
            FROM resultado_etapa re
            WHERE re.ingreso_id = a.ingreso_id
        )
            THEN 'ERROR_RESULTADO_INCOMPATIBLE'

        WHEN EXISTS (
            SELECT 1
            FROM estancia es
            WHERE es.ingreso_id = a.ingreso_id
              AND es.fecha_fin_real IS NULL
        )
            THEN 'ERROR_ESTANCIA_ABIERTA'

        ELSE 'CONSISTENTE'
    END AS estado_integridad
FROM adopcion a
JOIN ingreso i
    ON i.id_ingreso = a.ingreso_id
JOIN reserva r
    ON r.id_reserva = a.reserva_id;


-- 13. PERMISOS DE CONSULTA

REVOKE ALL ON FUNCTION
    generar_reporte_pendientes()
FROM PUBLIC;

GRANT EXECUTE ON FUNCTION
    generar_reporte_pendientes()
TO huellas_g05_operador;

GRANT SELECT ON
    v_indicaciones_jeank,
    v_aplicaciones_jeank,
    v_reservas_jeank,
    v_reservas_vigentes_jeank,
    v_adopciones_jeank,
    v_responsables_adopcion_jeank,
    v_restricciones_jeank,
    v_seguimientos_jeank,
    v_resultados_etapa_jeank,
    v_reingresos_jeank,
    v_control_adopciones_jeank
TO huellas_g05_operador;

COMMIT;
