\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = huellas, pg_catalog;
SET LOCAL TIME ZONE 'America/Costa_Rica';
-- Antecedentes ficticios, NO resultados precargados de G05-P02.
INSERT INTO persona(id_persona,nombre_identificacion) VALUES
    (101,'Solicitante ficticio A'),(102,'Solicitante ficticio B'),(103,'Reportante ficticio'),
    (104,'Veterinario ficticio con registro corto');
INSERT INTO participacion(id_participacion,persona_id,tipo_participacion,fecha_inicio,fecha_fin,
    requisitos,estado_aprobacion_registro,fecha_aprobacion_registro) VALUES
    (104,104,'VETERINARIO','2026-10-04','2026-10-06 10:00','Registro ficticio de frontera','REGISTRADO','2026-10-04');
-- Los nuevos IDs explícitos no deben colisionar con futuras identidades.
SELECT setval(pg_get_serial_sequence('persona','id_persona'),(SELECT max(id_persona) FROM persona));
SELECT setval(pg_get_serial_sequence('participacion','id_participacion'),(SELECT max(id_participacion) FROM participacion));

INSERT INTO reporte(reportante_id,fecha_reporte,lugar_aproximado,situacion_observada)
    VALUES(103,'2026-10-04 07:00','Parque ficticio','Dos perros encontrados juntos');
INSERT INTO reporte DEFAULT VALUES; -- información del reporte desconocida, S-07.
INSERT INTO reporte_animal VALUES(1,'HS-01'),(1,'HS-02');

-- El caso exige una inicial por etapa. Se preparan antecedentes de las 17 etapas
-- de Jason. Su momento coincide con el ingreso; no se presupone intervención veterinaria.
INSERT INTO evaluacion_salud(animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,observaciones)
    SELECT animal_codigo,id_ingreso,'INICIAL',fecha_ingreso,'Evaluación inicial ficticia al ingreso'
    FROM ingreso ORDER BY id_ingreso;
INSERT INTO evaluacion_salud(id_evaluacion,animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,
    veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones) VALUES
    (1001,'HS-01',1,'REVISION_VETERINARIA','2026-10-05 09:00',7,8,
     'Control de piel y oído','Lesión leve y oído sensible',12.400,'Control profesional según evolución'),
    (1002,'HS-01',1,'REVISION_VETERINARIA','2026-10-06 09:00',7,8,
     'Revisión de evolución','Piel en recuperación; oído sin hallazgos',12.450,'Mantener seguimiento');
SELECT setval(pg_get_serial_sequence('evaluacion_salud','id_evaluacion'),(SELECT max(id_evaluacion) FROM evaluacion_salud));
INSERT INTO diagnostico(nombre_estandarizado) VALUES('Dermatitis'),('Otitis');
INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico) VALUES
    (1001,1,'CONFIRMADO'),(1001,2,'PROVISIONAL'),(1002,1,'CONFIRMADO'),(1002,2,'DESCARTADO');
-- Una decisión humana puede habilitar al animal con diagnóstico confirmado.
-- No existe lista de enfermedades ni automatismo de habilitación.
INSERT INTO cambio_disponibilidad(animal_codigo,ingreso_id,fecha,estado_disponibilidad,
    responsable_id,participacion_responsable_id,observacion_general,valoracion_sanitaria) VALUES
    ('HS-01',1,'2026-10-05 10:00','HABILITADO',1,1,'Decisión del equipo registrada',
     'Se considera compatible el cuidado domiciliario con el seguimiento indicado'),
    ('HS-02',2,'2026-10-05 10:00','HABILITADO',1,1,'Habilitación atribuible de ejemplo',
     'Condición valorada por el equipo; sin automatismo por diagnóstico');
COMMIT;
