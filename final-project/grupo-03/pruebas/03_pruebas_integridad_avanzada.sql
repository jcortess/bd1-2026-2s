-- Universidad Horizonte: pruebas de integridad avanzada. Requiere los 81 registros iniciales y los
-- triggers instalados; los casos secuenciales terminan con ROLLBACK.

\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path TO public;
SET LOCAL universidad.autorizador = '1';
SET LOCAL universidad.motivo = 'Comprobacion controlada de integridad';

-- Un rechazo esperado debe coincidir en SQLSTATE 23514 y nombre de restriccion.
CREATE FUNCTION pg_temp.esperar_rechazo(p_caso TEXT, p_orden TEXT, p_constraint TEXT)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_constraint TEXT;
BEGIN
    BEGIN
        EXECUTE p_orden;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'El caso % acepto una operacion que debio rechazarse', p_caso
            USING ERRCODE = 'P0001';
    EXCEPTION WHEN SQLSTATE '23514' THEN
        GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
        IF v_constraint IS DISTINCT FROM p_constraint THEN
            RAISE EXCEPTION '%: rechazo por %, se esperaba %',
                p_caso, v_constraint, p_constraint;
        END IF;
        RAISE NOTICE 'Rechazo correcto: % (%)', p_caso, p_constraint;
    END;
END;
$$;

-- Se comprueban estructura, semilla e instalacion antes de alterar las filas de prueba.
DO $$
DECLARE n_tablas INTEGER; n_columnas INTEGER; n_registros BIGINT; n_triggers INTEGER;
BEGIN
    SELECT COUNT(*) INTO n_tablas FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    SELECT COUNT(*) INTO n_columnas FROM information_schema.columns c
    JOIN information_schema.tables t ON t.table_schema = c.table_schema
        AND t.table_name = c.table_name
    WHERE c.table_schema = 'public' AND t.table_type = 'BASE TABLE';
    SELECT COUNT(*) INTO n_triggers FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND NOT t.tgisinternal
      AND t.tgname IN ('uh_bloquear_contexto','uh_serializar_contexto','uh_validar_contexto',
                      'uh_proteger_historial','uh_auditar_alta','uh_auditar_actualizacion',
                      'uh_validar_cambio_plan','uh_rechazar_truncamiento');
    SELECT
        (SELECT COUNT(*) FROM estudiante) + (SELECT COUNT(*) FROM admision)
      + (SELECT COUNT(*) FROM carrera) + (SELECT COUNT(*) FROM sede)
      + (SELECT COUNT(*) FROM escuela) + (SELECT COUNT(*) FROM docente)
      + (SELECT COUNT(*) FROM persona_autorizadora)
      + (SELECT COUNT(*) FROM periodo_academico) + (SELECT COUNT(*) FROM curso)
      + (SELECT COUNT(*) FROM version_plan_estudios) + (SELECT COUNT(*) FROM carrera_sede)
      + (SELECT COUNT(*) FROM espacio) + (SELECT COUNT(*) FROM contacto_estudiante)
      + (SELECT COUNT(*) FROM ventana_periodo) + (SELECT COUNT(*) FROM participacion_plan)
      + (SELECT COUNT(*) FROM requisito_curso) + (SELECT COUNT(*) FROM grupo)
      + (SELECT COUNT(*) FROM bloque_horario) + (SELECT COUNT(*) FROM traslado_plan)
      + (SELECT COUNT(*) FROM reconocimiento_academico) + (SELECT COUNT(*) FROM grupo_docente)
      + (SELECT COUNT(*) FROM solicitud_matricula) + (SELECT COUNT(*) FROM historial_oferta)
      + (SELECT COUNT(*) FROM historial_solicitud) + (SELECT COUNT(*) FROM excepcion_requisito)
      + (SELECT COUNT(*) FROM historial_correccion_calificacion)
      INTO n_registros;
    IF n_tablas <> 26 OR n_columnas <> 135 OR n_registros <> 81 OR n_triggers <> 94 THEN
        RAISE EXCEPTION 'Instalacion inicial inesperada: tablas %, atributos %, filas %, triggers %',
            n_tablas,n_columnas,n_registros,n_triggers;
    END IF;
    PERFORM public.uh_validar_integridad();
    RAISE NOTICE 'Inventario y datos iniciales correctos: 26 / 135 / 81; triggers %',n_triggers;
END;
$$;

SELECT pg_temp.esperar_rechazo(
    'eliminacion del ultimo contacto de un estudiante admitido',
    $$DELETE FROM contacto_estudiante WHERE id_contacto=3$$,
    'uh_estudiante_contacto');

-- La sede usada existe: debe fallar por incompatibilidad de carrera y sede, no por FK.
SELECT pg_temp.esperar_rechazo(
    'admision en sede no habilitada',
    $$INSERT INTO admision VALUES (90,'UH-ALU2',1,201,DATE '2026-08-15','regular',TRUE)$$,
    'uh_admision_carrera_sede');

SELECT pg_temp.esperar_rechazo(
    'version inicial fuera de vigencia',
    $$INSERT INTO admision VALUES
      (91,'UH-ALU2',1,101,DATE '2026-08-01','regular',TRUE)$$,
    'uh_admision_vigencia_inicial');

-- La admision 3 ya tiene trayectoria; cambiar su sede alteraria su contexto historico.
SELECT pg_temp.esperar_rechazo(
    'sede de admision con trayectoria',
    $$UPDATE admision SET id_sede=2 WHERE id_admision=3$$,
    'uh_admision_historia');

-- La fecha de ingreso esta vinculada a hechos historicos y no puede reescribirse.
SELECT pg_temp.esperar_rechazo(
    'fecha de ingreso con antecedentes',
    $$UPDATE admision SET fecha_ingreso=DATE '2024-09-01'
      WHERE id_admision=3$$,
    'uh_admision_historia');

-- Cambiar el inicio de vigencia de una version utilizada invalidaria una admision existente.
SELECT pg_temp.esperar_rechazo(
    'modificacion de vigencia utilizada',
    $$UPDATE version_plan_estudios SET inicio_vigencia=DATE '2026-09-01'
      WHERE id_version_plan=201$$,
    'uh_version_identidad_historica');

SELECT pg_temp.esperar_rechazo(
    'cambio de plan sin traslado',
    $$UPDATE admision SET id_version_plan=101 WHERE id_admision=3$$,
    'uh_admision_traslado_obligatorio');

-- La habilitacion carrera-sede puede estar en uso aun cuando ambas FK individuales sigan siendo
-- validas.
SELECT pg_temp.esperar_rechazo(
    'eliminacion de sede habilitada',
    $$DELETE FROM carrera_sede WHERE id_carrera=10 AND id_sede=1$$,
    'uh_admision_carrera_sede');

-- El cambio de creditos afectaria retrospectivamente el avance de los planes utilizados.
SELECT pg_temp.esperar_rechazo(
    'creditos de curso curricular utilizado',
    $$UPDATE curso SET cantidad_creditos=5
      WHERE codigo_institucional='UH-PROG1'$$,
    'uh_curso_historico');

-- Actualizacion curricular valida en una version sin solicitudes; se restaura el valor al
-- finalizar.
UPDATE participacion_plan SET tipo_participacion='Obligatorio'
WHERE codigo_curso='UH-RED1' AND id_version_plan=102;
DO $$
BEGIN
    IF (SELECT tipo_participacion FROM participacion_plan
        WHERE codigo_curso='UH-RED1' AND id_version_plan=102)
        IS DISTINCT FROM 'Obligatorio' THEN
        RAISE EXCEPTION 'No se conservo la actualizacion curricular valida';
    END IF;
END;
$$;
UPDATE participacion_plan SET tipo_participacion='Optativo'
WHERE codigo_curso='UH-RED1' AND id_version_plan=102;

SELECT pg_temp.esperar_rechazo(
    'version con carrera historica',
    $$UPDATE version_plan_estudios SET id_carrera=20 WHERE id_version_plan=102$$,
    'uh_version_identidad_historica');

SELECT pg_temp.esperar_rechazo(
    'traslado entre carreras',
    $sql$DO $body$
    BEGIN
      INSERT INTO traslado_plan VALUES
          (900,2,201,102,'2026-10-01 10:00-06','Cambio incompatible',1);
      UPDATE admision SET id_version_plan=102 WHERE id_admision=2;
    END;
    $body$;$sql$,
    'uh_traslado_contexto');

-- Alta curricular valida, seguida de eliminacion para restablecer el escenario.
INSERT INTO participacion_plan (codigo_curso,id_version_plan,tipo_participacion)
VALUES ('UH-RED1',101,'Optativo');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DELETE FROM participacion_plan WHERE codigo_curso='UH-RED1' AND id_version_plan=101;

SELECT pg_temp.esperar_rechazo(
    'traslado que desajusta version final',
    $sql$DO $body$
    BEGIN
      INSERT INTO version_plan_estudios
          (id_version_plan,id_carrera,inicio_vigencia,fin_vigencia)
      VALUES (104,10,DATE '2026-01-01',NULL);
      INSERT INTO traslado_plan VALUES
          (901,3,102,104,'2026-10-01 11:00-06','Cambio no asignado',1);
    END;
    $body$;$sql$,
    'uh_traslado_secuencia');

-- La version destino existe, pero aun no estaba vigente al instante del traslado.
SELECT pg_temp.esperar_rechazo(
    'traslado hacia version aun no vigente',
    $sql$DO $body$
    BEGIN
      INSERT INTO admision VALUES
          (77,'UH-ALU1',1,102,DATE '2024-08-01','regular',TRUE);
      INSERT INTO traslado_plan VALUES
          (902,77,101,102,'2025-12-01 10:00-06','Traslado prematuro',1);
    END;
    $body$;$sql$,
    'uh_traslado_contexto');

