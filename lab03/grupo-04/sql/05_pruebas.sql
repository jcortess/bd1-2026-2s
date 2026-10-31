-- Precondicion general: 01,02,04 ejecutados sobre una base limpia.
-- Datos T* aislados y revertidos; repetir no modifica el conjunto inicial.
BEGIN;
CREATE TEMP TABLE resultados_pruebas (
 id text PRIMARY KEY, precondicion text NOT NULL, sentencia text NOT NULL,
 esperado text NOT NULL, observado text NOT NULL, conclusion text NOT NULL
) ON COMMIT DROP;
-- Ayudantes de pruebas, NO funciones de negocio adicionales.
CREATE FUNCTION pg_temp.comprobar(p_id text,p_ok boolean,p_sentencia text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF p_ok IS DISTINCT FROM true THEN
   RAISE EXCEPTION 'FALLO %: %',p_id,p_sentencia;
 END IF;
 INSERT INTO pg_temp.resultados_pruebas VALUES
 (p_id,'Base cargada; cambios previos solo de esta transaccion',p_sentencia,'true','true','ACEPTADA');
END;
$$;
CREATE FUNCTION pg_temp.esperar_rechazo(
 p_id text,p_sql text,p_estado text,p_restriccion text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_estado text; v_restriccion text;
BEGIN
 BEGIN
   EXECUTE p_sql;
   -- Fuerza rollback incluso si la operacion fue aceptada indebidamente.
   RAISE EXCEPTION USING ERRCODE='ZX001', MESSAGE='Operacion aceptada cuando debia rechazarse';
 EXCEPTION WHEN OTHERS THEN
   GET STACKED DIAGNOSTICS v_estado=RETURNED_SQLSTATE,v_restriccion=CONSTRAINT_NAME;
 END;
 IF v_estado IS DISTINCT FROM p_estado OR
    (p_restriccion IS NOT NULL AND v_restriccion IS DISTINCT FROM p_restriccion) THEN
   RAISE EXCEPTION 'FALLO %: esperado % / %, observado % / %',
      p_id,p_estado,p_restriccion,v_estado,v_restriccion;
 END IF;
 INSERT INTO pg_temp.resultados_pruebas VALUES
 (p_id,'Base cargada; subtransaccion revertida',p_sql,p_estado,
  v_estado||coalesce(' / '||nullif(v_restriccion,''),''),'RECHAZO CORRECTO');
END;
$$;
SELECT pg_temp.comprobar('T-01', public.fn_persona_tiene_facultad(2,2,1,TIMESTAMPTZ '2026-10-29 10:00:00-06'), 'Facultad vigente: organizacion 2, persona 2, facultad 1');
SELECT pg_temp.comprobar('T-02', public.fn_contar_autorizaciones_activas(2,TIMESTAMPTZ '2026-10-29 10:00:00-06')=3, 'Conteo cliente 2: 3 otorgamientos, aunque solo 2 personas');
SELECT pg_temp.comprobar('T-03', NOT public.fn_persona_tiene_facultad(3,2,1,TIMESTAMPTZ '2026-10-29 10:00:00-06'), 'Una facultad para cliente 2 no autoriza actuar para cliente 3');
SELECT pg_temp.comprobar('T-04', NOT public.fn_persona_tiene_facultad(2,4,1,TIMESTAMPTZ '2026-10-29 10:00:00-06') AND NOT public.fn_persona_tiene_facultad(2,5,1,TIMESTAMPTZ '2026-10-29 10:00:00-06'), 'Rechazo logico de autorizaciones vencidas y futuras');
SELECT pg_temp.comprobar('T-05', public.fn_persona_tiene_facultad(2,2,1,TIMESTAMPTZ '2026-01-01 08:00:00-06') AND NOT public.fn_persona_tiene_facultad(2,2,1,TIMESTAMPTZ '2026-12-31 18:00:00-06'), 'Inicio incluido y fin excluido');
SELECT pg_temp.comprobar('T-06', public.fn_persona_tiene_facultad(2,3,3,TIMESTAMPTZ '2028-01-01 08:00:00-06'), 'Autorizacion abierta permanece vigente despues de 2026');
CALL public.sp_registrar_autorizacion(9001,2,4,TIMESTAMPTZ '2026-10-01 00:00:00-06',NULL,ARRAY[1,3]::bigint[]);
SELECT pg_temp.comprobar('T-07', (SELECT count(*)=1 FROM public.autorizacion WHERE id_autorizacion=9001) AND (SELECT count(*)=2 FROM public.autorizacion_facultad WHERE id_autorizacion=9001), 'Procedimiento exitoso: cabecera 9001 y exactamente dos facultades');
SELECT pg_temp.esperar_rechazo('T-08', 'INSERT INTO public.persona VALUES (90,''Documento de prueba'',''DOC-FICT-001'',''Otra Prueba'')', '23505', 'uq_persona_documento');
SELECT pg_temp.esperar_rechazo('T-09', 'INSERT INTO public.autorizacion VALUES (9002,999,2,''2026-10-01 00:00:00-06'',NULL)', '23503', 'fk_autorizacion_cliente');
SELECT pg_temp.esperar_rechazo('T-10', 'INSERT INTO public.persona VALUES (90,''Documento de prueba'',''DOC-FICT-090'',NULL)', '23502');
SELECT pg_temp.esperar_rechazo('T-11', 'INSERT INTO public.autorizacion VALUES (9002,2,2,''2026-12-01 00:00:00-06'',''2026-01-01 00:00:00-06'')', '23514', 'ck_autorizacion_periodo');
SELECT pg_temp.esperar_rechazo('T-12', 'INSERT INTO public.autorizacion_facultad VALUES (1,1)', '23505', 'pk_autorizacion_facultad');
SELECT pg_temp.esperar_rechazo('T-13', 'CALL public.sp_registrar_autorizacion(9003,1,2,''2026-10-01 00:00:00-06'',NULL,ARRAY[1]::bigint[])', '23514');
SELECT pg_temp.esperar_rechazo('T-14', 'CALL public.sp_registrar_autorizacion(9003,2,2,''2026-10-01 00:00:00-06'',NULL,ARRAY[]::bigint[])', '23514');
SELECT pg_temp.esperar_rechazo('T-15', 'CALL public.sp_registrar_autorizacion(9003,2,2,''2026-10-01 00:00:00-06'',NULL,NULL::bigint[])', '23514');
SELECT pg_temp.esperar_rechazo('T-16', 'CALL public.sp_registrar_autorizacion(9003,2,2,''2026-10-01 00:00:00-06'',NULL,ARRAY[1,NULL]::bigint[])', '23514');
SELECT pg_temp.esperar_rechazo('T-17', 'CALL public.sp_registrar_autorizacion(9003,2,2,''2026-10-01 00:00:00-06'',NULL,ARRAY[1,1]::bigint[])', '22023');
SELECT pg_temp.esperar_rechazo('T-18', 'CALL public.sp_registrar_autorizacion(9003,2,2,''2026-10-01 00:00:00-06'',NULL,ARRAY[1,999]::bigint[])', '23503');
SELECT pg_temp.esperar_rechazo('T-19', 'CALL public.sp_registrar_autorizacion(9003,999,2,''2026-10-01 00:00:00-06'',NULL,ARRAY[1]::bigint[])', '23503');
SELECT pg_temp.esperar_rechazo('T-20', 'SELECT public.fn_persona_tiene_facultad(2,2,1,NULL::timestamptz)', '22004');
SELECT pg_temp.comprobar('T-21', (SELECT count(*)=7 FROM public.autorizacion) AND (SELECT count(*)=10 FROM public.autorizacion_facultad) AND NOT EXISTS (SELECT 1 FROM public.autorizacion WHERE id_autorizacion IN (9002,9003)), 'Sin inserciones parciales: solo permanece el alta valida 9001 dentro de la prueba');
CALL public.sp_preparar_resumen(TIMESTAMPTZ '2026-10-29 10:00:00-06');
CALL public.sp_preparar_resumen(TIMESTAMPTZ '2026-10-29 10:00:00-06');
SELECT pg_temp.comprobar('T-22', (SELECT count(*)=7 FROM pg_temp.resumen_autorizaciones), 'La segunda llamada al resumen reemplaza la temporal sin duplicar filas');
WITH alternativa AS (
 SELECT id_autorizacion,id_cliente,id_persona,
 CASE WHEN TIMESTAMPTZ '2026-10-29 10:00:00-06'<inicio_vigencia THEN 'futura'
      WHEN fin_vigencia IS NOT NULL AND TIMESTAMPTZ '2026-10-29 10:00:00-06'>=fin_vigencia THEN 'vencida'
      ELSE 'vigente' END AS estado FROM public.autorizacion
), diferencias AS (
 (SELECT * FROM alternativa EXCEPT SELECT * FROM pg_temp.resumen_autorizaciones)
 UNION ALL
 (SELECT * FROM pg_temp.resumen_autorizaciones EXCEPT SELECT * FROM alternativa)
)
SELECT pg_temp.comprobar('T-23',NOT EXISTS(SELECT 1 FROM diferencias),'Resumen temporal identico a la alternativa basada en conjuntos');
SELECT * FROM pg_temp.resultados_pruebas ORDER BY id;
ROLLBACK;
