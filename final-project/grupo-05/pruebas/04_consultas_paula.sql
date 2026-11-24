\set ON_ERROR_STOP on
SET TIME ZONE 'America/Costa_Rica';
SELECT version(),current_database(),current_user;
SELECT r.*,ra.animal_codigo FROM huellas.reporte r
LEFT JOIN huellas.reporte_animal ra ON ra.reporte_id=r.id_reporte ORDER BY r.id_reporte,ra.animal_codigo;
SELECT * FROM huellas.diagnostico ORDER BY id_diagnostico;
SELECT * FROM huellas.diagnostico_revision ORDER BY evaluacion_id,diagnostico_id;
SELECT id_solicitud,solicitante_id,estado,decision_id,responsable_id,razon,es_general
FROM huellas.estado_actual_solicitud ORDER BY id_solicitud;
SELECT id_solicitud,solicitante_id,estado FROM huellas.estado_actual_solicitud
WHERE es_general OR estado='PENDIENTE_INFORMACION' ORDER BY id_solicitud;
SELECT solicitud_id,animal_codigo,fecha_interes FROM huellas.solicitud_animal ORDER BY solicitud_id,animal_codigo;
SELECT solicitud_id,fecha,id_evento_solicitud,antecedente_decision_id,tipo_evento,
    responsable_id,resultado_actividad,estado_resultante,observaciones,razon
FROM huellas.historial_solicitud ORDER BY solicitud_id,fecha,id_evento_solicitud;
SELECT solicitud_id,animal_codigo,ingreso_id,fecha,responsable_id,resultado,valoracion_hogar,
    razon,observaciones,solicitante_id,informacion_vivienda,integrantes_hogar,
    experiencia_animales,condiciones_cuidado,actividad_contexto_id,tipo_actividad
FROM huellas.contexto_compatibilidad ORDER BY solicitud_id,animal_codigo,fecha,id_compatibilidad;
SELECT solicitud_id,animal_codigo,ingreso_id,id_compatibilidad,resultado FROM huellas.compatibilidad_vigente
ORDER BY solicitud_id,animal_codigo,ingreso_id;
SELECT a.id_solicitud AS rechazada,b.id_solicitud AS posterior,a.solicitante_id,a.razon AS razon_rechazo
FROM huellas.estado_actual_solicitud a JOIN huellas.solicitud_adopcion b
    ON a.solicitante_id=b.solicitante_id AND b.fecha_solicitud>a.fecha_decision
WHERE a.estado='RECHAZADA' ORDER BY a.id_solicitud,b.id_solicitud;
SELECT * FROM huellas.historial_evaluaciones WHERE animal_codigo='HS-01' ORDER BY fecha_evaluacion,id_evaluacion;
SELECT * FROM huellas.resumen_revisiones ORDER BY codigo_interno;
SELECT * FROM huellas.disponibilidad_actual ORDER BY animal_codigo,ingreso_id;
-- RESERVA no está implementada en esta versión: no convertir ausencia en integración comprobada.
SELECT to_regclass('huellas.reserva') AS reserva_pendiente_de_integrar;