-- El destino ya habia vencido, aunque la secuencia y la version final concuerdan.
SELECT pg_temp.esperar_rechazo(
    'traslado a version de destino ya vencida',
    $sql$DO $body$
    BEGIN
      INSERT INTO traslado_plan (id_traslado,id_admision,id_version_origen,
          id_version_destino,fecha,motivo,id_autorizador)
      VALUES (904,3,102,101,'2026-09-03 10:00-06','Version expirada',1);
      UPDATE admision SET id_version_plan=101 WHERE id_admision=3;
    END;
    $body$;$sql$,
    'uh_traslado_contexto');

SELECT pg_temp.esperar_rechazo(
    'traslado anterior a admision',
    $sql$DO $body$
    BEGIN
      INSERT INTO version_plan_estudios
          (id_version_plan,id_carrera,inicio_vigencia,fin_vigencia)
      VALUES (104,10,DATE '2026-05-01',NULL);
      INSERT INTO admision VALUES
          (78,'UH-ALU1',1,104,DATE '2026-08-01','regular',TRUE);
      INSERT INTO traslado_plan VALUES
          (903,78,102,104,'2026-07-01 09:00-06','Traslado anterior a ingreso',1);
    END;
    $body$;$sql$,
    'uh_traslado_contexto');
SELECT pg_temp.esperar_rechazo(
    'inmutabilidad del traslado existente',
    $$UPDATE traslado_plan SET fecha='2026-02-03 09:00-06' WHERE id_traslado=200$$,
    'uh_trayectoria_inmutable');

SELECT pg_temp.esperar_rechazo(
    'eliminacion del traslado historico',
    $$DELETE FROM traslado_plan WHERE id_traslado=200$$,
    'uh_trayectoria_inmutable');
SELECT pg_temp.esperar_rechazo(
    'eliminacion de reconocimiento historico',
    $$DELETE FROM reconocimiento_academico WHERE id_reconocimiento=300$$,
    'uh_trayectoria_inmutable');

-- Dos traslados consecutivos: se contrasta el plan en cada instante de frontera.
INSERT INTO estudiante VALUES ('UH-ALU8','Estudiante','Ocho',NULL);
INSERT INTO contacto_estudiante VALUES (608,'UH-ALU8','correo','alu8@example.test',TRUE);
INSERT INTO version_plan_estudios
    (id_version_plan,id_carrera,inicio_vigencia,fin_vigencia)
VALUES (103,10,DATE '2026-05-01',NULL);
INSERT INTO admision VALUES
    (8,'UH-ALU8',1,103,DATE '2024-08-01','regular',TRUE);
INSERT INTO traslado_plan
    (id_traslado,id_admision,id_version_origen,id_version_destino,
     fecha,motivo,id_autorizador)
VALUES
    (210,8,101,102,'2026-02-02 10:00-06','Primer traslado',1),
    (211,8,102,103,'2026-05-02 10:00-06','Segundo traslado',2);
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
  IF public.uh_plan_aplicable(8,'2025-12-01 10:00-06') IS DISTINCT FROM 101
     OR public.uh_plan_aplicable(8,'2026-02-02 10:00-06') IS DISTINCT FROM 102
     OR public.uh_plan_aplicable(8,'2026-05-02 10:00-06') IS DISTINCT FROM 103 THEN
    RAISE EXCEPTION 'La trayectoria historica de dos traslados no coincide';
  END IF;
END;
$$;

-- Una version preparada, sin decisiones de matricula, admite el cierre de vigencia.
INSERT INTO version_plan_estudios VALUES (190,10,DATE '2026-01-01',NULL);
INSERT INTO participacion_plan (codigo_curso,id_version_plan,tipo_participacion)
VALUES ('UH-RED1',190,'Optativo');
UPDATE version_plan_estudios SET fin_vigencia=DATE '2026-12-31'
WHERE id_version_plan=190;
DO $$
BEGIN
  IF (SELECT fin_vigencia FROM version_plan_estudios WHERE id_version_plan=190)
     IS DISTINCT FROM DATE '2026-12-31' THEN
    RAISE EXCEPTION 'No se conservo la fecha final de la version preparada';
  END IF;
END;
$$;

-- El reconocimiento usa versiones existentes, pero no la aplicable a esa admision.
SELECT pg_temp.esperar_rechazo(
    'reconocimiento de otra carrera',
    $$INSERT INTO reconocimiento_academico VALUES
        (900,1,'EXT-900',NULL,201,'UH-MAT1','RES-900','2026-09-04 10:00-06')$$,
    'uh_reconocimiento_trayectoria');

-- La version 101 tiene la participacion necesaria; el fallo es temporal, posterior al traslado.
SELECT pg_temp.esperar_rechazo(
    'reconocimiento con version historica anterior',
    $$INSERT INTO reconocimiento_academico
       (id_reconocimiento,id_admision,referencia_curso_reconocido,
        id_version_plan,codigo_curso_satisfecho,resolucion_academica,fecha_resolucion)
       VALUES (901,3,'EXT-901',101,'UH-PROG1','RES-901',
               '2026-09-03 10:00-06')$$,
    'uh_reconocimiento_trayectoria');
SELECT pg_temp.esperar_rechazo(
    'inmutabilidad del reconocimiento existente',
    $$UPDATE reconocimiento_academico SET resolucion_academica='RES-MOD'
      WHERE id_reconocimiento=300$$,
    'uh_trayectoria_inmutable');

-- Todos los identificadores existen; la incompatibilidad es de sede.
SELECT pg_temp.esperar_rechazo(
    'espacio de sede diferente',
    $$UPDATE bloque_horario SET id_espacio = 2 WHERE id_bloque = 100$$,
    'uh_bloque_espacio_contexto');

SELECT pg_temp.esperar_rechazo(
    'bloque no presencial en oferta presencial',
    $$INSERT INTO bloque_horario VALUES
        (905,13,6,TIME '08:00',TIME '09:00',FALSE,NULL)$$,
    'uh_bloque_espacio_contexto');

-- El espacio, grupo y dia existen para aislar el solapamiento horario.
SELECT pg_temp.esperar_rechazo(
    'conflicto de espacio',
    $$INSERT INTO bloque_horario VALUES
        (900,13,1,TIME '09:00',TIME '09:30',TRUE,1)$$,
    'uh_espacio_solapamiento');

-- El periodo nuevo coincide en fechas con otro, pero no contiene el dia semanal de ese bloque.
INSERT INTO periodo_academico
    (id_periodo,codigo_periodo,fecha_inicio,fecha_finalizacion)
VALUES (2,'2026-P2',DATE '2026-08-11',DATE '2026-08-11');
INSERT INTO grupo VALUES (16,4,'UH-PROG1',2,1,1,'presencial','cerrada');
INSERT INTO bloque_horario VALUES
    (904,16,1,TIME '08:00',TIME '10:00',TRUE,1);
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- Periodos distintos tambien pueden compartir efectivamente dia y franja, causando conflicto.
INSERT INTO periodo_academico
    (id_periodo,codigo_periodo,fecha_inicio,fecha_finalizacion)
VALUES (4,'2026-P4',DATE '2026-08-10',DATE '2026-08-10');
INSERT INTO grupo VALUES (24,24,'UH-PROG1',4,1,1,'presencial','cerrada');
SELECT pg_temp.esperar_rechazo(
    'choque de espacio entre periodos distintos',
    $$INSERT INTO bloque_horario VALUES
      (924,24,1,TIME '08:30',TIME '09:00',TRUE,1)$$,
    'uh_espacio_solapamiento');

-- Ampliar el calendario lectivo puede crear una colision espacial previamente ausente.
SELECT pg_temp.esperar_rechazo(
    'calendario que introduce conflicto de aula',
    $$UPDATE periodo_academico SET fecha_inicio=DATE '2026-08-10'
      WHERE id_periodo=2$$,
    'uh_espacio_solapamiento');

SELECT pg_temp.esperar_rechazo(
    'cancelacion inicial sin evento historico',
    $$INSERT INTO grupo VALUES (909,909,'UH-PROG1',1,1,1,'virtual','cancelada')$$,
    'uh_grupo_cancelacion_sin_historia');

SELECT pg_temp.esperar_rechazo(
    'publicacion incompleta',
    $$INSERT INTO grupo VALUES
        (900,99,'UH-PROG1',1,2,1,'virtual','abierta')$$,
    'uh_grupo_publicacion');

-- Las franjas contiguas pueden compartir aula: la hora final es exclusiva.
INSERT INTO bloque_horario VALUES
    (901,13,1,TIME '12:00',TIME '13:00',TRUE,1);
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- La apertura de dos grupos genera eventos de historial.
SET LOCAL universidad.instante_efectivo='2026-06-30 12:00-06';
UPDATE grupo SET estado_oferta = 'abierta' WHERE id_grupo IN (11,12);
SET LOCAL universidad.instante_efectivo='';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM historial_oferta WHERE id_grupo IN (11,12)
      AND tipo_cambio='apertura') <> 2 THEN
    RAISE EXCEPTION 'No se registraron las aperturas con su autorizacion';
  END IF;
END;
$$;

-- Se comprueba el instante de apertura, no solo el estado actual del grupo.
DO $$
BEGIN
  IF NOT public.uh_oferta_en_instante(12,'2026-07-02 10:00-06')
     OR public.uh_oferta_en_instante(12,'2026-06-29 10:00-06') THEN
    RAISE EXCEPTION 'La oferta historica no respeta el instante de apertura';
  END IF;
