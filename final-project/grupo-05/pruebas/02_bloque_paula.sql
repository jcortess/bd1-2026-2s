\set ON_ERROR_STOP on
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
-- Base nueva instalada con 09_instalar_bloque_paula.sql. No repetir sobre sus resultados.
-- Cada esperado está escrito ANTES de ejecutar. La evidencia se construye con
-- valores leídos y GET STACKED DIAGNOSTICS, nunca con un aviso preparado de éxito.
CREATE TEMP TABLE resultado_paula(codigo text PRIMARY KEY,esperado text,observado jsonb);
GRANT SELECT,INSERT ON resultado_paula TO huellas_g05_operador;
CREATE FUNCTION pg_temp.comprueba(p_codigo text,p_cumple boolean,p_observado jsonb) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN
    IF p_cumple IS DISTINCT FROM true THEN RAISE EXCEPTION 'Falla %: %',p_codigo,p_observado; END IF;
    INSERT INTO resultado_paula VALUES(p_codigo,'Valores y vínculos indicados en el guion',p_observado);
END $$;
CREATE FUNCTION pg_temp.rechaza(p_codigo text,p_sql text,p_estado text,p_restriccion text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_estado text; v_restriccion text; v_mensaje text;
BEGIN
    BEGIN
        EXECUTE p_sql;
        RAISE EXCEPTION 'Falla %: la sentencia fue aceptada',p_codigo;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_estado=RETURNED_SQLSTATE,v_restriccion=CONSTRAINT_NAME,v_mensaje=MESSAGE_TEXT;
        IF v_estado<>p_estado OR (p_restriccion IS NOT NULL AND v_restriccion<>p_restriccion) THEN RAISE; END IF;
        INSERT INTO resultado_paula VALUES(p_codigo,p_estado || coalesce(' / ' || p_restriccion,''),
            jsonb_build_object('sqlstate',v_estado,'restriccion',v_restriccion,'mensaje',v_mensaje));
    END;
END $$;

SELECT pg_temp.comprueba('P00-base',
    (SELECT count(*)=0 FROM solicitud_adopcion) AND (SELECT count(*)=17 FROM ingreso)
    AND (SELECT count(*)=19 FROM evaluacion_salud),
    jsonb_build_object('solicitudes',(SELECT count(*) FROM solicitud_adopcion),
        'ingresos',(SELECT count(*) FROM ingreso),'evaluaciones',(SELECT count(*) FROM evaluacion_salud)));

-- P01 | AC-01: solicitud general, cuatro datos de hogar y recepción atribuible.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT crear_solicitud('05000000-0000-0000-0000-000000000001',101,'2026-10-07 08:00',
    'Casa A con patio cerrado','Dos adultos','Sin experiencia previa','Tiempo diario y atención veterinaria',1)
    AS general \gset
COMMIT;
SELECT decision_id AS recepcion FROM estado_actual_solicitud WHERE id_solicitud=:general \gset
SELECT pg_temp.comprueba('P01-general',estado='RECIBIDA' AND es_general AND solicitante_id=101
    AND informacion_vivienda='Casa A con patio cerrado' AND integrantes_hogar='Dos adultos'
    AND experiencia_animales='Sin experiencia previa' AND condiciones_cuidado='Tiempo diario y atención veterinaria'
    AND responsable_id=1 AND razon='Recepción de solicitud',to_jsonb(s))
    FROM estado_actual_solicitud s WHERE id_solicitud=:general;

-- P02 | AC-01: interés posterior por dos animales. La entrevista NO decide estado.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT asociar_animal(:general,'HS-01','2026-10-07 09:00');
SELECT asociar_animal(:general,'HS-02','2026-10-07 09:00');
SELECT registrar_actividad('05000000-0000-0000-0000-000000000002',:general,'2026-10-07 10:00',7,
    'ENTREVISTA','Favorable en entrevista','Se revisaron condiciones y cuidados; visita no necesaria en este caso') AS entrevista \gset
COMMIT;
SELECT pg_temp.comprueba('P02-interes-actividad',
    (SELECT count(*)=2 FROM solicitud_animal WHERE solicitud_id=:general)
    AND (SELECT estado='RECIBIDA' AND NOT es_general FROM estado_actual_solicitud WHERE id_solicitud=:general)
    AND EXISTS (SELECT FROM evento_solicitud WHERE id_evento_solicitud=:entrevista AND responsable_id=7
        AND fecha='2026-10-07 10:00' AND resultado_actividad='Favorable en entrevista'
        AND observaciones IS NOT NULL AND estado_resultante IS NULL),
    jsonb_build_object('estado',(SELECT estado FROM estado_actual_solicitud WHERE id_solicitud=:general),
        'interes',(SELECT jsonb_agg(to_jsonb(a)) FROM solicitud_animal a WHERE solicitud_id=:general),
        'actividad',(SELECT to_jsonb(e) FROM evento_solicitud e WHERE id_evento_solicitud=:entrevista)));

-- P03 | La interfaz P03 debe rechazar tanto falta de decisión como interés sin evaluación.
SELECT pg_temp.rechaza('P03-sin-aprobacion',format(
    $$SELECT _exigir_compatibilidad(%s,'HS-01',1,'2026-10-08')$$,:general),'P2024');
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000003',:general,:recepcion,'2026-10-07 11:00',
    1,'APROBADA','Condiciones generales adecuadas; valorar cada animal') AS aprobacion \gset
COMMIT;
SELECT pg_temp.rechaza('P03-interes-no-compatible',format(
    $$SELECT _exigir_compatibilidad(%s,'HS-01',1,'2026-10-08')$$,:general),'P2026');

-- P04 | AC-01/02/04: evaluaciones concretas distintas, conservando el mismo hogar.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000004',:general,'HS-01',1,'2026-10-07 12:00',1,
    'FAVORABLE','Patio cerrado y tiempo compatibles con las necesidades de Luna',
    'Correspondencia favorable para este animal','Evaluación individual, no adjudicación',:entrevista) AS favorable \gset
SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000005',:general,'HS-02',2,'2026-10-07 12:00',1,
    'NO_FAVORABLE','El tiempo de acompañamiento ofrecido resulta insuficiente para Milo',
    'Necesidades de este animal diferentes','Se conserva el interés; sin reserva',:entrevista) AS no_favorable \gset
COMMIT;
SELECT pg_temp.comprueba('P04-compatibilidades',
    (SELECT count(*)=2 AND count(DISTINCT resultado)=2 FROM compatibilidad_vigente WHERE solicitud_id=:general)
    AND EXISTS (SELECT FROM contexto_compatibilidad WHERE id_compatibilidad=:favorable AND solicitud_id=:general
        AND animal_codigo='HS-01' AND ingreso_id=1 AND solicitante_id=101
        AND informacion_vivienda='Casa A con patio cerrado' AND resultado='FAVORABLE' AND actividad_contexto_id=:entrevista)
    AND (SELECT _exigir_compatibilidad(:general,'HS-01',1,'2026-10-08')=:favorable),
    (SELECT jsonb_agg(to_jsonb(c) ORDER BY animal_codigo) FROM contexto_compatibilidad c WHERE solicitud_id=:general));
SELECT pg_temp.rechaza('P04-no-favorable',format(
    $$SELECT _exigir_compatibilidad(%s,'HS-02',2,'2026-10-08')$$,:general),'P2026');
SELECT pg_temp.rechaza('P04-etapa-ajena',format(
    $$SELECT _exigir_compatibilidad(%s,'HS-01',2,'2026-10-08')$$,:general),'P2025');

-- P05 | AC-03: pendiente, rechazo registrado y solicitud posterior de la misma persona.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT crear_solicitud('05000000-0000-0000-0000-000000000006',102,'2026-10-07 08:00',
    'Apartamento B','Un adulto','Experiencia con gatos','Cuidados declarados',1,ARRAY['HS-01','HS-02']) AS multiple \gset
SELECT crear_solicitud('05000000-0000-0000-0000-000000000007',101,'2026-10-08 08:00',
    'Otro contexto de vivienda','Un adulto','Experiencia limitada','Información por completar',1) AS rechazada \gset
SELECT decision_id AS r_recibida FROM estado_actual_solicitud WHERE id_solicitud=:rechazada \gset
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000008',:rechazada,:r_recibida,'2026-10-08 09:00',1,
    'PENDIENTE_INFORMACION','Falta precisar el espacio disponible') AS pendiente \gset
SELECT registrar_actividad('05000000-0000-0000-0000-000000000009',:rechazada,'2026-10-08 10:00',7,
    'INFORMACION','No se completó lo solicitado','Se conserva la comunicación y su resultado') AS informacion \gset
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000010',:rechazada,:pendiente,'2026-10-08 11:00',1,
    'RECHAZADA','La información disponible no acredita condiciones para el cuidado') AS rechazo \gset
SELECT crear_solicitud('05000000-0000-0000-0000-000000000011',101,'2026-10-09 08:00',
    'Nueva vivienda declarada','Dos adultos','Experiencia declarada','Condiciones nuevas para evaluar',1) AS posterior \gset
COMMIT;
SELECT pg_temp.comprueba('P05-nueva-tras-rechazo',
    (SELECT estado='RECHAZADA' FROM estado_actual_solicitud WHERE id_solicitud=:rechazada)
    AND (SELECT estado='RECIBIDA' AND es_general FROM estado_actual_solicitud WHERE id_solicitud=:posterior)
    AND (SELECT count(*)=4 FROM evento_solicitud WHERE solicitud_id=:rechazada)
    AND (SELECT count(*)=2 FROM solicitud_animal WHERE solicitud_id=:multiple)
    AND EXISTS (SELECT FROM solicitud_adopcion a JOIN solicitud_adopcion b ON a.solicitante_id=b.solicitante_id
        WHERE a.id_solicitud=:rechazada AND b.id_solicitud=:posterior AND b.fecha_solicitud>'2026-10-08 11:00'),
    (SELECT jsonb_agg(to_jsonb(e) ORDER BY solicitud_id,fecha,id_evento_solicitud) FROM historial_solicitud e
     WHERE solicitud_id IN (:rechazada,:posterior)));

-- P06 | Todos los estados del caso, sin plazo inventado ni visita universal.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT crear_solicitud('05000000-0000-0000-0000-000000000012',102,'2026-10-09',
    'Vivienda C','Familia C','Experiencia C','Condiciones C',1) AS estados \gset
SELECT decision_id AS e0 FROM estado_actual_solicitud WHERE id_solicitud=:estados \gset
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000013',:estados,:e0,'2026-10-09 01:00',1,'EN_EVALUACION','Inicio de evaluación') AS e1 \gset
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000014',:estados,:e1,'2026-10-09 02:00',1,'PENDIENTE_INFORMACION','Información requerida') AS e2 \gset
SELECT registrar_actividad('05000000-0000-0000-0000-000000000015',:estados,'2026-10-09 03:00',7,
    'VISITA_HOGAR','Se observan condiciones suficientes','Visita pertinente en este caso concreto');
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000016',:estados,:e2,'2026-10-09 04:00',1,'APROBADA','Decisión fundada') AS e3 \gset
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000017',:estados,:e3,'2026-10-09 05:00',1,'CANCELADA','Desistimiento comunicado') AS e4 \gset
SELECT decidir_solicitud('05000000-0000-0000-0000-000000000018',:estados,:e4,'2026-10-09 06:00',1,'VENCIDA','Rectificación administrativa documentada sin plazo automático') AS e5 \gset
COMMIT;
SELECT pg_temp.comprueba('P06-estados',
    (SELECT count(DISTINCT estado_resultante)=7 FROM evento_solicitud WHERE estado_resultante IS NOT NULL)
    AND (SELECT count(*)=0 FROM evento_solicitud WHERE solicitud_id=:general AND tipo_evento='VISITA_HOGAR'),
    jsonb_build_object('estados',(SELECT jsonb_agg(DISTINCT estado_resultante) FROM evento_solicitud WHERE estado_resultante IS NOT NULL),
        'visitas_solicitud_general',(SELECT count(*) FROM evento_solicitud WHERE solicitud_id=:general AND tipo_evento='VISITA_HOGAR')));

