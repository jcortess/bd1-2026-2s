\set ON_ERROR_STOP on
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';

CREATE FUNCTION pg_temp.espera(p_caso text, p_sql text, p_estado text, p_restriccion text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    estado text;
    restriccion text;
    mensaje text;
BEGIN
    BEGIN
        EXECUTE p_sql;
        RAISE EXCEPTION 'La prueba % debía rechazar la sentencia', p_caso;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS estado = RETURNED_SQLSTATE, restriccion = CONSTRAINT_NAME, mensaje = MESSAGE_TEXT;
        IF estado <> p_estado OR (p_restriccion IS NOT NULL AND restriccion <> p_restriccion) THEN
            RAISE;
        END IF;
        RAISE NOTICE '% rechazada % [%] %', p_caso, estado, restriccion, mensaje;
    END;
END
$$;

CREATE FUNCTION pg_temp.comprueba(p_caso text, p_cumple boolean) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF p_cumple IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'La comprobación % no se cumple', p_caso;
    END IF;
    RAISE NOTICE '% comprobada', p_caso;
END
$$;

-- M01–M03 | AC-01/02, RN-05/06. La sala está vacía. Dos altas deben ocupar
-- exactamente dos cupos. La tercera, una condición distinta y una fecha
-- anterior al ingreso se rechazan y no crean estancias.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT mover_animal(1, NULL, 1, '2026-10-04 08:00', 1, 'CONVIVENCIA') AS luna_sala \gset
SELECT mover_animal(2, NULL, 1, '2026-10-04 08:30', 1, 'CONVIVENCIA') AS milo_sala \gset
SELECT pg_temp.espera('M02-exceso',
    $$SELECT mover_animal(4,NULL,1,'2026-10-04 09:00',1,'CONVIVENCIA')$$, 'P1014');
SELECT pg_temp.espera('M02-condicion',
    $$SELECT mover_animal(4,NULL,1,'2026-10-04 09:00',1,'AISLAMIENTO')$$, 'P1010');
SELECT pg_temp.espera('M03-ingreso',
    $$SELECT mover_animal(4,NULL,3,'2026-10-04 07:59:59.999999',1)$$, 'P1005');
SELECT pg_temp.espera('M03-retroactivo',
    $$SELECT mover_animal(4,NULL,1,'2026-10-04 08:10',1,'CONVIVENCIA')$$, 'P1014');
COMMIT;

SELECT pg_temp.comprueba('M01–M03 después del COMMIT',
    (SELECT ocupacion = 2 AND saldo_fisico = 0 FROM ocupacion_actual WHERE id_ubicacion = 1)
    AND (SELECT count(*) = 2 FROM estancia)
    AND EXISTS (SELECT FROM ubicacion_actual WHERE id_estancia = :luna_sala AND ingreso_id = 1
               AND animal_codigo = 'HS-01' AND ubicacion_id = 1 AND actor_entrada_id = 1)
    AND EXISTS (SELECT FROM ubicacion_actual WHERE id_estancia = :milo_sala AND ingreso_id = 2
               AND animal_codigo = 'HS-02' AND ubicacion_id = 1 AND actor_entrada_id = 1));

-- M04, M05 | AC-01/03, RN-05/07/14. La alta duplicada, la ausencia de
-- valoración y el hogar pendiente se rechazan. El último error se obtiene
-- después de intentar cerrar la sala. Persiste la fila previa intacta.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_temp.espera('M04-doble', $$SELECT mover_animal(1,NULL,3,'2026-10-05',1)$$, 'P1006');
SELECT pg_temp.espera('M04-valoracion', format(
    $$SELECT mover_animal(1,%s,3,'2026-10-05',7)$$, :luna_sala), 'P1008');
SELECT pg_temp.espera('M05-atomica', format(
    $$SELECT mover_animal(1,%s,4,'2026-10-05',7,NULL,'2026-10-05','2026-10-09',NULL,'Traslado sin incidencia sanitaria')$$,
    :luna_sala), 'P1012');
COMMIT;
SELECT pg_temp.comprueba('M04–M05 después del COMMIT',
    (SELECT fecha_fin_real IS NULL AND actor_salida_id IS NULL AND ubicacion_id = 1
     FROM estancia WHERE id_estancia = :luna_sala)
    AND (SELECT count(*) = 1 FROM estancia WHERE ingreso_id = 1)
    AND (SELECT ocupacion = 0 FROM ocupacion_actual WHERE id_ubicacion = 4));

-- M06–M08 | AC-01/02/03, RN-05/06/07/08/14. Se acepta la llegada al
-- inicio exacto de la oferta. La salida de la sala libera un cupo en ese
-- instante. El hogar rechaza cupo, especie y fechas fuera del periodo.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT mover_animal(1, :luna_sala, 2, '2026-10-05', 7, NULL, '2026-10-05', '2026-10-10',
                    'Reposo según el acuerdo', 'Se valoró recuperación y se acordó reposo') AS luna_casa \gset
SELECT mover_animal(16, NULL, 1, '2026-10-05', 1, 'CONVIVENCIA') AS canela_sala \gset
SELECT pg_temp.espera('M07-especie', $$SELECT mover_animal(3,NULL,2,'2026-10-06',1,NULL,
    '2026-10-06','2026-10-07')$$, 'P1013');
SELECT pg_temp.espera('M07-sin-especies', $$SELECT mover_animal(4,NULL,11,'2026-10-06',1,NULL,
    '2026-10-06','2026-10-07')$$, 'P1013');
SELECT pg_temp.espera('M07-cupo', $$SELECT mover_animal(4,NULL,2,'2026-10-06',1,NULL,
    '2026-10-06','2026-10-07')$$, 'P1014');
SELECT pg_temp.espera('M08-antes', $$SELECT mover_animal(4,NULL,2,'2026-10-04 23:59:59.999999',1,NULL,
    '2026-10-05','2026-10-07')$$, 'P1011');
SELECT pg_temp.espera('M08-fin', $$SELECT mover_animal(4,NULL,2,'2026-10-10',1,NULL,
    '2026-10-09','2026-10-10')$$, 'P1011');
SELECT pg_temp.espera('M08-plan-fuera', $$SELECT mover_animal(4,NULL,2,'2026-10-06',1,NULL,
    '2026-10-06','2026-10-10 00:00:00.000001')$$, 'P1011');
SELECT pg_temp.espera('M08-sin-plan', $$SELECT mover_animal(4,NULL,2,'2026-10-06',1)$$, 'P1011');
SELECT pg_temp.espera('M08-vigencia-siguiente-oferta', $$SELECT mover_animal(4,NULL,6,'2026-10-10',1,NULL,
    '2026-10-10','2026-10-11')$$, 'P1014');
COMMIT;

SELECT pg_temp.comprueba('M06–M08 después del COMMIT',
    EXISTS (SELECT FROM estancia WHERE id_estancia = :luna_sala AND fecha_fin_real = '2026-10-05'
                                      AND actor_salida_id = 7)
    AND EXISTS (SELECT FROM ubicacion_actual WHERE id_estancia = :luna_casa AND animal_codigo = 'HS-01'
        AND ingreso_id = 1 AND ubicacion_id = 2 AND persona_oferente_id = 2 AND aprobacion_hogar_id = 2
        AND fecha_inicio_real = '2026-10-05' AND fecha_inicio_prevista = '2026-10-05'
        AND fecha_fin_prevista = '2026-10-10' AND actor_entrada_id = 7 AND actor_salida_id IS NULL
        AND condicion_especial = 'Reposo según el acuerdo'
        AND valoracion_sanitaria = 'Se valoró recuperación y se acordó reposo')
    AND EXISTS (SELECT FROM estancia WHERE id_estancia = :canela_sala AND fecha_inicio_real = '2026-10-05')
    AND NOT EXISTS (SELECT FROM estancia WHERE ingreso_id IN (3,4))
    AND (SELECT ocupacion = 1 AND saldo_fisico = 0 FROM ocupacion_actual WHERE id_ubicacion = 2));

-- M09–M11 | AC-01/02, RN-05/07/08/14. El límite de participación se
-- comprueba a ambos lados. Aprobación simultánea no cuenta como previa.
-- La salida de Casa A permite reusar su cupo a la misma hora de cambio de oferta.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_temp.espera('M09-vigencia', $$SELECT mover_animal(5,NULL,5,'2026-10-06 10:00',1,NULL,
    '2026-10-06','2026-10-07')$$, 'P1012');
SELECT mover_animal(5,NULL,5,'2026-10-06 09:59:59.999999',1,NULL,'2026-10-06','2026-10-07') AS alba_casa \gset
SELECT pg_temp.espera('M09-aprobacion', $$SELECT mover_animal(6,NULL,10,'2026-10-06 10:00',1,NULL,
    '2026-10-06','2026-10-07')$$, 'P1012');
SELECT mover_animal(6,NULL,10,'2026-10-06 10:00:00.000001',1,NULL,'2026-10-06','2026-10-07') AS tico_casa \gset
SELECT pg_temp.espera('M10-periodo-cero', format(
    $$SELECT mover_animal(1,%s,3,'2026-10-05',7,p_valoracion_sanitaria => 'Sin incidencia')$$, :luna_casa),
    'P1005');
SELECT mover_animal(1, :luna_casa, 3, '2026-10-10', 1,
                    p_valoracion_sanitaria => 'Atención externa acordada') AS luna_externa \gset
SELECT mover_animal(4,NULL,6,'2026-10-10',7,NULL,'2026-10-10','2026-10-15') AS nilo_casa \gset
SELECT mover_animal(3,NULL,3,'2026-10-04 09:00',1) AS nube_externa \gset
SELECT mover_animal(4,:nilo_casa,3,'2026-10-15 00:00:00.000001',7,
                    p_valoracion_sanitaria => 'Salida real registrada tras el plazo') AS nilo_externa \gset
COMMIT;

SELECT pg_temp.comprueba('M09–M11 después del COMMIT',
    EXISTS (SELECT FROM historial_alojamiento WHERE id_estancia = :luna_casa AND fecha_fin_real = '2026-10-10'
        AND actor_salida_id = 1 AND persona_oferente_id = 2 AND aprobacion_hogar_id = 2 AND NOT rebasa_oferta)
    AND EXISTS (SELECT FROM historial_alojamiento WHERE id_estancia = :nilo_casa AND fecha_inicio_real = '2026-10-10'
        AND fecha_fin_real = '2026-10-15 00:00:00.000001' AND persona_oferente_id = 5
        AND aprobacion_hogar_id = 5 AND rebasa_oferta)
    AND EXISTS (SELECT FROM ubicacion_actual WHERE id_estancia = :alba_casa AND aprobacion_hogar_id = 4)
    AND EXISTS (SELECT FROM ubicacion_actual WHERE id_estancia = :tico_casa AND aprobacion_hogar_id = 6)
    AND (SELECT array_agg(id_estancia ORDER BY id_estancia) FROM ubicacion_actual WHERE ubicacion_id = 3)
        = ARRAY[:luna_externa, :nube_externa, :nilo_externa]::bigint[]
    AND (SELECT ocupacion = 3 AND capacidad IS NULL AND saldo_fisico IS NULL
         FROM ocupacion_actual WHERE id_ubicacion = 3)
    AND (SELECT count(*) = 3 FROM historial_alojamiento WHERE ingreso_id = 1));

-- I01–I09 | Identidad, vínculos, dominios e historia. Las filas referidas
-- por las pruebas contextuales sí existen. Solo las pruebas FK de ausencia
-- usan 9999. Se exigen tanto el SQLSTATE como la restricción esperada.
BEGIN;
SELECT pg_temp.espera('I01-persona-pk', $$INSERT INTO persona(id_persona) VALUES(1)$$, '23505', 'persona_pkey');
SELECT pg_temp.espera('I01-persona-dominio', $$INSERT INTO persona(nombre_identificacion) VALUES('  ')$$,
    '23514', 'texto_no_vacio_check');
SELECT pg_temp.espera('I01-persona-delete', $$DELETE FROM persona WHERE id_persona=2$$,
    '23503', 'medio_contacto_persona_id_fkey');
SELECT pg_temp.espera('I02-contacto-pk', $$INSERT INTO medio_contacto VALUES(1,2,'CORREO','duplicado@example.invalid')$$,
    '23505', 'medio_contacto_pkey');
SELECT pg_temp.espera('I02-contacto-referencia', $$UPDATE medio_contacto SET persona_id=9999 WHERE id_medio=1$$,
    '23503', 'medio_contacto_persona_id_fkey');
SELECT pg_temp.espera('I02-contacto-nulo', $$INSERT INTO medio_contacto(persona_id,tipo_medio) VALUES(2,'CORREO')$$,
    '23502');
SELECT pg_temp.espera('I03-participacion-pk', $$INSERT INTO participacion
    (id_participacion,persona_id,tipo_participacion,fecha_inicio) VALUES(1,1,'VOLUNTARIO','2026-10-01')$$,
    '23505', 'participacion_pkey');
SELECT pg_temp.espera('I03-participacion-persona', $$UPDATE participacion SET persona_id=9999 WHERE id_participacion=7$$,
    '23503', 'participacion_persona_id_fkey');
SELECT pg_temp.espera('I03-participacion-periodo', $$UPDATE participacion SET fecha_fin=fecha_inicio
    WHERE id_participacion=7$$, '23514', 'participacion_periodo');
SELECT pg_temp.espera('I03-participacion-aprobacion', $$UPDATE participacion SET estado_aprobacion_registro='APROBADO'
    WHERE id_participacion=3$$, '23514', 'participacion_aprobacion');
SELECT pg_temp.espera('I03-participacion-historia', $$UPDATE participacion SET persona_id=5 WHERE id_participacion=2$$,
    'P1002');
SELECT pg_temp.espera('I03-participacion-caducidad', $$UPDATE participacion SET fecha_fin='2026-10-05'
    WHERE id_participacion=2$$, 'P1002');
SELECT pg_temp.espera('I03-participacion-delete', $$DELETE FROM participacion WHERE id_participacion=2$$,
    '23503', 'estancia_aprobacion_hogar_id_fkey');
SELECT pg_temp.espera('I04-animal-pk', $$INSERT INTO animal(codigo_interno,especie) VALUES('HS-01','PERRO')$$,
    '23505', 'animal_pkey');
SELECT pg_temp.espera('I04-especie-nula', $$INSERT INTO animal(codigo_interno) VALUES('HS-NUEVO')$$, '23502');
SELECT pg_temp.espera('I04-microchip', $$UPDATE animal SET numero_microchip='000451' WHERE codigo_interno='HS-02'$$,
    '23505', 'animal_numero_microchip_key');
SELECT pg_temp.espera('I04-edad', $$UPDATE animal SET edad_estimada=-1 WHERE codigo_interno='HS-02'$$,
    '23514', 'animal_edad_estimada_check');
SELECT pg_temp.espera('I04-especie-formato', $$UPDATE animal SET especie='Perro' WHERE codigo_interno='HS-07'$$,
    '23514', 'especie_animal_check');
SELECT pg_temp.espera('I04-especie-historica', $$UPDATE animal SET especie='GATO' WHERE codigo_interno='HS-01'$$,
    'P1002');
SELECT pg_temp.espera('I04-codigo', $$UPDATE animal SET codigo_interno='HS-NUEVO' WHERE codigo_interno='HS-01'$$,
    'P1002');
SELECT pg_temp.espera('I05-organizacion-pk',
    $$INSERT INTO organizacion_externa VALUES(1,'Organización de prueba')$$, '23505', 'organizacion_externa_pkey');
SELECT pg_temp.espera('I05-organizacion-nombre', $$INSERT INTO organizacion_externa(nombre_organizacion) VALUES(null)$$,
    '23502');
SELECT pg_temp.espera('I05-organizacion-delete', $$DELETE FROM organizacion_externa WHERE id_organizacion=1$$,
    '23503', 'ingreso_organizacion_origen_id_fkey');
SELECT pg_temp.espera('I06-ingreso-pk', $$INSERT INTO ingreso
    (id_ingreso,animal_codigo,fecha_ingreso,lugar_ingreso,condicion_general,circunstancia_ingreso,fecha_cierre)
    VALUES(1,'HS-07','2026-10-01','Sede','Estable','RESCATE','2026-10-02')$$, '23505', 'ingreso_pkey');
SELECT pg_temp.espera('I06-propietario', $$UPDATE ingreso SET propietario_anterior_id=9999 WHERE id_ingreso=7$$,
    '23503', 'ingreso_propietario_anterior_id_fkey');
SELECT pg_temp.espera('I06-traslado', $$UPDATE ingreso SET organizacion_origen_id=NULL WHERE id_ingreso=2$$,
    '23514', 'ingreso_organizacion');
SELECT pg_temp.espera('I06-otra', $$UPDATE ingreso SET circunstancia_ingreso='OTRA' WHERE id_ingreso=7$$,
    '23514', 'ingreso_detalle');
SELECT pg_temp.espera('I06-periodo', $$UPDATE ingreso SET fecha_ingreso='infinity' WHERE id_ingreso=7$$,
    '23514', 'instante_check');
SELECT pg_temp.espera('I06-solape', $$INSERT INTO ingreso
    (animal_codigo,fecha_ingreso,lugar_ingreso,condicion_general,circunstancia_ingreso)
    VALUES('HS-01','2026-10-06','Sede','Estable','RESCATE')$$, '23P01', 'ingreso_etapas_no_solapan');
SELECT pg_temp.espera('I06-contexto-modificacion', $$UPDATE ingreso SET fecha_ingreso='2026-10-04 08:01'
    WHERE id_ingreso=1$$, 'P1002');
SELECT pg_temp.espera('I06-cierre-directo', $$UPDATE ingreso SET fecha_cierre='2026-10-20'
    WHERE id_ingreso=1$$, 'P1002');
SELECT pg_temp.espera('I06-ingreso-delete', $$DELETE FROM ingreso WHERE id_ingreso=1$$,
    '23503', 'estancia_ingreso_animal_fk');
SELECT pg_temp.espera('I07-ubicacion-pk', $$INSERT INTO ubicacion(id_ubicacion,tipo_ubicacion,nombre_descripcion)
    VALUES(1,'ATENCION_EXTERNA','Lugar de prueba')$$, '23505', 'ubicacion_pkey');
SELECT pg_temp.espera('I07-capacidad', $$INSERT INTO ubicacion(tipo_ubicacion,nombre_descripcion,capacidad,condicion_admitida)
    VALUES('AREA_INTERNA','Sala de prueba',0,'CONVIVENCIA')$$, '23514', 'ubicacion_capacidad_check');
SELECT pg_temp.espera('I07-condicion', $$INSERT INTO ubicacion(tipo_ubicacion,nombre_descripcion,capacidad)
    VALUES('AREA_INTERNA','Sala de prueba',1)$$, '23514', 'ubicacion_por_tipo');
SELECT pg_temp.espera('I07-externa', $$INSERT INTO ubicacion(tipo_ubicacion,nombre_descripcion,capacidad)
    VALUES('ATENCION_EXTERNA','Centro de prueba',1)$$, '23514', 'ubicacion_por_tipo');
SELECT pg_temp.espera('I07-hogar-sin-oferente', $$UPDATE ubicacion SET persona_oferente_id=NULL WHERE id_ubicacion=4$$,
    '23514', 'ubicacion_por_tipo');
SELECT pg_temp.espera('I07-hogar-oferente-fk', $$UPDATE ubicacion SET persona_oferente_id=9999 WHERE id_ubicacion=4$$,
    '23503', 'ubicacion_persona_oferente_id_fkey');
SELECT pg_temp.espera('I07-ofertas-solapadas', $$UPDATE ubicacion SET codigo_hogar='CASA-A' WHERE id_ubicacion=4$$,
    '23P01', 'ubicacion_ofertas_no_solapan');
SELECT pg_temp.espera('I07-oferente-historico', $$UPDATE ubicacion SET persona_oferente_id=5 WHERE id_ubicacion=2$$,
    'P1002');
SELECT pg_temp.espera('I07-capacidad-historica', $$UPDATE ubicacion SET capacidad=10 WHERE id_ubicacion=1$$, 'P1002');
SELECT pg_temp.espera('I07-ubicacion-delete', $$DELETE FROM ubicacion WHERE id_ubicacion=3$$,
    '23503', 'estancia_ubicacion_id_fkey');
SELECT pg_temp.espera('I08-especie-pk', $$INSERT INTO ubicacion_especie_aceptada VALUES(2,'PERRO')$$,
    '23505', 'ubicacion_especie_aceptada_pkey');
SELECT pg_temp.espera('I08-especie-nula', $$INSERT INTO ubicacion_especie_aceptada VALUES(2,NULL)$$, '23502');
SELECT pg_temp.espera('I08-especie-tipo', $$INSERT INTO ubicacion_especie_aceptada VALUES(1,'PERRO')$$, 'P1003');
SELECT pg_temp.espera('I08-especie-referencia', $$INSERT INTO ubicacion_especie_aceptada VALUES(9999,'PERRO')$$,
    '23503', 'ubicacion_especie_aceptada_ubicacion_id_fkey');
SELECT pg_temp.espera('I08-especie-historica', $$DELETE FROM ubicacion_especie_aceptada
    WHERE ubicacion_id=2 AND especie='PERRO'$$, 'P1002');
SELECT pg_temp.espera('I09-estancia-pk', format($$INSERT INTO estancia
    (id_estancia,animal_codigo,ingreso_id,ubicacion_id,fecha_inicio_real,actor_entrada_id)
    VALUES(%s,'HS-07',7,3,'2026-10-06',1)$$, :luna_sala), '23505', 'estancia_pkey');
SELECT pg_temp.espera('I09-contexto', $$INSERT INTO estancia
    (animal_codigo,ingreso_id,ubicacion_id,fecha_inicio_real,actor_entrada_id)
    VALUES('HS-07',8,3,'2026-10-06',1)$$, '23503', 'estancia_ingreso_animal_fk');
SELECT pg_temp.espera('I09-vigente', $$INSERT INTO estancia
    (animal_codigo,ingreso_id,ubicacion_id,fecha_inicio_real,actor_entrada_id)
    VALUES('HS-01',1,3,'2026-10-20',1)$$, '23P01', 'estancia_no_solapa');
SELECT pg_temp.espera('I09-cierre', $$UPDATE estancia SET actor_salida_id=NULL
    WHERE animal_codigo='HS-01' AND ubicacion_id=2$$, '23514', 'estancia_cierre');
SELECT pg_temp.espera('I09-prevision', $$UPDATE estancia SET fecha_inicio_prevista=NULL
    WHERE animal_codigo='HS-01' AND ubicacion_id=2$$, '23514', 'estancia_periodo_previsto');
SELECT pg_temp.espera('I09-actor', $$SELECT mover_animal(7,NULL,3,'2026-10-06',9999)$$,
    '23503', 'estancia_actor_entrada_id_fkey');

-- I10 | RN-23. Regreso requiere receptor y motivo. Con ambos presentes la
-- restricción de integración impide activar una referencia a una adopción ausente.
SELECT pg_temp.espera('I10-receptor', $$UPDATE ingreso SET circunstancia_ingreso='DEVOLUCION',
    detalle_circunstancia='Motivo ficticio', adopcion_origen_id=90 WHERE id_ingreso=7$$,
    '23514', 'ingreso_receptor');
SELECT pg_temp.espera('I10-motivo', $$UPDATE ingreso SET circunstancia_ingreso='RECUPERACION',
    adopcion_origen_id=90,receptor_devolucion_id=1 WHERE id_ingreso=7$$, '23514', 'ingreso_detalle');
SELECT pg_temp.espera('I10-origen', $$UPDATE ingreso SET circunstancia_ingreso='DEVOLUCION',
    detalle_circunstancia='Motivo ficticio', receptor_devolucion_id=1 WHERE id_ingreso=7$$,
    '23514', 'ingreso_origen_adopcion');
SELECT pg_temp.espera('I10-integracion', $$UPDATE ingreso SET circunstancia_ingreso='DEVOLUCION',
    detalle_circunstancia='Motivo ficticio', adopcion_origen_id=90,receptor_devolucion_id=1 WHERE id_ingreso=7$$,
    '23514', 'zz_ingreso_adopcion_pendiente');
SELECT pg_temp.espera('I10-receptor-no-aplica', $$UPDATE ingreso SET receptor_devolucion_id=1 WHERE id_ingreso=7$$,
    '23514', 'ingreso_receptor');
SELECT pg_temp.comprueba('I10-FK del receptor validada en catálogo',
    EXISTS (SELECT FROM pg_constraint WHERE conrelid = 'ingreso'::regclass AND confrelid = 'persona'::regclass
        AND convalidated AND pg_get_constraintdef(oid) LIKE 'FOREIGN KEY (receptor_devolucion_id)%'));

-- I11 | AC-01/03 y contrato con P03. El dueño prueba la primitiva en una
-- transacción reversible, con salida y etapa cerradas en el mismo instante.
SELECT _cerrar_etapa_alojamiento(1, :luna_externa, '2026-10-20', 7) AS estancia_cerrada \gset
SELECT pg_temp.comprueba('I11-cierre y contexto dentro de la transacción',
    :estancia_cerrada = :luna_externa
    AND EXISTS (SELECT FROM ingreso WHERE id_ingreso=1 AND fecha_cierre='2026-10-20')
    AND EXISTS (SELECT FROM estancia WHERE id_estancia=:luna_externa AND fecha_fin_real='2026-10-20'
                                      AND actor_salida_id=7)
    AND NOT EXISTS (SELECT FROM ubicacion_actual WHERE ingreso_id=1));
SELECT pg_temp.espera('I11-etapa-cerrada', $$SELECT mover_animal(1,NULL,3,'2026-10-21',1)$$, 'P1004');
INSERT INTO ingreso (animal_codigo,fecha_ingreso,lugar_ingreso,condicion_general,circunstancia_ingreso,detalle_circunstancia)
VALUES ('HS-01','2026-10-20','Sede','En cuidado','OTRA','Continuación de cuidados') RETURNING id_ingreso AS nuevo_ingreso \gset
SELECT mover_animal(:nuevo_ingreso,NULL,3,'2026-10-20',7) AS nueva_etapa \gset
SELECT pg_temp.comprueba('I11-nueva etapa en la frontera',
    EXISTS (SELECT FROM ubicacion_actual WHERE id_estancia=:nueva_etapa AND ingreso_id=:nuevo_ingreso
         AND animal_codigo='HS-01' AND fecha_inicio_real='2026-10-20')
    AND (SELECT count(*) = 3 FROM estancia WHERE ingreso_id=1));
ROLLBACK;

-- I12 | El rol de operación solo puede escribir mediante mover_animal.
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_temp.espera('I12-estancia-delete', $$DELETE FROM estancia WHERE ingreso_id=1$$, '42501');
SELECT pg_temp.espera('I12-estancia-update', $$UPDATE estancia SET fecha_fin_real=NULL WHERE ingreso_id=1$$, '42501');
SELECT pg_temp.espera('I12-estancia-insert', $$INSERT INTO estancia
    (animal_codigo,ingreso_id,ubicacion_id,fecha_inicio_real,actor_entrada_id)
    VALUES('HS-07',7,3,'2026-10-06',1)$$, '42501');
SELECT pg_temp.espera('I12-catalogo', $$UPDATE ubicacion SET capacidad=10 WHERE id_ubicacion=4$$, '42501');
SELECT pg_temp.espera('I12-participacion-delete', $$DELETE FROM participacion WHERE id_participacion=3$$, '42501');
SELECT pg_temp.espera('I12-cierre-privado', $$SELECT _cerrar_etapa_alojamiento(1,NULL,'2026-10-20',7)$$, '42501');
SELECT pg_temp.espera('I12-truncate', $$TRUNCATE estancia$$, '42501');
ROLLBACK;

BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_temp.espera('I12-aislamiento', $$SELECT mover_animal(7,NULL,3,'2026-10-06',1)$$, 'P1001');
ROLLBACK;

SELECT pg_temp.comprueba('I01–I12 después de los ROLLBACK',
    EXISTS (SELECT FROM persona p WHERE p.id_persona = 8 AND p.nombre_identificacion IS NULL)
    AND EXISTS (SELECT FROM medio_contacto WHERE id_medio=1 AND persona_id=2 AND tipo_medio='CORREO'
                                            AND valor='oferente-a@example.invalid')
    AND EXISTS (SELECT FROM participacion WHERE id_participacion=8 AND persona_id=7 AND tipo_participacion='VETERINARIO'
                                            AND estado_aprobacion_registro='REGISTRADO')
    AND (SELECT especie='PERRO' AND edad_estimada=18 AND numero_microchip='000451'
         FROM animal WHERE codigo_interno='HS-01')
    AND EXISTS (SELECT FROM ingreso i JOIN organizacion_externa o ON o.id_organizacion=i.organizacion_origen_id
                WHERE i.id_ingreso=2 AND o.nombre_organizacion='Red de rescate ficticia')
    AND EXISTS (SELECT FROM ingreso WHERE id_ingreso=7 AND circunstancia_ingreso='RESCATE'
                                      AND receptor_devolucion_id IS NULL AND adopcion_origen_id IS NULL)
    AND EXISTS (SELECT FROM ingreso WHERE id_ingreso=1 AND fecha_cierre IS NULL)
    AND NOT EXISTS (SELECT FROM ingreso WHERE id_ingreso=:nuevo_ingreso)
    AND EXISTS (SELECT FROM ubicacion_actual WHERE id_estancia=:luna_externa AND ingreso_id=1 AND actor_salida_id IS NULL)
    AND EXISTS (SELECT FROM historial_alojamiento WHERE id_estancia=:luna_casa AND persona_oferente_id=2)
    AND EXISTS (SELECT FROM ubicacion_especie_aceptada WHERE ubicacion_id=2 AND especie='PERRO')
    AND NOT EXISTS (SELECT FROM estancia WHERE ingreso_id IN (7,8)));

SELECT id_estancia, animal_codigo, ingreso_id, ubicacion_id, fecha_inicio_real, fecha_fin_real,
       fecha_inicio_prevista, fecha_fin_prevista, persona_oferente_id, aprobacion_hogar_id,
       actor_entrada_id, actor_salida_id, condicion_especial, valoracion_sanitaria, rebasa_oferta
FROM historial_alojamiento WHERE ingreso_id IN (1,4) ORDER BY ingreso_id, fecha_inicio_real;
SELECT id_ubicacion, capacidad, ocupacion, saldo_fisico FROM ocupacion_actual WHERE id_ubicacion IN (1,2,3,6)
ORDER BY id_ubicacion;