END;
$$;

SET LOCAL universidad.autorizador='';
SELECT pg_temp.esperar_rechazo(
    'modificacion sin actor autorizado',
    $$UPDATE grupo SET capacidad=1 WHERE id_grupo=11$$,
    'uh_oferta_auditoria_obligatoria');
SET LOCAL universidad.autorizador='1';

SELECT pg_temp.esperar_rechazo(
    'cambio de sede con historial de oferta',
    $$UPDATE grupo SET id_sede=2 WHERE id_grupo=12$$,
    'uh_grupo_contexto_historico');

-- El historial no admite transiciones ficticias insertadas desde fuera del hecho.
SELECT pg_temp.esperar_rechazo(
    'insercion manual de historial de oferta',
    $$INSERT INTO historial_oferta
       (id_cambio,id_grupo,tipo_cambio,estado_anterior,estado_nuevo,
        fecha_cambio,motivo,id_responsable)
       VALUES (901,12,'cierre','abierta','cerrada',
               transaction_timestamp()+interval '1 hour',
               'Cierre no realizado',1)$$,
    'uh_historial_evento_automatico');

SELECT pg_temp.esperar_rechazo(
    'eliminacion de historial de oferta',
    $$DELETE FROM historial_oferta WHERE id_grupo=12$$,
    'uh_historial_inmutable');

-- TRUNCATE no dispara controles por fila; se comprueba su rechazo directo y con CASCADE.
SELECT pg_temp.esperar_rechazo(
    'truncamiento de historial protegido',
    $$TRUNCATE TABLE historial_oferta$$,
    'uh_truncamiento_prohibido');
SELECT pg_temp.esperar_rechazo(
    'truncamiento con cascada sobre hechos academicos',
    $$TRUNCATE TABLE estudiante CASCADE$$,
    'uh_truncamiento_prohibido');

SELECT pg_temp.esperar_rechazo(
    'alteracion de historial de oferta',
    $$UPDATE historial_oferta SET motivo='Cambio ficticio' WHERE id_grupo=12$$,
    'uh_historial_inmutable');

-- Admisiones de prueba para solicitudes de julio sin modificar los antecedentes originales.
INSERT INTO admision VALUES
    (31,'UH-ALU1',1,102,DATE '2026-02-01','regular',TRUE),
    (32,'UH-ALU2',2,201,DATE '2026-02-01','regular',TRUE);

UPDATE admision SET activa=FALSE WHERE id_admision=32;
SELECT pg_temp.esperar_rechazo(
    'solicitud desde admision inactiva',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado)
      VALUES (9302,32,11,201,'2026-07-03 10:00-06','matriculada')$$,
    'uh_solicitud_admision_activa');
-- El rechazo se conserva como decision sin consumir cupo.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado,razon_rechazo_espera)
VALUES (9304,32,11,201,'2026-07-03 10:00-06','rechazada',
        'Admision inactiva al solicitar');
UPDATE admision SET activa=TRUE WHERE id_admision=32;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

SELECT pg_temp.esperar_rechazo(
    'posicion en solicitud que nunca ingreso en espera',
    $$UPDATE solicitud_matricula SET orden_espera=1 WHERE id_solicitud=9304$$,
    'uh_espera_posicion_historica');

SAVEPOINT lote_inmediato;
SET CONSTRAINTS ALL IMMEDIATE;
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado,razon_rechazo_espera)
VALUES (9390,32,11,201,'2026-07-03 11:00-06','rechazada','Prueba de lote'),
       (9391,32,11,201,'2026-07-03 12:00-06','rechazada','Prueba de lote');
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM historial_solicitud
        WHERE id_solicitud IN (9390,9391) AND estado_nuevo='rechazada') <> 2 THEN
        RAISE EXCEPTION 'La sentencia multiple no conservo ambas transiciones';
    END IF;
END;
$$;
ROLLBACK TO SAVEPOINT lote_inmediato;
RELEASE SAVEPOINT lote_inmediato;

SELECT pg_temp.esperar_rechazo(
    'reconsideracion de rechazo fuera de ventana',
    $$UPDATE solicitud_matricula SET estado='matriculada',
        momento_transicion='2026-09-12 10:00-06'
      WHERE id_solicitud=9304$$,
    'uh_historial_evento_temporal');

-- La razon original del rechazo debe persistir en el historial y no poder sustituirse sin
-- transicion.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM historial_solicitud
      WHERE id_solicitud=9304 AND tipo_evento='transicion'
        AND motivo='Admision inactiva al solicitar') THEN
    RAISE EXCEPTION 'El motivo del rechazo no quedo en el historial';
  END IF;
END;
$$;
SELECT pg_temp.esperar_rechazo(
    'reescritura del motivo historico de un rechazo',
    $$UPDATE solicitud_matricula SET razon_rechazo_espera='Motivo posterior'
      WHERE id_solicitud=9304$$,
    'uh_solicitud_razon_historica');

SELECT pg_temp.esperar_rechazo(
    'matricula en oferta cerrada',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado)
      VALUES (9303,31,13,102,'2026-07-03 10:00-06','matriculada')$$,
    'uh_matricula_oferta_abierta');

SELECT pg_temp.esperar_rechazo(
    'espera en oferta no publicada',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado,razon_rechazo_espera,orden_espera)
      VALUES (9350,31,13,102,'2026-07-04 09:00-06','en_espera','Sin cupo',1)$$,
    'uh_espera_oferta_abierta');

SELECT pg_temp.esperar_rechazo(
    'adjudicacion anterior a la fecha de ingreso de la admision',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
      VALUES (9380,1,12,102,'2026-07-02 10:00-06','matriculada')$$,
    'uh_solicitud_antes_ingreso');

-- La identidad se comprueba por estudiante incluso si tiene varias admisiones.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (1001,31,12,102,'2026-07-02 10:00-06','matriculada');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'espera pese a existir plaza en un grupo abierto',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado,razon_rechazo_espera,orden_espera)
      VALUES (9381,32,12,201,'2026-07-03 09:00-06','en_espera','Sin cupo',1)$$,
    'uh_espera_sin_ocupacion_completa');
SELECT pg_temp.esperar_rechazo(
    'duplicacion entre admisiones',
    $$INSERT INTO solicitud_matricula
       (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
        fecha_solicitud,estado)
       VALUES (1002,3,12,102,'2026-07-03 10:00-06','matriculada')$$,
    'uh_matricula_duplicada');

-- La oferta es valida ahora, pero fue publicada despues de la fecha de solicitud simulada.
INSERT INTO grupo VALUES (71,71,'UH-MAT1',1,2,1,'virtual','cerrada');
INSERT INTO bloque_horario VALUES (971,71,5,TIME '14:00',TIME '15:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (71,1,'responsable');
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=71;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'publicacion posterior a matricula historica',
    $$INSERT INTO solicitud_matricula
        (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
         fecha_solicitud,estado)
      VALUES (9971,32,71,201,'2026-07-04 10:00-06','matriculada')$$,
    'uh_oferta_publicacion_historica');

-- Trasladar reglas o participaciones hacia una version utilizada puede alterar decisiones
-- anteriores.
SELECT pg_temp.esperar_rechazo(
    'traslado de requisito hacia version historicamente utilizada',
    $sql$DO $body$
    BEGIN
      INSERT INTO version_plan_estudios VALUES (104,10,DATE '2026-01-01',NULL);
      INSERT INTO requisito_curso
          (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,
           tipo_requisito,id_requisito)
      VALUES (104,'UH-PROG1','UH-SIS1','Requisito previo',99999);
      UPDATE requisito_curso SET id_version_plan=102
      WHERE id_version_plan=104 AND codigo_curso_objetivo='UH-PROG1';
    END;
    $body$;$sql$,
    'uh_requisito_historico');
SELECT pg_temp.esperar_rechazo(
    'traslado de participacion hacia version historicamente utilizada',
    $sql$DO $body$
    BEGIN
      INSERT INTO version_plan_estudios VALUES (104,10,DATE '2026-01-01',NULL);
      INSERT INTO participacion_plan
          (codigo_curso,id_version_plan,tipo_participacion)
      VALUES ('UH-SIS1',104,'Optativo');
      UPDATE participacion_plan SET id_version_plan=102
      WHERE codigo_curso='UH-SIS1' AND id_version_plan=104;
    END;
    $body$;$sql$,
    'uh_participacion_historica');

SELECT pg_temp.esperar_rechazo(
    'transicion indebida desde matricula a espera',
    $$UPDATE solicitud_matricula SET estado='en_espera',orden_espera=4,
        razon_rechazo_espera='Retroceso invalido'
      WHERE id_solicitud=1001$$,
    'uh_solicitud_transicion_valida');

-- Una modificacion de fechas lectivas no puede alterar decisiones historicas.
SELECT pg_temp.esperar_rechazo(
    'fechas lectivas de periodo con decisiones previas',
    $$UPDATE periodo_academico SET fecha_finalizacion=DATE '2026-12-14'
      WHERE id_periodo=1$$,
    'uh_periodo_historico');

SELECT pg_temp.esperar_rechazo(
    'instante de transicion sin cambio de estado',
    $$UPDATE solicitud_matricula SET momento_transicion='2026-07-07 09:00-06'
      WHERE id_solicitud=1001$$,
    'uh_solicitud_momento_inmutable');

SELECT pg_temp.esperar_rechazo(
    'grupo de solicitud historica inmutable',
    $$UPDATE solicitud_matricula SET id_grupo=13 WHERE id_solicitud=1001$$,
    'uh_solicitud_contexto_inmutable');