-- P07 | Un fallo en el segundo detalle debe revertir cabecera, recepción y primer detalle.
SELECT pg_temp.rechaza('P07-atomicidad',
    $$SELECT crear_solicitud('05000000-0000-0000-0000-000000000099',101,'2026-10-10',
        'Vivienda','Integrantes','Experiencia','Cuidados',1,ARRAY['HS-01','ANIMAL-INEXISTENTE'])$$,
    '23503','solicitud_animal_animal_codigo_fkey');
SELECT pg_temp.comprueba('P07-sin-parciales',
    NOT EXISTS (SELECT FROM solicitud_adopcion WHERE clave_operacion='05000000-0000-0000-0000-000000000099')
    AND NOT EXISTS (SELECT FROM evento_solicitud WHERE clave_operacion='05000000-0000-0000-0000-000000000099')
    AND (SELECT count(*)=5 FROM solicitud_adopcion) AND (SELECT count(*)=4 FROM solicitud_animal),
    jsonb_build_object('solicitudes',(SELECT count(*) FROM solicitud_adopcion),
        'intereses',(SELECT count(*) FROM solicitud_animal),'recepciones',(SELECT count(*) FROM evento_solicitud WHERE tipo_evento='RECEPCION')));

-- P08 | Cada rechazo exige su causa real. El resto de referencias sí existe.
SELECT pg_temp.rechaza('P08-solicitante-fk',
    $$SELECT crear_solicitud('05000000-0000-0000-0000-000000000100',99999,'2026-10-10','V','I','E','C',1)$$,
    '23503','solicitud_adopcion_solicitante_id_fkey');
SELECT pg_temp.rechaza('P08-vivienda-nula',
    $$SELECT crear_solicitud('05000000-0000-0000-0000-000000000101',101,'2026-10-10',NULL,'I','E','C',1)$$,'23502');
SELECT pg_temp.rechaza('P08-texto-vacio',
    $$SELECT crear_solicitud('05000000-0000-0000-0000-000000000102',101,'2026-10-10','V','I',' ','C',1)$$,
    '23514','texto_no_vacio_check');
SELECT pg_temp.rechaza('P08-reintento-clave',
    $$SELECT crear_solicitud('05000000-0000-0000-0000-000000000001',101,'2026-10-07 08:00',
        'Casa A con patio cerrado','Dos adultos','Sin experiencia previa','Tiempo diario y atención veterinaria',1)$$,
    '23505','solicitud_adopcion_clave_operacion_key');
SELECT pg_temp.rechaza('P08-interes-duplicado',format($$SELECT asociar_animal(%s,'HS-01','2026-10-07 09:00')$$,:general),
    '23505','solicitud_animal_pkey');
SELECT pg_temp.rechaza('P08-solicitud-ausente',$$SELECT asociar_animal(99999,'HS-01','2026-10-10')$$,'P2005');
SELECT pg_temp.rechaza('P08-interes-animal-ausente',format($$SELECT asociar_animal(%s,'NO-EXISTE','2026-10-10')$$,:general),
    '23503','solicitud_animal_animal_codigo_fkey');
SELECT pg_temp.rechaza('P08-duplicado-en-alta',
    $$SELECT crear_solicitud('05000000-0000-0000-0000-000000000103',101,'2026-10-10','V','I','E','C',1,ARRAY['HS-01','HS-01'])$$,
    '23505','solicitud_animal_pkey');
SELECT pg_temp.rechaza('P08-fecha-anterior',format($$SELECT asociar_animal(%s,'HS-03','2026-10-06')$$,:general),'P2002');
SELECT pg_temp.rechaza('P08-fecha-futura',format($$SELECT asociar_animal(%s,'HS-03',clock_timestamp()+interval '1 day')$$,:general),'P2002');

SELECT pg_temp.rechaza('P09-responsable-ausente',format(
    $$SELECT decidir_solicitud('05000000-0000-0000-0000-000000000104',%s,%s,'2026-10-10',NULL,'RECHAZADA','Razón')$$,:general,:aprobacion),'P2003');
SELECT pg_temp.rechaza('P09-responsable-desconocido',format(
    $$SELECT registrar_actividad('05000000-0000-0000-0000-000000000105',%s,'2026-10-10',99999,'ENTREVISTA','R','O')$$,:general),'P2003');
SELECT pg_temp.rechaza('P09-actor-sin-rol',format(
    $$SELECT registrar_actividad('05000000-0000-0000-0000-000000000106',%s,'2026-10-10',101,'ENTREVISTA','R','O')$$,:general),'P2004');
SELECT pg_temp.rechaza('P09-sin-razon',format(
    $$SELECT decidir_solicitud('05000000-0000-0000-0000-000000000107',%s,%s,'2026-10-10',1,'RECHAZADA',NULL)$$,:general,:aprobacion),
    '23514','evento_contenido');
SELECT pg_temp.rechaza('P09-sin-estado',format(
    $$SELECT decidir_solicitud('05000000-0000-0000-0000-000000000108',%s,%s,'2026-10-10',1,NULL,'Razón')$$,:general,:aprobacion),
    '23514','evento_contenido');
SELECT pg_temp.rechaza('P09-estado-invalido',format(
    $$SELECT decidir_solicitud('05000000-0000-0000-0000-000000000109',%s,%s,'2026-10-10',1,'RESERVADA','Razón')$$,:general,:aprobacion),
    '23514','estado_solicitud_check');