SELECT pg_temp.esperar_rechazo(
    'solicitud de retiro sin matricula previa',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado)
      VALUES (9300,31,12,102,'2026-07-04 09:00-06','retirada')$$,
    'uh_solicitud_estado_inicial');

SELECT pg_temp.esperar_rechazo(
    'momento inicial indebidamente preestablecido',
    $$INSERT INTO solicitud_matricula
       (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
        fecha_solicitud,estado,razon_rechazo_espera,momento_transicion)
       VALUES (9305,32,11,201,'2026-07-03 10:00-06','rechazada',
               'Tentativa incorrecta','2026-07-04 10:00-06')$$,
    'uh_solicitud_momento_inicial');

-- El estudiante ya matriculado en PROG1 tiene franja coincidente con el grupo de otro curso.
INSERT INTO grupo VALUES (21,15,'UH-RED1',1,2,2,'virtual','cerrada');
INSERT INTO bloque_horario VALUES (921,21,1,TIME '10:00',TIME '12:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (21,1,'responsable');
SET LOCAL universidad.instante_efectivo='2026-06-30 12:00-06';
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=21;
SET LOCAL universidad.instante_efectivo='';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'conflicto horario de estudiante',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado)
      VALUES (9301,31,21,102,'2026-07-04 09:00-06','matriculada')$$,
    'uh_horario_historico');

-- Cambiar una ventana usada puede invalidar solicitudes previamente confirmadas.
SELECT pg_temp.esperar_rechazo(
    'modificacion de ventana de solicitud',
    $$UPDATE ventana_periodo SET inicio='2026-07-05 00:00-06'
      WHERE id_ventana=1$$,
    'uh_solicitud_contexto');

-- El evento propuesto tiene forma valida, pero no corresponde a una transicion real.
SELECT pg_temp.esperar_rechazo(
    'insercion manual de transicion ficticia',
    $$INSERT INTO historial_solicitud
      (id_evento,id_solicitud,tipo_evento,estado_anterior,estado_nuevo,
       fecha_evento,motivo)
      VALUES (901,1001,'transicion','matriculada','retirada',
              '2026-08-10 10:00-06','Retiro no realizado')$$,
    'uh_historial_evento_automatico');

SELECT pg_temp.esperar_rechazo(
    'reduccion del cupo por debajo de ocupacion',
    $$UPDATE grupo SET capacidad = 0 WHERE id_grupo = 12$$,
    'uh_grupo_cupo');

-- Cambiar la ubicacion de un espacio utilizado alteraria la ubicacion historica de las sesiones.
SELECT pg_temp.esperar_rechazo(
    'ubicacion de espacio con solicitudes historicas',
    $$UPDATE espacio SET ubicacion='Aula trasladada'
      WHERE id_espacio=1$$,
    'uh_espacio_historico');

-- La capacidad del espacio debe cubrir la del grupo no cancelado que lo utiliza.
SELECT pg_temp.esperar_rechazo(
    'reduccion de espacio incompatible con grupo',
    $$UPDATE espacio SET capacidad=1 WHERE id_espacio=1$$,
    'uh_bloque_espacio_contexto');

SELECT pg_temp.esperar_rechazo(
    'eliminacion del unico bloque de oferta abierta',
    $$DELETE FROM bloque_horario WHERE id_bloque=101$$,
    'uh_oferta_contexto_historico');

SELECT pg_temp.esperar_rechazo(
    'eliminacion del responsable de oferta abierta',
    $$DELETE FROM grupo_docente WHERE id_grupo=12 AND rol='responsable'$$,
    'uh_oferta_contexto_historico');

-- Una segunda admision valida ocupa el ultimo cupo libre.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (1003,32,12,201,'2026-07-03 11:00-06','matriculada');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM solicitud_matricula
      WHERE id_grupo = 12 AND estado = 'matriculada') <> 2 THEN
    RAISE EXCEPTION 'La ocupacion confirmada no coincide';
  END IF;
END;
$$;

INSERT INTO estudiante VALUES ('UH-ALU3','Estudiante','Tres',NULL);
INSERT INTO contacto_estudiante VALUES (603,'UH-ALU3','correo','alu3@example.test',TRUE);
INSERT INTO admision VALUES (4,'UH-ALU3',1,102,DATE '2026-02-01','regular',TRUE);
SELECT pg_temp.esperar_rechazo(
    'tercer matriculado sin cupo',
    $$INSERT INTO solicitud_matricula
       (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
        fecha_solicitud,estado)
       VALUES (1004,4,12,102,'2026-07-04 10:00-06','matriculada')$$,
    'uh_grupo_cupo');

-- Una solicitud en espera no consume cupo y conserva posicion y motivo.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado,razon_rechazo_espera,orden_espera)
VALUES (2001,4,12,102,'2026-07-04 10:00-06','en_espera','Sin cupo',1);
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- En empate de ingreso a espera, id_solicitud determina el orden.
INSERT INTO estudiante VALUES ('UH-ALU4','Estudiante','Cuatro',NULL);
INSERT INTO contacto_estudiante VALUES (604,'UH-ALU4','correo','alu4@example.test',TRUE);
INSERT INTO admision VALUES (5,'UH-ALU4',1,102,DATE '2026-02-01','regular',TRUE);
SELECT pg_temp.esperar_rechazo(
    'empate de espera con posicion repetida',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado,razon_rechazo_espera,orden_espera)
      VALUES (2002,5,12,102,'2026-07-04 10:00-06',
              'en_espera','Sin cupo',1)$$,
    'uh_espera_orden');
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado,razon_rechazo_espera,orden_espera)
VALUES (2002,5,12,102,'2026-07-04 10:00-06',
        'en_espera','Sin cupo',2);
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- El orden de cola usa la entrada efectiva, no necesariamente la fecha inicial de solicitud.
INSERT INTO estudiante VALUES ('UH-ALU6','Estudiante','Seis',NULL);
INSERT INTO contacto_estudiante VALUES (606,'UH-ALU6','correo','alu6@example.test',TRUE);
INSERT INTO admision VALUES (7,'UH-ALU6',1,102,DATE '2026-02-01','regular',TRUE);
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado,razon_rechazo_espera)
VALUES (2003,7,12,102,'2026-07-02 10:00-06','rechazada','Evaluacion inicial');
UPDATE solicitud_matricula SET estado='en_espera',
    razon_rechazo_espera='Sin cupo', orden_espera=3,
    momento_transicion='2026-07-05 11:00-06'
WHERE id_solicitud=2003;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- El antecedente de una solicitud registrada no puede sustituirse posteriormente.
SELECT pg_temp.esperar_rechazo(
    'antecedente historico no modificable',
    $$UPDATE solicitud_matricula SET id_solicitud_anterior=2002
      WHERE id_solicitud=2001$$,
    'uh_solicitud_contexto_inmutable');

SELECT pg_temp.esperar_rechazo(
    'reescritura del orden de espera',
    $$UPDATE solicitud_matricula SET orden_espera=5 WHERE id_solicitud=2001$$,
    'uh_espera_orden_inmutable');

-- El reingreso en espera no puede reutilizar la posicion de una solicitud anterior.
SELECT pg_temp.esperar_rechazo(
    'reingreso a espera con posicion historica antigua',
    $sql$DO $body$
    BEGIN
        UPDATE solicitud_matricula SET estado='rechazada',
            razon_rechazo_espera='Se retiro de la espera',
            momento_transicion='2026-07-05 10:00-06'
        WHERE id_solicitud=2001;
        UPDATE solicitud_matricula SET estado='en_espera',
            razon_rechazo_espera='Nueva solicitud de espera',
            momento_transicion='2026-07-06 10:00-06'
        WHERE id_solicitud=2001;
    END;
    $body$;$sql$,
    'uh_espera_reingreso_historico');

UPDATE admision SET activa=FALSE WHERE id_admision=4;
SELECT pg_temp.esperar_rechazo(
    'promocion de espera desde admision inactiva',
    $$UPDATE solicitud_matricula SET estado='matriculada'
      WHERE id_solicitud=2001$$,
    'uh_solicitud_admision_activa');
UPDATE admision SET activa=TRUE WHERE id_admision=4;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- El curso ofertado exige un requisito previo que aun no fue aprobado ni reconocido.
INSERT INTO grupo VALUES (14,1,'UH-PROG2',1,2,2,'virtual','cerrada');
INSERT INTO bloque_horario VALUES (902,14,4,TIME '13:00',TIME '14:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (14,2,'responsable');
SET LOCAL universidad.instante_efectivo='2026-07-01 08:00-06';
UPDATE grupo SET estado_oferta = 'abierta' WHERE id_grupo = 14;
SET LOCAL universidad.instante_efectivo='';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'requisito previo no satisfecho',
    $$INSERT INTO solicitud_matricula
       (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
        fecha_solicitud,estado)
       VALUES (1005,31,14,102,'2026-07-04 10:00-06','matriculada')$$,
    'uh_matricula_requisitos');

-- La excepcion se agrega en la misma transaccion y corresponde al curso, plan y requisito
-- concretos.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (1005,31,14,102,'2026-07-04 10:00-06','matriculada');
INSERT INTO excepcion_requisito
    (id_excepcion,id_solicitud,id_requisito,id_autorizador,fecha_autorizacion,motivo)
SELECT 800,1005,r.id_requisito,1,'2026-07-04 09:30-06','Autorizacion individual'
FROM requisito_curso r
WHERE r.id_version_plan = 102 AND r.codigo_curso_objetivo = 'UH-PROG2'
  AND r.codigo_curso_exigido = 'UH-PROG1' AND r.tipo_requisito = 'Requisito previo';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

SELECT pg_temp.esperar_rechazo(
    'eliminacion de excepcion ya utilizada',
    $$DELETE FROM excepcion_requisito WHERE id_excepcion=800$$,
    'uh_excepcion_inmutable');

SELECT pg_temp.esperar_rechazo(
    'autorizacion posterior a matricula',
    $$INSERT INTO excepcion_requisito
      (id_excepcion,id_solicitud,id_requisito,id_autorizador,fecha_autorizacion,motivo)
      SELECT 802,1005,r.id_requisito,1,'2026-07-04 11:00-06','Autorizacion tardia'
      FROM requisito_curso r
      WHERE r.id_version_plan=102 AND r.codigo_curso_objetivo='UH-PROG2'
        AND r.codigo_curso_exigido='UH-PROG1'
        AND r.tipo_requisito='Requisito previo'$$,
    'uh_excepcion_temporal');

SELECT pg_temp.esperar_rechazo(
    'excepcion de curso objetivo diferente',
    $$INSERT INTO excepcion_requisito
      (id_excepcion,id_solicitud,id_requisito,id_autorizador,fecha_autorizacion,motivo)
      SELECT 801,1005,r.id_requisito,1,'2026-07-04 09:40-06','Incompatible'
      FROM requisito_curso r
      WHERE r.id_version_plan=102 AND r.codigo_curso_objetivo='UH-BDAT1'
        AND r.codigo_curso_exigido='UH-MAT1'
        AND r.tipo_requisito='Correquisito'$$,
    'uh_excepcion_contexto');

-- Una regla con excepcion utilizada queda protegida frente a cambios de curso objetivo.
SELECT pg_temp.esperar_rechazo(
    'modificacion de regla exceptuada',
    $$UPDATE requisito_curso SET codigo_curso_objetivo='UH-ALG1'
      WHERE id_requisito=(SELECT r.id_requisito FROM requisito_curso r
        WHERE r.id_version_plan=102 AND r.codigo_curso_objetivo='UH-PROG2'
          AND r.codigo_curso_exigido='UH-PROG1'
          AND r.tipo_requisito='Requisito previo')$$,
    'uh_requisito_historico');

-- Una solicitud rechazada fuera de ventana conserva la razon sin ocupar cupo.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado,razon_rechazo_espera)
VALUES (3001,4,12,102,'2026-07-16 10:00-06','rechazada','Fuera de ventana');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- Una anulacion administrativa requiere actor y no convierte el rechazo en matricula.
SET LOCAL universidad.autorizador='';
SELECT pg_temp.esperar_rechazo(
    'anulacion administrativa sin actor',
    $$UPDATE solicitud_matricula SET estado='anulada',
      momento_transicion='2026-07-17 10:00-06' WHERE id_solicitud=3001$$,
    'uh_anulacion_actor');
SET LOCAL universidad.autorizador='1';
DO $$
BEGIN
  BEGIN
    UPDATE solicitud_matricula SET estado='anulada',
        momento_transicion='2026-07-17 10:00-06' WHERE id_solicitud=3001;
    SET CONSTRAINTS ALL IMMEDIATE;
    IF NOT EXISTS (
        SELECT 1 FROM historial_solicitud
        WHERE id_solicitud=3001 AND estado_anterior='rechazada'
          AND estado_nuevo='anulada' AND id_actor=1
    ) THEN RAISE EXCEPTION 'La anulacion no quedo documentada'; END IF;
    RAISE EXCEPTION 'Reversion controlada' USING ERRCODE='P9001';
  EXCEPTION WHEN SQLSTATE 'P9001' THEN
    RAISE NOTICE 'Anulacion administrativa comprobada y revertida';
  END;
END;
$$;
SET CONSTRAINTS ALL DEFERRED;

SELECT pg_temp.esperar_rechazo(
    'resultado academico sin matricula',
    $$UPDATE solicitud_matricula SET calificacion='A',resultado_academico='aprobado'
      WHERE id_solicitud=3001$$,
    'uh_resultado_sin_matricula');

-- La ventana es semiabierta: se rechaza la matricula justo en su hora final.
SELECT pg_temp.esperar_rechazo(
    'extremo derecho de ventana de matricula',
    $$INSERT INTO solicitud_matricula
       (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
        fecha_solicitud,estado)
       VALUES (3002,4,11,102,'2026-07-12 00:00-06','matriculada')$$,
    'uh_solicitud_contexto');

-- Se comprueba el extremo inicial inclusivo y la compatibilidad entre horarios contiguos.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (3002,4,11,102,'2026-07-01 00:00-06','matriculada');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

SELECT pg_temp.esperar_rechazo(
    'cambio hacia otro curso',
    $$INSERT INTO solicitud_matricula
       (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,
        id_version_plan_evaluada,fecha_solicitud,estado)
       VALUES (4001,31,11,1001,102,'2026-07-11 11:00-06','matriculada')$$,
    'uh_solicitud_antecedente');

-- Convencion del cambio de grupo: retiro y adjudicacion tienen el mismo instante efectivo y se
-- confirman o revierten juntos. Se contrastan un par de instantes distintos y un par coincidente.
DO $$
DECLARE v_origen TEXT; v_destino TEXT;
BEGIN
  BEGIN
    INSERT INTO grupo VALUES (15,3,'UH-PROG1',1,1,1,'virtual','cerrada');
    INSERT INTO bloque_horario VALUES (903,15,4,TIME '16:00',TIME '17:00',FALSE,NULL);
    INSERT INTO grupo_docente VALUES (15,1,'responsable');
    PERFORM set_config('universidad.instante_efectivo','2026-07-10 09:00-06', TRUE);
    UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=15;
    PERFORM set_config('universidad.instante_efectivo','', TRUE);
    PERFORM pg_temp.esperar_rechazo(
        'cambio con retiro y confirmacion en instantes distintos',
        $sql$DO $cambio$
        BEGIN
            UPDATE solicitud_matricula SET estado='retirada',
                momento_transicion='2026-07-11 10:00-06' WHERE id_solicitud=1001;
            PERFORM set_config('universidad.instante_adjudicacion','2026-07-11 10:01-06',TRUE);
            INSERT INTO solicitud_matricula
                (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,
                 id_version_plan_evaluada,fecha_solicitud,estado)
            VALUES (4002,31,15,1001,102,'2026-07-11 10:00-06','matriculada');
        END;
        $cambio$;$sql$,
        'uh_solicitud_antecedente');
    UPDATE solicitud_matricula SET estado='retirada',
      momento_transicion='2026-07-11 10:00-06' WHERE id_solicitud=1001;
    INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,
       id_version_plan_evaluada,fecha_solicitud,estado)
    VALUES (4002,31,15,1001,102,'2026-07-11 10:00-06','matriculada');
    SET CONSTRAINTS ALL IMMEDIATE;
    -- La retirada posterior del destino no anula la validez del cambio ya registrado.
    SET CONSTRAINTS ALL DEFERRED;
    UPDATE solicitud_matricula SET estado='retirada',
        momento_transicion='2026-08-10 11:00-06' WHERE id_solicitud=4002;
    SET CONSTRAINTS ALL IMMEDIATE;
    SELECT estado INTO v_origen FROM solicitud_matricula WHERE id_solicitud=1001;
    SELECT estado INTO v_destino FROM solicitud_matricula WHERE id_solicitud=4002;
    IF v_origen IS DISTINCT FROM 'retirada' OR v_destino IS DISTINCT FROM 'retirada' THEN
      RAISE EXCEPTION 'Los estados del cambio no se conservaron';
    END IF;
    RAISE EXCEPTION 'reversion del caso valido' USING ERRCODE='P9001';
  EXCEPTION WHEN SQLSTATE 'P9001' THEN
    RAISE NOTICE 'Cambio de grupo valido, comprobado y revertido';
  END;
END;
$$;
SET CONSTRAINTS ALL DEFERRED;

-- Una evaluacion de espera puede conservar un motivo sin alterar el estado.
INSERT INTO historial_solicitud
    (id_evento,id_solicitud,tipo_evento,estado_anterior,estado_nuevo,
     fecha_evento,motivo)
VALUES (810,2001,'evaluacion_espera','en_espera','en_espera',
        '2026-07-05 10:00-06','Evaluacion pendiente');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'evaluacion de espera sin antecedente de espera',
    $$INSERT INTO historial_solicitud
       (id_evento,id_solicitud,tipo_evento,estado_anterior,estado_nuevo,
        fecha_evento,motivo)
       VALUES (811,1003,'evaluacion_espera','matriculada','matriculada',
               '2026-07-06 10:00-06','No corresponde')$$,
    'uh_historial_evento_temporal');

SELECT pg_temp.esperar_rechazo(
    'modificacion de evento de solicitud',
    $$UPDATE historial_solicitud SET motivo='Alteracion posterior'
      WHERE id_solicitud=1001$$,
    'uh_historial_inmutable');

SELECT pg_temp.esperar_rechazo(
    'retiro fuera de plazo',
    $$UPDATE solicitud_matricula SET estado='retirada',
      momento_transicion='2026-07-16 10:00-06' WHERE id_solicitud=1001$$,
    'uh_historial_evento_temporal');