SELECT pg_temp.rechaza('P09-antecedente-viejo',format(
    $$SELECT decidir_solicitud('05000000-0000-0000-0000-000000000110',%s,%s,'2026-10-10',1,'RECHAZADA','Razón')$$,:general,:recepcion),'P2021');
SELECT pg_temp.rechaza('P09-actividad-sin-observacion',format(
    $$SELECT registrar_actividad('05000000-0000-0000-0000-000000000111',%s,'2026-10-10',1,'ENTREVISTA','R',NULL)$$,:general),
    '23514','evento_contenido');
SELECT pg_temp.rechaza('P09-actividad-sin-resultado',format(
    $$SELECT registrar_actividad('05000000-0000-0000-0000-000000000112',%s,'2026-10-10',1,'ENTREVISTA',NULL,'O')$$,:general),
    '23514','evento_contenido');
SELECT pg_temp.rechaza('P09-tipo-no-actividad',format(
    $$SELECT registrar_actividad('05000000-0000-0000-0000-000000000113',%s,'2026-10-10',1,'DECISION','APROBADA','O')$$,:general),'P2023');
SELECT pg_temp.rechaza('P09-reintento-actividad',format(
    $$SELECT registrar_actividad('05000000-0000-0000-0000-000000000002',%s,'2026-10-07 10:00',7,'ENTREVISTA','R','O')$$,:general),
    '23505','evento_solicitud_clave_operacion_key');