-- El retiro posterior no puede ocultar un sobrecupo ocurrido antes; el caso se revierte en una
-- subtransaccion.
SELECT pg_temp.esperar_rechazo(
    'sobrecupo historico encubierto por retiro posterior',
    $sql$DO $body$
    BEGIN
      UPDATE solicitud_matricula SET estado='retirada',
          momento_transicion='2026-08-10 10:00-06'
      WHERE id_solicitud=1001;
      INSERT INTO solicitud_matricula
        (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
         fecha_solicitud,estado)
      VALUES (1004,4,12,102,'2026-07-04 10:00-06','matriculada');
    END;
    $body$;$sql$,
    'uh_cupo_historico');

-- El retiro valido registra una segunda transicion dentro de la ventana autorizada.
UPDATE solicitud_matricula SET estado='retirada',
    momento_transicion='2026-08-10 10:00-06' WHERE id_solicitud=1001;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM historial_solicitud WHERE id_solicitud=1001
      AND tipo_evento='transicion') <> 2 THEN
    RAISE EXCEPTION 'La transicion de retiro no quedo auditada';
  END IF;
END;
$$;

SELECT pg_temp.esperar_rechazo(
    'promocion que omite al primer elegible',
    $$UPDATE solicitud_matricula SET estado='matriculada',
        momento_transicion='2026-08-10 10:30-06' WHERE id_solicitud=2002$$,
    'uh_espera_prioridad');
SAVEPOINT promocion_en_orden;
UPDATE solicitud_matricula SET estado='matriculada',
    momento_transicion='2026-08-10 10:30-06' WHERE id_solicitud=2001;
SET CONSTRAINTS ALL IMMEDIATE;
DO $$
BEGIN
    IF public.uh_estado_en_instante(2001,'2026-08-10 10:30-06')
       IS DISTINCT FROM 'matriculada' THEN
        RAISE EXCEPTION 'El primer elegible no recibio el cupo';
    END IF;
END;
$$;
ROLLBACK TO SAVEPOINT promocion_en_orden;
UPDATE admision SET activa=FALSE WHERE id_admision=4;
-- La evaluacion del 5 de julio no justifica una omision durante la promocion del 10 de agosto.
SELECT pg_temp.esperar_rechazo(
    'promocion con evaluacion anterior obsoleta',
    $$UPDATE solicitud_matricula SET estado='matriculada',
        momento_transicion='2026-08-10 10:30-06' WHERE id_solicitud=2002$$,
    'uh_espera_prioridad');
-- La omision motivada se registra en el mismo instante de la promocion siguiente.
INSERT INTO historial_solicitud
    (id_evento,id_solicitud,tipo_evento,estado_anterior,estado_nuevo,fecha_evento,motivo)
VALUES (8900,2001,'evaluacion_espera','en_espera','en_espera',
        '2026-08-10 10:30-06','Admision inactiva al liberar el cupo');
UPDATE solicitud_matricula SET estado='matriculada',
    momento_transicion='2026-08-10 10:30-06' WHERE id_solicitud=2002;
SET CONSTRAINTS ALL IMMEDIATE;
DO $$
BEGIN
    IF public.uh_estado_en_instante(2002,'2026-08-10 10:30-06')
       IS DISTINCT FROM 'matriculada' OR
       public.uh_estado_en_instante(2001,'2026-08-10 10:30-06')
       IS DISTINCT FROM 'en_espera' THEN
        RAISE EXCEPTION 'La promocion del segundo elegible altero la cola';
    END IF;
END;
$$;
ROLLBACK TO SAVEPOINT promocion_en_orden;
RELEASE SAVEPOINT promocion_en_orden;

-- Tras el retiro, el estado actual no muestra duplicacion, pero las dos matriculas historicas se
-- habrian superpuesto.
INSERT INTO grupo VALUES (72,72,'UH-PROG1',1,1,10,'virtual','cerrada');
INSERT INTO bloque_horario VALUES (972,72,5,TIME '18:00',TIME '19:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (72,1,'responsable');
SET LOCAL universidad.instante_efectivo='2026-06-30 12:00-06';
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=72;
SET LOCAL universidad.instante_efectivo='';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'duplicacion de matriculas en el pasado tras retiro',
    $$INSERT INTO solicitud_matricula
        (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
         fecha_solicitud,estado)
      VALUES (1072,3,72,102,'2026-07-04 10:00-06','matriculada')$$,
    'uh_matricula_duplicada_historica');

-- El estado actual tampoco revela un choque horario que existio antes del retiro.
INSERT INTO grupo VALUES (73,73,'UH-RED1',1,2,5,'virtual','cerrada');
INSERT INTO bloque_horario VALUES (973,73,1,TIME '11:00',TIME '13:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (73,2,'responsable');
SET LOCAL universidad.instante_efectivo='2026-06-30 12:00-06';
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=73;
SET LOCAL universidad.instante_efectivo='';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'choque historico encubierto por retiro posterior',
    $$INSERT INTO solicitud_matricula
        (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
         fecha_solicitud,estado)
      VALUES (1073,3,73,102,'2026-07-04 10:00-06','matriculada')$$,
    'uh_horario_historico');

-- El origen ya estaba retirado antes de pedir un cambio de grupo.
INSERT INTO ventana_periodo
    (id_ventana,id_periodo,tipo_ventana,inicio,fin)
VALUES (29,1,'modificacion','2026-09-01 00:00-06','2026-09-10 00:00-06');
INSERT INTO grupo VALUES (29,29,'UH-PROG1',1,1,1,'virtual','cerrada');
INSERT INTO bloque_horario VALUES (929,29,2,TIME '10:00',TIME '11:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (29,1,'responsable');
SET LOCAL universidad.instante_efectivo='2026-09-01 08:00-06';
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=29;
SET LOCAL universidad.instante_efectivo='';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'antecedente retirado antes de nuevo cambio',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,
       id_version_plan_evaluada,fecha_solicitud,estado)
      VALUES (4029,31,29,1001,102,'2026-09-05 10:00-06','matriculada')$$,
    'uh_solicitud_antecedente');

-- Se prepara un periodo lectivo finalizado para generar un antecedente de aprobacion.
INSERT INTO estudiante VALUES ('UH-ALU9','Estudiante','Nueve',NULL);
INSERT INTO contacto_estudiante VALUES (609,'UH-ALU9','correo','alu9@example.test',TRUE);
INSERT INTO admision VALUES
    (9,'UH-ALU9',2,201,DATE '2026-02-01','regular',TRUE);
INSERT INTO periodo_academico
    (id_periodo,codigo_periodo,fecha_inicio,fecha_finalizacion)
VALUES (5,'2026-1',DATE '2026-03-01',DATE '2026-06-30');
INSERT INTO ventana_periodo
    (id_ventana,id_periodo,tipo_ventana,inicio,fin)
VALUES (50,5,'matricula','2026-02-10 00:00-06','2026-03-01 00:00-06');
INSERT INTO grupo VALUES (50,50,'UH-MAT1',5,2,2,'virtual','cerrada');
INSERT INTO bloque_horario VALUES
    (950,50,4,TIME '08:00',TIME '09:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (50,2,'responsable');
SET LOCAL universidad.instante_efectivo='2026-02-19 08:00-06';
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=50;
SET LOCAL universidad.instante_efectivo='';
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (5051,9,50,201,'2026-02-20 10:00-06','matriculada');
INSERT INTO estudiante VALUES ('UH-ALU10','Estudiante','Diez',NULL);
INSERT INTO contacto_estudiante VALUES (610,'UH-ALU10','correo','alu10@example.test',TRUE);
INSERT INTO admision VALUES
    (10,'UH-ALU10',2,201,DATE '2026-02-01','regular',TRUE);
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado,calificacion,resultado_academico)
VALUES (5052,10,50,201,'2026-02-21 10:00-06','matriculada','A','aprobado');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM historial_correccion_calificacion
               WHERE id_solicitud=5052) THEN
        RAISE EXCEPTION 'La primera asignacion no es una correccion';
    END IF;
END;
$$;

-- Sin fecha de carga inicial, el cierre del periodo es el limite inferior para utilizar una nota
-- como antecedente.
DO $$
BEGIN
  IF public.uh_resultado_en_instante(5052,'2026-06-30 23:59:00-06') IS NOT NULL THEN
    RAISE EXCEPTION 'La aprobacion se atribuyo a un periodo aun no concluido';
  END IF;
END;
$$;

-- Un periodo futuro respecto al reloj del servidor permite probar el rechazo de notas anticipadas.
INSERT INTO periodo_academico
    (id_periodo,codigo_periodo,fecha_inicio,fecha_finalizacion)
VALUES (60,'PERIODO-FUTURO',CURRENT_DATE + 30,CURRENT_DATE + 100);
INSERT INTO ventana_periodo
    (id_ventana,id_periodo,tipo_ventana,inicio,fin)
VALUES (60,60,'matricula',transaction_timestamp(),
        transaction_timestamp() + INTERVAL '10 days');
INSERT INTO grupo VALUES (60,60,'UH-MAT1',60,2,2,'virtual','cerrada');
INSERT INTO bloque_horario VALUES
    (960,60,4,TIME '15:00',TIME '16:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES (60,2,'responsable');
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=60;
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (6060,2,60,201,transaction_timestamp() + INTERVAL '1 day','matriculada');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.esperar_rechazo(
    'nota inicial anterior al cierre lectivo',
    $$UPDATE solicitud_matricula SET calificacion='A',resultado_academico='aprobado'
      WHERE id_solicitud=6060$$,
    'uh_resultado_antes_fin_periodo');
SELECT pg_temp.esperar_rechazo(
    'nota en solicitud inicial de periodo no terminado',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado,calificacion,resultado_academico)
      VALUES (6061,2,60,201,transaction_timestamp()+INTERVAL '2 days',
              'matriculada','A','aprobado')$$,
    'uh_resultado_antes_fin_periodo');

-- La correccion sin motivo se rechaza; se restituye el contexto de auditoria.
UPDATE solicitud_matricula SET calificacion='A',resultado_academico='aprobado'
WHERE id_solicitud=5051;
SET LOCAL universidad.motivo='';
SELECT pg_temp.esperar_rechazo(
    'correccion sin motivo',
    $$UPDATE solicitud_matricula SET calificacion='C'
       WHERE id_solicitud=5051$$,
    'uh_correccion_auditoria_obligatoria');
SET LOCAL universidad.motivo='Comprobacion controlada de integridad';

-- La correccion debe conservar valores anterior y nuevo, motivo y autorizador.
UPDATE solicitud_matricula SET calificacion='A',resultado_academico='aprobado'
WHERE id_solicitud=5051;
UPDATE solicitud_matricula SET calificacion='B',resultado_academico='reprobado'
WHERE id_solicitud=5051;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM historial_correccion_calificacion
    WHERE id_solicitud = 5051 AND calificacion_anterior = 'A'
      AND calificacion_nueva = 'B' AND resultado_anterior='aprobado'
      AND resultado_nuevo='reprobado' AND id_autorizador=1
  ) THEN RAISE EXCEPTION 'La correccion efectiva no quedo auditada'; END IF;
END;
$$;

SELECT pg_temp.esperar_rechazo(
    'eliminacion de correccion historica',
    $$DELETE FROM historial_correccion_calificacion
      WHERE id_solicitud=5051$$,
    'uh_historial_inmutable');

-- Una asignacion tras corregir la nota a NULL sigue siendo correccion, no alta inicial.
DO $$
DECLARE
  v_cambios INTEGER;
BEGIN
  BEGIN
    UPDATE solicitud_matricula SET calificacion=NULL,resultado_academico=NULL
      WHERE id_solicitud=5051;
    UPDATE solicitud_matricula SET calificacion='C',resultado_academico='aprobado'
      WHERE id_solicitud=5051;
    SET CONSTRAINTS ALL IMMEDIATE;
    SELECT COUNT(*) INTO v_cambios
    FROM historial_correccion_calificacion WHERE id_solicitud=5051;
    IF v_cambios <> 3 THEN
      RAISE EXCEPTION 'No se audito la correccion posterior a NULL';
    END IF;
    RAISE EXCEPTION 'Reversion controlada' USING ERRCODE='P9001';
  EXCEPTION WHEN SQLSTATE 'P9001' THEN
    RAISE NOTICE 'Correciones sucesivas conservadas y revertidas';
  END;
END;
$$;
SET CONSTRAINTS ALL DEFERRED;

-- Se preparan tres vias de satisfaccion: aprobacion anterior, reconocimiento y correquisito del
-- mismo periodo.
INSERT INTO periodo_academico
    (id_periodo,codigo_periodo,fecha_inicio,fecha_finalizacion)
VALUES (3,'2027-1',DATE '2027-01-10',DATE '2027-05-10');
INSERT INTO ventana_periodo
    (id_ventana,id_periodo,tipo_ventana,inicio,fin)
VALUES (30,3,'matricula','2026-12-20 00:00-06','2027-01-05 00:00-06');
INSERT INTO grupo VALUES
    (17,11,'UH-PROG2',3,2,2,'virtual','cerrada'),
    (18,12,'UH-SIS1',3,2,2,'virtual','cerrada'),
    (20,14,'UH-MAT1',3,2,2,'virtual','cerrada');
INSERT INTO bloque_horario VALUES
    (917,17,5,TIME '16:00',TIME '17:00',FALSE,NULL),
    (918,18,5,TIME '18:00',TIME '19:00',FALSE,NULL),
    (920,20,5,TIME '09:00',TIME '10:00',FALSE,NULL);
INSERT INTO grupo_docente VALUES
    (17,1,'responsable'),(18,2,'responsable'),(20,1,'responsable');
SET LOCAL universidad.instante_efectivo='2026-12-20 12:00-06';
UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo IN (17,18,20);
SET LOCAL universidad.instante_efectivo='';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- El reconocimiento de PROG1 en el plan 102 habilita el requisito previo de PROG2.
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (5017,1,17,102,'2026-12-22 10:00-06','matriculada');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- La eliminacion de un reconocimiento usado no puede alterar una adjudicacion posterior.
SELECT pg_temp.esperar_rechazo(
    'eliminacion de reconocimiento utilizado',
    $$DELETE FROM reconocimiento_academico WHERE id_reconocimiento=300$$,
    'uh_trayectoria_inmutable');

-- La aprobacion de MAT1 en un periodo concluido satisface el requisito previo correspondiente.
UPDATE solicitud_matricula SET calificacion='A',resultado_academico='aprobado'
WHERE id_solicitud=5051;
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES (5018,9,18,201,'2026-12-22 11:00-06','matriculada');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- La validez de una correccion depende de si precede o sucede a la adjudicacion historica; se
-- distinguen ambos ordenes temporales.
DO $$
BEGIN
    IF clock_timestamp() < TIMESTAMPTZ '2026-12-22 11:00:00-06' THEN
        PERFORM pg_temp.esperar_rechazo(
            'revocacion del antecedente antes de la adjudicacion posterior',
            $sql$UPDATE solicitud_matricula SET resultado_academico='reprobado'
              WHERE id_solicitud=5051$sql$,
            'uh_matricula_requisitos'
        );
    ELSE
        BEGIN
            UPDATE solicitud_matricula SET resultado_academico='reprobado'
              WHERE id_solicitud=5051;
            SET CONSTRAINTS ALL IMMEDIATE;
            IF public.uh_resultado_en_instante(
                5051, TIMESTAMPTZ '2026-12-22 11:00:00-06'
            ) IS DISTINCT FROM 'aprobado' THEN
                RAISE EXCEPTION 'Una correccion posterior modifico un resultado historico';
            END IF;
            RAISE EXCEPTION 'Reversion del escenario de correccion tardia'
                USING ERRCODE='P9001';
        EXCEPTION WHEN SQLSTATE 'P9001' THEN
            RAISE NOTICE 'La correccion posterior no invalida una adjudicacion historica';
        END;
        SET CONSTRAINTS ALL DEFERRED;
    END IF;
END;
$$;

-- Esta admision no tiene MAT1 aprobado ni reconocido; necesita matricular el correquisito en el
-- periodo.
INSERT INTO estudiante VALUES ('UH-ALU5','Estudiante','Cinco',NULL);
INSERT INTO contacto_estudiante VALUES (605,'UH-ALU5','correo','alu5@example.test',TRUE);
INSERT INTO admision VALUES (6,'UH-ALU5',2,201,DATE '2026-08-01','regular',TRUE);
SELECT pg_temp.esperar_rechazo(
    'correquisito no matriculado ni aprobado',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado)
      VALUES (6018,6,18,201,'2026-12-23 11:00-06','matriculada')$$,
    'uh_matricula_requisitos');
-- Adjudicar el correquisito despues no legitima una matricula anterior.
SAVEPOINT correquisito_posterior;
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
VALUES (6020,6,20,201,'2026-12-24 10:00-06','matriculada');
SELECT pg_temp.esperar_rechazo(
    'correquisito adjudicado despues de la decision',
    $$INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
      VALUES (6018,6,18,201,'2026-12-23 11:00-06','matriculada')$$,
    'uh_matricula_requisitos');
ROLLBACK TO SAVEPOINT correquisito_posterior;
RELEASE SAVEPOINT correquisito_posterior;

INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
     fecha_solicitud,estado)
VALUES
    (6020,6,20,201,'2026-12-23 10:00-06','matriculada'),
    (6018,6,18,201,'2026-12-23 11:00-06','matriculada');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM solicitud_matricula
      WHERE id_solicitud IN (5017,5018,6018,6020) AND estado='matriculada') <> 4 THEN
    RAISE EXCEPTION 'No se conservaron las satisfacciones validas diferenciadas';
  END IF;
END;
$$;

-- Las dos solicitudes se insertan en orden inverso a la dependencia y se adjudican en el mismo
-- instante; la validacion diferida considera ambas.
DO $$
BEGIN
  BEGIN
    INSERT INTO estudiante VALUES ('UH-ALU11','Estudiante','Once',NULL);
    INSERT INTO contacto_estudiante VALUES (611,'UH-ALU11','correo','alu11@example.test',TRUE);
    INSERT INTO admision VALUES
      (11,'UH-ALU11',2,201,DATE '2026-08-01','regular',TRUE);
    INSERT INTO grupo VALUES (22,22,'UH-SIS1',3,2,1,'virtual','cerrada');
    INSERT INTO bloque_horario VALUES
      (922,22,5,TIME '20:00',TIME '21:00',FALSE,NULL);
    INSERT INTO grupo_docente VALUES (22,2,'responsable');
    PERFORM set_config('universidad.instante_efectivo',
                       '2026-12-20 12:00-06', TRUE);
    UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=22;
    PERFORM set_config('universidad.instante_efectivo','',TRUE);
    PERFORM set_config('universidad.instante_adjudicacion','2026-12-24 12:00-06',TRUE);
    INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado)
    VALUES (6122,11,22,201,'2026-12-24 11:00-06','matriculada');
    INSERT INTO solicitud_matricula
      (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
       fecha_solicitud,estado)
    VALUES (6120,11,20,201,'2026-12-24 12:00-06','matriculada');
    PERFORM set_config('universidad.instante_adjudicacion','',TRUE);
    SET CONSTRAINTS ALL IMMEDIATE;
    IF (SELECT COUNT(*) FROM solicitud_matricula
        WHERE id_solicitud IN (6122,6120) AND estado='matriculada') <> 2 THEN
      RAISE EXCEPTION 'La operacion compuesta no conservo las dos matriculas';
    END IF;
    RAISE EXCEPTION 'Reversion del escenario compuesto'
        USING ERRCODE='P9001';
  EXCEPTION WHEN SQLSTATE 'P9001' THEN
    RAISE NOTICE 'Correquisito y curso adjudicados en operacion compuesta';
  END;