SELECT pg_temp.rechaza('P10-interes-no-evaluado',format(
    $$SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000114',%s,'HS-03',3,'2026-10-10',1,'FAVORABLE','V','R','O')$$,:general),
    '23503','compatibilidad_interes_fk');
SELECT pg_temp.rechaza('P10-ingreso-animal-ajeno',format(
    $$SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000115',%s,'HS-01',2,'2026-10-10',1,'FAVORABLE','V','R','O')$$,:general),
    '23503','compatibilidad_ingreso_fk');
SELECT pg_temp.rechaza('P10-actividad-otra-solicitud',format(
    $$SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000116',%s,'HS-01',1,'2026-10-10',1,'FAVORABLE','V','R','O',%s)$$,:general,:informacion),
    '23503','compatibilidad_actividad_fk');
SELECT pg_temp.rechaza('P10-decision-no-actividad',format(
    $$SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000117',%s,'HS-01',1,'2026-10-10',1,'FAVORABLE','V','R','O',%s)$$,:general,:aprobacion),'P2022');
SELECT pg_temp.rechaza('P10-evaluacion-sin-contexto',format(
    $$SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000118',%s,'HS-01',1,'2026-10-10',1,'FAVORABLE',NULL,'R','O')$$,:general),'23502');
SELECT pg_temp.rechaza('P10-dominio',format(
    $$SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000119',%s,'HS-01',1,'2026-10-10',1,'RESERVADO','V','R','O')$$,:general),
    '23514','compatibilidad_animal_hogar_resultado_check');
SELECT pg_temp.rechaza('P10-evaluacion-antigua',format(
    $$SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000120',%s,'HS-01',1,'2026-10-07 11:59:59.999999',1,'FAVORABLE','V','R','O')$$,:general),'P2002');

-- P11 | Una evaluación posterior desfavorable invalida el uso del favorable anterior.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000020',:general,'HS-01',1,'2026-10-10',1,
    'PENDIENTE_INFORMACION','Nueva valoración del mismo hogar','Se requiere aclarar el cuidado','Mantener valoración anterior como historia');
COMMIT;
SELECT pg_temp.rechaza('P11-vigente-pendiente',format($$SELECT _exigir_compatibilidad(%s,'HS-01',1,'2026-10-11')$$,:general),'P2026');
SELECT pg_temp.comprueba('P11-historia-individual',
    (SELECT count(*)=2 FROM compatibilidad_animal_hogar WHERE solicitud_id=:general AND animal_codigo='HS-01')
    AND (SELECT resultado='PENDIENTE_INFORMACION' FROM compatibilidad_vigente WHERE solicitud_id=:general AND animal_codigo='HS-01'),
    (SELECT jsonb_agg(to_jsonb(c) ORDER BY fecha,id_compatibilidad) FROM compatibilidad_animal_hogar c
     WHERE solicitud_id=:general AND animal_codigo='HS-01'));

-- Integridad de antecedentes. Las alteraciones válidas se revierten al final.
BEGIN;
SELECT pg_temp.rechaza('R01-reporte-pk',$$INSERT INTO reporte(id_reporte) VALUES(1)$$,'23505','reporte_pkey');
SELECT pg_temp.rechaza('R01-reporte-persona',$$INSERT INTO reporte(reportante_id) VALUES(99999)$$,'23503','reporte_reportante_id_fkey');
SELECT pg_temp.rechaza('R01-reporte-texto',$$INSERT INTO reporte(lugar_aproximado) VALUES(' ')$$,'23514','texto_no_vacio_check');
SELECT pg_temp.rechaza('R01-reporte-fecha',$$INSERT INTO reporte(fecha_reporte) VALUES('infinity')$$,'23514','instante_check');
SELECT pg_temp.rechaza('R02-pareja-duplicada',$$INSERT INTO reporte_animal VALUES(1,'HS-01')$$,'23505','reporte_animal_pkey');
SELECT pg_temp.rechaza('R02-reporte-ausente',$$INSERT INTO reporte_animal VALUES(99999,'HS-01')$$,'23503','reporte_animal_reporte_id_fkey');
SELECT pg_temp.rechaza('R02-animal-ausente',$$INSERT INTO reporte_animal VALUES(1,'NO-EXISTE')$$,'23503','reporte_animal_animal_codigo_fkey');
SELECT pg_temp.rechaza('R02-clave-incompleta',$$INSERT INTO reporte_animal VALUES(1,NULL)$$,'23502');
SELECT pg_temp.rechaza('R02-padre-delete',$$DELETE FROM reporte WHERE id_reporte=1$$,'23503','reporte_animal_reporte_id_fkey');
SELECT pg_temp.rechaza('R02-padre-update',$$UPDATE reporte SET id_reporte=90000 WHERE id_reporte=1$$,'23503','reporte_animal_reporte_id_fkey');
UPDATE reporte SET lugar_aproximado='Lugar ficticio precisado' WHERE id_reporte=2;
UPDATE reporte_animal SET animal_codigo='HS-03' WHERE reporte_id=1 AND animal_codigo='HS-02';
SELECT pg_temp.comprueba('R02-rectificacion-valida',
    EXISTS (SELECT FROM reporte WHERE id_reporte=2 AND reportante_id IS NULL AND lugar_aproximado='Lugar ficticio precisado')
    AND EXISTS (SELECT FROM reporte_animal WHERE reporte_id=1 AND animal_codigo='HS-03'),
    (SELECT jsonb_agg(to_jsonb(r)) FROM reporte r));

SELECT pg_temp.rechaza('R03-evaluacion-pk',$$INSERT INTO evaluacion_salud
    (id_evaluacion,animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones)
    VALUES(1001,'HS-03',3,'REVISION_VETERINARIA','2026-10-06',7,8,'M','O',1,'R')$$,'23505','evaluacion_salud_pkey');
SELECT pg_temp.rechaza('R03-inicial-duplicada',$$INSERT INTO evaluacion_salud(animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion)
    VALUES('HS-03',3,'INICIAL','2026-10-06')$$,'23505','evaluacion_inicial_etapa_uq');
SELECT pg_temp.rechaza('R03-contexto-ajeno',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones)
    VALUES('HS-01',2,'REVISION_VETERINARIA','2026-10-06',7,8,'M','O',1,'R')$$,'23503','evaluacion_ingreso_animal_fk');
SELECT pg_temp.rechaza('R03-ingreso-ausente',$$INSERT INTO evaluacion_salud(animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion)
    VALUES('HS-01',99999,'INICIAL','2026-10-06')$$,'23503','evaluacion_ingreso_animal_fk');
SELECT pg_temp.rechaza('R03-antes-ingreso',$$INSERT INTO evaluacion_salud(animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion)
    VALUES('HS-01',1,'INICIAL','2026-10-04 07:59:59.999999')$$,'P2010');
SELECT pg_temp.rechaza('R03-sin-veterinario',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,motivo,observaciones,peso,recomendaciones)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06','M','O',1,'R')$$,'23514','chk_revision_campos');
SELECT pg_temp.rechaza('R03-sin-motivo',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,observaciones,peso,recomendaciones)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06',7,8,'O',1,'R')$$,'23514','chk_revision_campos');
SELECT pg_temp.rechaza('R03-sin-observaciones',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,peso,recomendaciones)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06',7,8,'M',1,'R')$$,'23514','chk_revision_campos');
SELECT pg_temp.rechaza('R03-sin-peso',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,recomendaciones)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06',7,8,'M','O','R')$$,'23514','chk_revision_campos');
SELECT pg_temp.rechaza('R03-sin-recomendaciones',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,peso)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06',7,8,'M','O',1)$$,'23514','chk_revision_campos');
SELECT pg_temp.rechaza('R03-peso-cero',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06',7,8,'M','O',0,'R')$$,'23514','evaluacion_salud_peso_check');
SELECT pg_temp.rechaza('R03-peso-nan',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,peso)
    VALUES('HS-03',3,'INICIAL','2026-10-06','NaN')$$,'23514','evaluacion_salud_peso_check');
SELECT pg_temp.rechaza('R03-registro-ajeno',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06',7,1,'M','O',1,'R')$$,'P2012');
SELECT pg_temp.rechaza('R03-fin-registro',$$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones)
    VALUES('HS-03',3,'REVISION_VETERINARIA','2026-10-06 10:00',104,104,'M','O',1,'R')$$,'P2012');
INSERT INTO evaluacion_salud(id_evaluacion,animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,
    veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones)
    VALUES(90001,'HS-03',3,'REVISION_VETERINARIA','2026-10-06 09:59:59.999999',104,104,'M','O',0.001,'R');
SELECT pg_temp.comprueba('R03-frontera-valida',peso=0.001 AND registro_veterinario_id=104,to_jsonb(e))
    FROM evaluacion_salud e WHERE id_evaluacion=90001;
SELECT pg_temp.rechaza('R03-registro-historico',$$UPDATE participacion SET fecha_fin='2026-10-06 09:59:59.999999'
    WHERE id_participacion=104$$,'P2015');
SELECT pg_temp.rechaza('R03-registro-delete',$$DELETE FROM participacion WHERE id_participacion=104$$,
    '23503','evaluacion_salud_registro_veterinario_id_fkey');
SELECT pg_temp.rechaza('R03-etapa-modificada',$$UPDATE ingreso SET fecha_ingreso='2026-10-04 08:01' WHERE id_ingreso=3$$,'P2014');

SELECT pg_temp.rechaza('R04-catalogo-pk',$$INSERT INTO diagnostico VALUES(1,'Otro nombre')$$,'23505','diagnostico_pkey');
SELECT pg_temp.rechaza('R04-catalogo-nombre',$$INSERT INTO diagnostico(nombre_estandarizado) VALUES('Dermatitis')$$,
    '23505','diagnostico_nombre_estandarizado_key');
SELECT pg_temp.rechaza('R04-catalogo-nulo',$$INSERT INTO diagnostico(nombre_estandarizado) VALUES(NULL)$$,'23502');
SELECT pg_temp.rechaza('R04-catalogo-vacio',$$INSERT INTO diagnostico(nombre_estandarizado) VALUES(' ')$$,'23514','texto_no_vacio_check');
SELECT pg_temp.rechaza('R05-pareja-pk',$$INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico)
    VALUES(1001,1,'CONFIRMADO')$$,'23505','diagnostico_revision_pkey');
SELECT pg_temp.rechaza('R05-no-inicial',$$INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico)
    VALUES(1,1,'CONFIRMADO')$$,'23503','fk_diagnostico_revision_evaluacion');
SELECT pg_temp.rechaza('R05-diagnostico-ausente',$$INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico)
    VALUES(1001,99999,'CONFIRMADO')$$,'23503','diagnostico_revision_diagnostico_id_fkey');
SELECT pg_temp.rechaza('R05-estado',$$INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico)
    VALUES(90001,1,'INVALIDO')$$,'23514','diagnostico_revision_estado_diagnostico_check');
SELECT pg_temp.rechaza('R05-estado-nulo',$$INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico)
    VALUES(90001,1,NULL)$$,'23502');
SELECT pg_temp.rechaza('R05-catalogo-delete',$$DELETE FROM diagnostico WHERE id_diagnostico=1$$,
    '23503','diagnostico_revision_diagnostico_id_fkey');
SELECT pg_temp.rechaza('R05-catalogo-update',$$UPDATE diagnostico SET id_diagnostico=99999 WHERE id_diagnostico=1$$,
    '23503','diagnostico_revision_diagnostico_id_fkey');
INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico) VALUES(90001,1,'PROVISIONAL');
SELECT pg_temp.comprueba('R05-reutilizacion-clinica',
    contar_revisiones_animal('HS-01')=2
    AND (SELECT revisiones=2 AND registros_confirmados=2 FROM resumen_revisiones WHERE codigo_interno='HS-01')
    AND (SELECT count(*)=3 FROM historial_evaluaciones WHERE animal_codigo='HS-01')
    AND EXISTS (SELECT FROM diagnostico_revision WHERE evaluacion_id=90001 AND diagnostico_id=1 AND estado_diagnostico='PROVISIONAL'),
    jsonb_build_object('conteo',contar_revisiones_animal('HS-01'),
        'resumen',(SELECT to_jsonb(r) FROM resumen_revisiones r WHERE codigo_interno='HS-01'),
        'historia',(SELECT jsonb_agg(to_jsonb(h) ORDER BY fecha_evaluacion) FROM historial_evaluaciones h WHERE animal_codigo='HS-01')));

SELECT pg_temp.rechaza('R06-disponibilidad-pk',$$INSERT INTO cambio_disponibilidad
    VALUES(1,'HS-02',2,'2026-10-10','HABILITADO',1,1,'O','V')$$,'23505','cambio_disponibilidad_pkey');
SELECT pg_temp.rechaza('R06-disponibilidad-contexto',$$INSERT INTO cambio_disponibilidad
    (animal_codigo,ingreso_id,fecha,estado_disponibilidad,responsable_id,participacion_responsable_id,observacion_general,valoracion_sanitaria)
    VALUES('HS-01',2,'2026-10-10','HABILITADO',1,1,'O','V')$$,'23503','disponibilidad_ingreso_animal_fk');
SELECT pg_temp.rechaza('R06-disponibilidad-observacion',$$INSERT INTO cambio_disponibilidad
    (animal_codigo,ingreso_id,fecha,estado_disponibilidad,responsable_id,participacion_responsable_id,valoracion_sanitaria)
    VALUES('HS-01',1,'2026-10-10','HABILITADO',1,1,'V')$$,'23502');
SELECT pg_temp.rechaza('R06-disponibilidad-valoracion',$$INSERT INTO cambio_disponibilidad
    (animal_codigo,ingreso_id,fecha,estado_disponibilidad,responsable_id,participacion_responsable_id,observacion_general)
    VALUES('HS-01',1,'2026-10-10','HABILITADO',1,1,'O')$$,'23502');
SELECT pg_temp.rechaza('R06-disponibilidad-dominio',$$INSERT INTO cambio_disponibilidad
    (animal_codigo,ingreso_id,fecha,estado_disponibilidad,responsable_id,participacion_responsable_id,observacion_general,valoracion_sanitaria)
    VALUES('HS-01',1,'2026-10-10','POR_DIAGNOSTICO',1,1,'O','V')$$,
    '23514','cambio_disponibilidad_estado_disponibilidad_check');
SELECT pg_temp.rechaza('R06-disponibilidad-actor',$$INSERT INTO cambio_disponibilidad
    (animal_codigo,ingreso_id,fecha,estado_disponibilidad,responsable_id,participacion_responsable_id,observacion_general,valoracion_sanitaria)
    VALUES('HS-01',1,'2026-10-10','HABILITADO',99999,1,'O','V')$$,'P2003');
INSERT INTO cambio_disponibilidad(animal_codigo,ingreso_id,fecha,estado_disponibilidad,responsable_id,
    participacion_responsable_id,observacion_general,valoracion_sanitaria) VALUES
    ('HS-01',1,'2026-10-11','NO_DISPONIBLE',1,1,'Suspensión temporal decidida','Valoración humana temporal'),
    ('HS-01',1,'2026-10-12','HABILITADO',1,1,'Restablecimiento decidido','Cuidado posible con seguimiento');
SELECT pg_temp.comprueba('R06-historia-sin-automatismo',
    (SELECT count(*)=3 FROM cambio_disponibilidad WHERE animal_codigo='HS-01')
    AND (SELECT estado_disponibilidad='HABILITADO' AND responsable_id=1 FROM disponibilidad_actual WHERE animal_codigo='HS-01')
    AND EXISTS (SELECT FROM diagnostico_revision WHERE evaluacion_id=1002 AND diagnostico_id=1 AND estado_diagnostico='CONFIRMADO'),
    (SELECT jsonb_agg(to_jsonb(d) ORDER BY fecha,id_cambio) FROM cambio_disponibilidad d WHERE animal_codigo='HS-01'));

-- Identidad de las otras relaciones de P02, con datos que satisfacen su contexto.
SELECT pg_temp.rechaza('R07-solicitud-pk',format($$INSERT INTO solicitud_adopcion
    SELECT id_solicitud,'05000000-0000-0000-0000-000000000123',solicitante_id,fecha_solicitud,
        informacion_vivienda,integrantes_hogar,experiencia_animales,condiciones_cuidado
    FROM solicitud_adopcion WHERE id_solicitud=%s$$,:general),'23505','solicitud_adopcion_pkey');
SELECT pg_temp.rechaza('R08-evento-pk',format($$INSERT INTO evento_solicitud
    SELECT id_evento_solicitud,'05000000-0000-0000-0000-000000000124',solicitud_id,fecha,tipo_evento,
        responsable_id,participacion_responsable_id,resultado_actividad,estado_resultante,observaciones,razon,antecedente_decision_id
    FROM evento_solicitud WHERE id_evento_solicitud=%s$$,:entrevista),'23505','evento_solicitud_pkey');
SELECT pg_temp.rechaza('R09-compatibilidad-pk',format($$INSERT INTO compatibilidad_animal_hogar
    SELECT id_compatibilidad,'05000000-0000-0000-0000-000000000125',solicitud_id,animal_codigo,ingreso_id,
        '2026-10-11'::timestamptz,responsable_id,participacion_responsable_id,resultado,valoracion_hogar,razon,observaciones,actividad_contexto_id
    FROM compatibilidad_animal_hogar WHERE id_compatibilidad=%s$$,:favorable),'23505','compatibilidad_animal_hogar_pkey');
SELECT evaluar_compatibilidad('05000000-0000-0000-0000-000000000126',:multiple,'HS-01',1,'2026-10-11',1,
    'FAVORABLE','Apartamento B valorado para Luna','Evaluación de otro hogar','Sin adjudicar el animal');
SELECT pg_temp.comprueba('R09-hogares-separados',
    (SELECT count(DISTINCT solicitud_id)=2 AND count(DISTINCT informacion_vivienda)=2
        FROM contexto_compatibilidad WHERE animal_codigo='HS-01'),
    (SELECT jsonb_agg(to_jsonb(c)) FROM contexto_compatibilidad c WHERE animal_codigo='HS-01'));

SELECT pg_temp.rechaza('H01-evaluacion-update',$$UPDATE evaluacion_salud SET motivo='Otro' WHERE id_evaluacion=1001$$,'P2001');
SELECT pg_temp.rechaza('H01-evaluacion-delete',$$DELETE FROM evaluacion_salud WHERE id_evaluacion=1001$$,'P2001');
SELECT pg_temp.rechaza('H01-diagnostico-update',$$UPDATE diagnostico_revision SET estado_diagnostico='DESCARTADO' WHERE evaluacion_id=1001 AND diagnostico_id=1$$,'P2001');
SELECT pg_temp.rechaza('H01-diagnostico-delete',$$DELETE FROM diagnostico_revision WHERE evaluacion_id=1001 AND diagnostico_id=1$$,'P2001');
SELECT pg_temp.rechaza('H01-disponibilidad-update',$$UPDATE cambio_disponibilidad SET estado_disponibilidad='NO_DISPONIBLE' WHERE id_cambio=1$$,'P2001');
SELECT pg_temp.rechaza('H01-disponibilidad-delete',$$DELETE FROM cambio_disponibilidad WHERE id_cambio=1$$,'P2001');
SELECT pg_temp.rechaza('H02-hogar-inmutable',format($$UPDATE solicitud_adopcion SET informacion_vivienda='Otro hogar' WHERE id_solicitud=%s$$,:general),'P2001');
SELECT pg_temp.rechaza('H02-solicitud-delete',format($$DELETE FROM solicitud_adopcion WHERE id_solicitud=%s$$,:general),'P2001');
SELECT pg_temp.rechaza('H02-interes-update',format($$UPDATE solicitud_animal SET animal_codigo='HS-03' WHERE solicitud_id=%s AND animal_codigo='HS-01'$$,:general),'P2001');
SELECT pg_temp.rechaza('H02-interes-delete',format($$DELETE FROM solicitud_animal WHERE solicitud_id=%s$$,:general),'P2001');
SELECT pg_temp.rechaza('H02-evento-update',format($$UPDATE evento_solicitud SET razon='Otra' WHERE id_evento_solicitud=%s$$,:aprobacion),'P2001');
SELECT pg_temp.rechaza('H02-evento-delete',format($$DELETE FROM evento_solicitud WHERE id_evento_solicitud=%s$$,:entrevista),'P2001');
SELECT pg_temp.rechaza('H02-compatibilidad-update',format($$UPDATE compatibilidad_animal_hogar SET resultado='FAVORABLE' WHERE id_compatibilidad=%s$$,:no_favorable),'P2001');
SELECT pg_temp.rechaza('H02-compatibilidad-delete',format($$DELETE FROM compatibilidad_animal_hogar WHERE id_compatibilidad=%s$$,:favorable),'P2001');
-- Capturar resultados de esta transacción antes de revertir sus fixtures.
SELECT codigo,esperado,observado FROM resultado_paula ORDER BY codigo;
ROLLBACK;

-- P12 | Restricciones diferidas: se comprueban al confirmar, sin imponer un plazo en días.
BEGIN;
INSERT INTO animal(codigo_interno,especie) VALUES('PA-INICIAL','PERRO');
SELECT pg_temp.rechaza('P12-ingreso-sin-inicial',$$INSERT INTO ingreso
    (animal_codigo,fecha_ingreso,lugar_ingreso,condicion_general,circunstancia_ingreso)
    VALUES('PA-INICIAL','2026-10-04','Sede ficticia','Alerta','RESCATE');
    SET CONSTRAINTS ingreso_inicial_paula IMMEDIATE$$,'P2013');
SELECT pg_temp.rechaza('P12-solicitud-sin-recepcion',$$INSERT INTO solicitud_adopcion
    (clave_operacion,solicitante_id,fecha_solicitud,informacion_vivienda,integrantes_hogar,experiencia_animales,condiciones_cuidado)
    VALUES('05000000-0000-0000-0000-000000000121',101,'2026-10-10','V','I','E','C');
    SET CONSTRAINTS solicitud_recepcion IMMEDIATE$$,'P2020');
SELECT codigo,esperado,observado FROM resultado_paula WHERE codigo LIKE 'P12-%' ORDER BY codigo;
ROLLBACK;

-- P13 | Dos etapas del mismo animal con iniciales independientes y frontera de cierre.
BEGIN;
INSERT INTO animal(codigo_interno,especie) VALUES('PA-ETAPAS','PERRO');
INSERT INTO ingreso(animal_codigo,fecha_ingreso,lugar_ingreso,condicion_general,circunstancia_ingreso)
    VALUES('PA-ETAPAS','2026-10-04','Sede ficticia','Alerta','RESCATE') RETURNING id_ingreso AS etapa_a \gset
INSERT INTO evaluacion_salud(animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion)
    VALUES('PA-ETAPAS',:etapa_a,'INICIAL','2026-10-04');
UPDATE ingreso SET fecha_cierre='2026-10-05' WHERE id_ingreso=:etapa_a;
INSERT INTO ingreso(animal_codigo,fecha_ingreso,lugar_ingreso,condicion_general,circunstancia_ingreso,detalle_circunstancia)
    VALUES('PA-ETAPAS','2026-10-05','Sede ficticia','Alerta','OTRA','Continuación ficticia de cuidado') RETURNING id_ingreso AS etapa_b \gset
SELECT pg_temp.rechaza('P13-revision-sin-inicial-etapa',format($$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion,veterinario_id,registro_veterinario_id,motivo,observaciones,peso,recomendaciones)
    VALUES('PA-ETAPAS',%s,'REVISION_VETERINARIA','2026-10-05',7,8,'M','O',1,'R')$$,:etapa_b),'P2011');
SELECT pg_temp.rechaza('P13-evaluacion-fin-etapa',format($$INSERT INTO evaluacion_salud
    (animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion)
    VALUES('PA-ETAPAS',%s,'INICIAL','2026-10-05')$$,:etapa_a),'P2010');
INSERT INTO evaluacion_salud(animal_codigo,ingreso_id,tipo_evaluacion,fecha_evaluacion)
    VALUES('PA-ETAPAS',:etapa_b,'INICIAL','2026-10-05');
COMMIT;
SELECT pg_temp.comprueba('P13-iniciales-por-etapa',
    (SELECT count(*)=2 AND count(DISTINCT ingreso_id)=2 FROM evaluacion_salud WHERE animal_codigo='PA-ETAPAS'),
    (SELECT jsonb_agg(to_jsonb(e) ORDER BY fecha_evaluacion) FROM evaluacion_salud e WHERE animal_codigo='PA-ETAPAS'));

-- P14 | Permisos: no se conceden DML, TRUNCATE, secuencias ni primitivas privadas.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_temp.rechaza('P14-evento-directo',$$INSERT INTO evento_solicitud(clave_operacion) VALUES('05000000-0000-0000-0000-000000000122')$$,'42501');
SELECT pg_temp.rechaza('P14-solicitud-update',$$UPDATE solicitud_adopcion SET informacion_vivienda='X'$$,'42501');
SELECT pg_temp.rechaza('P14-compatibilidad-delete',$$DELETE FROM compatibilidad_animal_hogar$$,'42501');
SELECT pg_temp.rechaza('P14-truncate',$$TRUNCATE evento_solicitud$$,'42501');
SELECT pg_temp.rechaza('P14-primitiva',$$SELECT _exigir_compatibilidad(1,'HS-01',1,'2026-10-10')$$,'42501');
SELECT codigo,esperado,observado FROM resultado_paula WHERE codigo LIKE 'P14-%' ORDER BY codigo;
ROLLBACK;
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT pg_temp.rechaza('P14-aislamiento',$$SELECT asociar_animal(1,'HS-03','2026-10-10')$$,'P1001');
SELECT codigo,esperado,observado FROM resultado_paula WHERE codigo='P14-aislamiento';
ROLLBACK;

-- P15 | Lectura final después de COMMIT/ROLLBACK. No se suplanta RESERVA pendiente.
SELECT pg_temp.comprueba('P15-final',
    (SELECT count(*)=5 FROM solicitud_adopcion) AND (SELECT count(*)=4 FROM solicitud_animal)
    AND (SELECT count(*)=3 FROM compatibilidad_animal_hogar)
    AND (SELECT count(*)=21 FROM evaluacion_salud)
    AND (SELECT count(*)=2 FROM cambio_disponibilidad)
    AND (SELECT lugar_aproximado IS NULL FROM reporte WHERE id_reporte=2)
    AND EXISTS (SELECT FROM reporte_animal WHERE reporte_id=1 AND animal_codigo='HS-02')
    AND (SELECT estado='APROBADA' AND decision_id=:aprobacion FROM estado_actual_solicitud WHERE id_solicitud=:general)
    AND NOT EXISTS (SELECT FROM evento_solicitud WHERE clave_operacion='05000000-0000-0000-0000-000000000107')
    AND to_regclass('huellas.reserva') IS NULL,
    jsonb_build_object('solicitudes',(SELECT count(*) FROM solicitud_adopcion),
        'compatibilidades',(SELECT count(*) FROM compatibilidad_animal_hogar),'evaluaciones',(SELECT count(*) FROM evaluacion_salud),
        'disponibilidades',(SELECT count(*) FROM cambio_disponibilidad),'reserva',to_regclass('huellas.reserva')));
SELECT codigo,esperado,observado FROM resultado_paula ORDER BY codigo;
SELECT id_solicitud,solicitante_id,estado,decision_id,es_general FROM estado_actual_solicitud ORDER BY id_solicitud;
SELECT solicitud_id,animal_codigo,ingreso_id,resultado,fecha FROM compatibilidad_vigente ORDER BY solicitud_id,animal_codigo;