END;
$$;
SET CONSTRAINTS ALL DEFERRED;

-- La anulacion del correquisito antes de confirmar el curso dependiente impide utilizarlo como
-- antecedente; el caso negativo se aisla.
SELECT pg_temp.esperar_rechazo(
    'correquisito anulado antes de la adjudicacion',
    $sql$DO $body$
    BEGIN
        INSERT INTO estudiante VALUES ('UH-ALU12','Estudiante','Doce',NULL);
        INSERT INTO contacto_estudiante VALUES (612,'UH-ALU12','correo','alu12@example.test',TRUE);
        INSERT INTO admision VALUES
            (12,'UH-ALU12',2,201,DATE '2026-08-01','regular',TRUE);
        INSERT INTO grupo VALUES
            (23,23,'UH-SIS1',3,2,1,'virtual','cerrada');
        INSERT INTO bloque_horario VALUES
            (923,23,5,TIME '20:00',TIME '21:00',FALSE,NULL);
        INSERT INTO grupo_docente VALUES (23,2,'responsable');
        PERFORM set_config('universidad.instante_efectivo',
                           '2026-12-20 12:00-06',TRUE);
        UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=23;
        PERFORM set_config('universidad.instante_efectivo','',TRUE);
        INSERT INTO solicitud_matricula
            (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
             fecha_solicitud,estado)
        VALUES (6123,12,20,201,'2026-12-24 10:00-06','matriculada');
        UPDATE solicitud_matricula SET estado='anulada',
            momento_transicion='2026-12-24 10:30-06' WHERE id_solicitud=6123;
        INSERT INTO solicitud_matricula
            (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
             fecha_solicitud,estado)
        VALUES (6124,12,23,201,'2026-12-24 11:00-06','matriculada');
    END;
    $body$;$sql$,
    'uh_matricula_requisitos');

-- Una promocion tras traslado evalua el nuevo plan y un cupo ampliado sin alterar el plan original
-- de la solicitud.
SAVEPOINT promocion_traslado;
DO $$
BEGIN
        INSERT INTO version_plan_estudios VALUES
            (105,10,DATE '2026-07-01',NULL);
        INSERT INTO participacion_plan
            (codigo_curso,id_version_plan,tipo_participacion)
        VALUES ('UH-PROG1',105,'Obligatorio');
        INSERT INTO requisito_curso
            (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito)
        VALUES (105,'UH-PROG1','UH-MAT1','Requisito previo',9950);
        INSERT INTO estudiante VALUES ('UH-ALU13','Estudiante','Trece',NULL);
        INSERT INTO contacto_estudiante VALUES (613,'UH-ALU13','correo','alu13@example.test',TRUE);
        INSERT INTO admision VALUES
            (13,'UH-ALU13',1,102,DATE '2026-01-01','regular',TRUE);
        INSERT INTO grupo VALUES
            (99,99,'UH-PROG1',1,1,0,'virtual','cerrada');
        INSERT INTO bloque_horario VALUES
            (999,99,5,TIME '18:00',TIME '19:00',FALSE,NULL);
        INSERT INTO grupo_docente VALUES (99,1,'responsable');
        PERFORM set_config('universidad.instante_efectivo',
                           '2026-06-30 12:00-06',TRUE);
        UPDATE grupo SET estado_oferta='abierta' WHERE id_grupo=99;
        PERFORM set_config('universidad.instante_efectivo','',TRUE);
        INSERT INTO solicitud_matricula
            (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,
             fecha_solicitud,estado,razon_rechazo_espera,orden_espera)
        VALUES (9900,13,99,102,'2026-07-04 10:00-06',
                'en_espera','Evaluacion pendiente',1);
        INSERT INTO traslado_plan
            (id_traslado,id_admision,id_version_origen,id_version_destino,
             fecha,motivo,id_autorizador)
        VALUES (9900,13,102,105,'2026-07-05 10:00-06',
                'Traslado de version',1);
        UPDATE admision SET id_version_plan=105 WHERE id_admision=13;
        PERFORM set_config('universidad.instante_efectivo','2026-07-06 10:00-06',TRUE);
        UPDATE grupo SET capacidad=1 WHERE id_grupo=99;
        PERFORM set_config('universidad.instante_efectivo','',TRUE);
        PERFORM pg_temp.esperar_rechazo(
            'promocion sin el requisito del nuevo plan',
            $sql$UPDATE solicitud_matricula SET estado='matriculada',
                momento_transicion='2026-07-06 11:00-06' WHERE id_solicitud=9900$sql$,
            'uh_matricula_requisitos');
        INSERT INTO excepcion_requisito
            (id_excepcion,id_solicitud,id_requisito,id_autorizador,fecha_autorizacion,motivo)
        VALUES (9950,9900,9950,1,'2026-07-06 10:45-06','Excepcion de la version 105');
        UPDATE solicitud_matricula SET estado='matriculada',
            momento_transicion='2026-07-06 11:00-06'
        WHERE id_solicitud=9900;
        SET CONSTRAINTS ALL IMMEDIATE;
        IF NOT EXISTS (
            SELECT 1 FROM solicitud_matricula
            WHERE id_solicitud=9900 AND id_version_plan_evaluada=102
              AND estado='matriculada' AND orden_espera=1
              AND public.uh_plan_aplicable(id_admision,momento_transicion)=105
              AND public.uh_estado_en_instante(id_solicitud,momento_transicion)='matriculada'
        ) THEN
            RAISE EXCEPTION 'La promocion no conservo la trayectoria de la solicitud';
        END IF;
END;
$$;
ROLLBACK TO SAVEPOINT promocion_traslado;
RELEASE SAVEPOINT promocion_traslado;

-- Una correccion incoherente con el resultado y su historial debe rechazarse.
SELECT pg_temp.esperar_rechazo(
    'correccion academica historica incoherente',
    $$INSERT INTO historial_correccion_calificacion
       (id_correccion,id_solicitud,calificacion_anterior,calificacion_nueva,
        resultado_anterior,resultado_nuevo,fecha_correccion,motivo,id_autorizador)
       VALUES (990,1003,'B','C','reprobado','aprobado',
               '2026-12-16 10:00-06','Revision sin efecto actual',1)$$,
    'uh_historial_evento_automatico');

-- La cancelacion desde un grupo cerrado no inventa una apertura previa.
DO $$
BEGIN
  BEGIN
    UPDATE grupo SET estado_oferta='cancelada' WHERE id_grupo=13;
    SET CONSTRAINTS ALL IMMEDIATE;
    IF NOT EXISTS (
        SELECT 1 FROM historial_oferta WHERE id_grupo=13
          AND tipo_cambio='cancelacion' AND estado_anterior='cerrada'
    ) OR EXISTS (
        SELECT 1 FROM historial_oferta WHERE id_grupo=13
          AND tipo_cambio='apertura'
    ) THEN
        RAISE EXCEPTION 'La cancelacion previa a apertura se represento incorrectamente';
    END IF;
    RAISE EXCEPTION 'Reversion controlada' USING ERRCODE='P9001';
  EXCEPTION WHEN SQLSTATE 'P9001' THEN
    RAISE NOTICE 'Cancelacion sin apertura inventada comprobada y revertida';
  END;
END;
$$;
SET CONSTRAINTS ALL DEFERRED;

-- La cancelacion registra el cambio y conserva las solicitudes existentes.
UPDATE grupo SET estado_oferta='cancelada' WHERE id_grupo=12;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM solicitud_matricula WHERE id_grupo=12) <> 6 THEN
    RAISE EXCEPTION 'La cancelacion elimino solicitudes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM historial_oferta
    WHERE id_grupo=12 AND tipo_cambio='cancelacion' AND estado_nuevo='cancelada'
      AND id_responsable=1) THEN
    RAISE EXCEPTION 'La cancelacion no quedo auditada';
  END IF;
END;
$$;

ROLLBACK;
BEGIN ISOLATION LEVEL REPEATABLE READ;
DO $$
BEGIN
    BEGIN
        UPDATE public.grupo SET capacidad=capacidad WHERE FALSE;
        RAISE EXCEPTION 'La escritura bajo REPEATABLE READ fue admitida';
    EXCEPTION WHEN SQLSTATE '25001' THEN
        RAISE NOTICE 'Se rechazo el aislamiento con instantanea fija';
    END;
END;
$$;
ROLLBACK;

BEGIN ISOLATION LEVEL SERIALIZABLE;
DO $$
BEGIN
    BEGIN
        UPDATE public.grupo SET capacidad=capacidad WHERE FALSE;
        RAISE EXCEPTION 'La escritura bajo SERIALIZABLE fue admitida';
    EXCEPTION WHEN SQLSTATE '25001' THEN
        RAISE NOTICE 'Se rechazo el aislamiento con instantanea fija';
    END;
END;
$$;
ROLLBACK;

-- Las pruebas de concurrencia se ejecutan por separado, en sesiones
-- PostgreSQL independientes, según los guiones y Pruebas.md.