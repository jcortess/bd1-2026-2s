\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = huellas, pg_catalog;

CREATE FUNCTION _solo_insercion_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    RAISE EXCEPTION USING ERRCODE='P2001', MESSAGE='El hecho histórico es inmutable: ' || TG_TABLE_NAME;
END $$;

-- Serialización compatible con P01/P03: primero el bloqueo compartido, luego la solicitud.
-- También cubre cargas como propietario. READ COMMITTED permite releer tras la espera.
CREATE TRIGGER reporte_serializar BEFORE INSERT OR UPDATE OR DELETE ON reporte
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER reporte_animal_serializar BEFORE INSERT OR UPDATE OR DELETE ON reporte_animal
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER evaluacion_serializar BEFORE INSERT OR UPDATE OR DELETE ON evaluacion_salud
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER diagnostico_serializar BEFORE INSERT OR UPDATE OR DELETE ON diagnostico
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER diagnostico_revision_serializar BEFORE INSERT OR UPDATE OR DELETE ON diagnostico_revision
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER disponibilidad_serializar BEFORE INSERT OR UPDATE OR DELETE ON cambio_disponibilidad
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER solicitud_serializar BEFORE INSERT OR UPDATE OR DELETE ON solicitud_adopcion
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER interes_serializar BEFORE INSERT OR UPDATE OR DELETE ON solicitud_animal
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER evento_serializar BEFORE INSERT OR UPDATE OR DELETE ON evento_solicitud
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER compatibilidad_serializar BEFORE INSERT OR UPDATE OR DELETE ON compatibilidad_animal_hogar
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();

CREATE TRIGGER evaluacion_historia BEFORE UPDATE OR DELETE ON evaluacion_salud
    FOR EACH ROW EXECUTE FUNCTION _solo_insercion_paula();
CREATE TRIGGER diagnostico_revision_historia BEFORE UPDATE OR DELETE ON diagnostico_revision
    FOR EACH ROW EXECUTE FUNCTION _solo_insercion_paula();
CREATE TRIGGER disponibilidad_historia BEFORE UPDATE OR DELETE ON cambio_disponibilidad
    FOR EACH ROW EXECUTE FUNCTION _solo_insercion_paula();
CREATE TRIGGER solicitud_historia BEFORE UPDATE OR DELETE ON solicitud_adopcion
    FOR EACH ROW EXECUTE FUNCTION _solo_insercion_paula();
CREATE TRIGGER interes_historia BEFORE UPDATE OR DELETE ON solicitud_animal
    FOR EACH ROW EXECUTE FUNCTION _solo_insercion_paula();
CREATE TRIGGER evento_historia BEFORE UPDATE OR DELETE ON evento_solicitud
    FOR EACH ROW EXECUTE FUNCTION _solo_insercion_paula();
CREATE TRIGGER compatibilidad_historia BEFORE UPDATE OR DELETE ON compatibilidad_animal_hogar
    FOR EACH ROW EXECUTE FUNCTION _solo_insercion_paula();

CREATE FUNCTION _fecha_real_paula(p_fecha timestamptz) RETURNS void
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    IF p_fecha IS NULL OR NOT isfinite(p_fecha) OR p_fecha > clock_timestamp() THEN
        RAISE EXCEPTION USING ERRCODE='P2002', MESSAGE='Fecha real ausente, infinita o futura';
    END IF;
END $$;

CREATE FUNCTION _personal_paula(p_persona bigint, p_fecha timestamptz) RETURNS bigint
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_id bigint;
BEGIN
    IF NOT EXISTS (SELECT FROM persona WHERE id_persona=p_persona) THEN
        RAISE EXCEPTION USING ERRCODE='P2003', MESSAGE='Persona responsable inexistente o ausente';
    END IF;
    SELECT id_participacion INTO v_id FROM participacion
    WHERE persona_id=p_persona AND tipo_participacion IN ('PERSONAL_PERMANENTE','VOLUNTARIO')
        AND fecha_inicio <= p_fecha AND (fecha_fin IS NULL OR p_fecha < fecha_fin)
    ORDER BY id_participacion LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='P2004', MESSAGE='La decisión o actividad requiere personal/voluntario vigente';
    END IF;
    RETURN v_id;
END $$;

CREATE FUNCTION _contexto_solicitud_paula(p_solicitud bigint, p_fecha timestamptz) RETURNS void
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_fecha timestamptz;
BEGIN
    SELECT fecha_solicitud INTO v_fecha FROM solicitud_adopcion WHERE id_solicitud=p_solicitud FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='P2005', MESSAGE='Solicitud inexistente';
    END IF;
    PERFORM _fecha_real_paula(p_fecha);
    IF p_fecha < v_fecha THEN
        RAISE EXCEPTION USING ERRCODE='P2002', MESSAGE='El hecho precede a su solicitud';
    END IF;
END $$;

CREATE FUNCTION _validar_fecha_reporte_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    IF NEW.fecha_reporte IS NOT NULL THEN PERFORM _fecha_real_paula(NEW.fecha_reporte); END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER reporte_fecha BEFORE INSERT OR UPDATE ON reporte
    FOR EACH ROW EXECUTE FUNCTION _validar_fecha_reporte_paula();

CREATE FUNCTION _validar_evaluacion_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_etapa ingreso%ROWTYPE; v_registro participacion%ROWTYPE;
BEGIN
    PERFORM _fecha_real_paula(NEW.fecha_evaluacion);
    SELECT * INTO v_etapa FROM ingreso WHERE id_ingreso=NEW.ingreso_id;
    -- La FK conserva el diagnóstico de referencia ausente/contexto animal incorrecto.
    IF FOUND AND NEW.animal_codigo=v_etapa.animal_codigo THEN
        IF NEW.fecha_evaluacion < v_etapa.fecha_ingreso OR
            (v_etapa.fecha_cierre IS NOT NULL AND NEW.fecha_evaluacion >= v_etapa.fecha_cierre) THEN
            RAISE EXCEPTION USING ERRCODE='P2010', MESSAGE='Evaluación fuera del periodo de ingreso';
        END IF;
        IF NEW.tipo_evaluacion='REVISION_VETERINARIA' AND NOT EXISTS (
            SELECT FROM evaluacion_salud WHERE ingreso_id=NEW.ingreso_id AND tipo_evaluacion='INICIAL'
                AND fecha_evaluacion <= NEW.fecha_evaluacion) THEN
            RAISE EXCEPTION USING ERRCODE='P2011', MESSAGE='La revisión requiere evaluación inicial previa en esta etapa';
        END IF;
    END IF;
    IF NEW.veterinario_id IS NOT NULL AND NEW.registro_veterinario_id IS NOT NULL THEN
        SELECT * INTO v_registro FROM participacion WHERE id_participacion=NEW.registro_veterinario_id;
        IF NOT FOUND OR v_registro.persona_id<>NEW.veterinario_id OR v_registro.tipo_participacion<>'VETERINARIO'
           OR v_registro.estado_aprobacion_registro IS DISTINCT FROM 'REGISTRADO'
           OR v_registro.fecha_aprobacion_registro > NEW.fecha_evaluacion
           OR v_registro.fecha_inicio > NEW.fecha_evaluacion
           OR (v_registro.fecha_fin IS NOT NULL AND NEW.fecha_evaluacion >= v_registro.fecha_fin) THEN
            RAISE EXCEPTION USING ERRCODE='P2012', MESSAGE='Profesional sin registro veterinario vigente en esa fecha';
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER evaluacion_contexto BEFORE INSERT ON evaluacion_salud
    FOR EACH ROW EXECUTE FUNCTION _validar_evaluacion_paula();

CREATE FUNCTION _exigir_inicial_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_id bigint;
BEGIN
    IF TG_TABLE_NAME='ingreso' THEN v_id:=NEW.id_ingreso; ELSE v_id:=NEW.ingreso_id; END IF;
    IF EXISTS (SELECT FROM ingreso WHERE id_ingreso=v_id) AND NOT EXISTS
       (SELECT FROM evaluacion_salud WHERE ingreso_id=v_id AND tipo_evaluacion='INICIAL') THEN
        RAISE EXCEPTION USING ERRCODE='P2013', MESSAGE='El ingreso requiere evaluación inicial al confirmar';
    END IF;
    RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER ingreso_inicial_paula AFTER INSERT OR UPDATE ON ingreso
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION _exigir_inicial_paula();
CREATE CONSTRAINT TRIGGER evaluacion_inicial_paula AFTER INSERT ON evaluacion_salud
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION _exigir_inicial_paula();

CREATE FUNCTION _preservar_etapa_clinica_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    IF EXISTS (SELECT FROM evaluacion_salud WHERE ingreso_id=OLD.id_ingreso) AND
       ((NEW.id_ingreso,NEW.animal_codigo,NEW.fecha_ingreso) IS DISTINCT FROM
        (OLD.id_ingreso,OLD.animal_codigo,OLD.fecha_ingreso)
        OR EXISTS (SELECT FROM evaluacion_salud WHERE ingreso_id=OLD.id_ingreso AND fecha_evaluacion >= NEW.fecha_cierre)
        OR EXISTS (SELECT FROM cambio_disponibilidad WHERE ingreso_id=OLD.id_ingreso AND fecha >= NEW.fecha_cierre)
        OR EXISTS (SELECT FROM compatibilidad_animal_hogar WHERE ingreso_id=OLD.id_ingreso AND fecha >= NEW.fecha_cierre)) THEN
        RAISE EXCEPTION USING ERRCODE='P2014', MESSAGE='La modificación del ingreso invalida su contexto clínico/evaluado';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER zz_ingreso_contexto_paula BEFORE UPDATE ON ingreso
    FOR EACH ROW EXECUTE FUNCTION _preservar_etapa_clinica_paula();

CREATE FUNCTION _preservar_registro_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_ultima timestamptz;
BEGIN
    SELECT max(fecha) INTO v_ultima FROM (
        SELECT fecha_evaluacion AS fecha FROM evaluacion_salud WHERE registro_veterinario_id=OLD.id_participacion
        UNION ALL SELECT fecha FROM evento_solicitud WHERE participacion_responsable_id=OLD.id_participacion
        UNION ALL SELECT fecha FROM cambio_disponibilidad WHERE participacion_responsable_id=OLD.id_participacion
        UNION ALL SELECT fecha FROM compatibilidad_animal_hogar WHERE participacion_responsable_id=OLD.id_participacion
    ) f;
    IF v_ultima IS NOT NULL AND
       ((NEW.id_participacion,NEW.persona_id,NEW.tipo_participacion,NEW.fecha_inicio,
         NEW.estado_aprobacion_registro,NEW.fecha_aprobacion_registro) IS DISTINCT FROM
        (OLD.id_participacion,OLD.persona_id,OLD.tipo_participacion,OLD.fecha_inicio,
         OLD.estado_aprobacion_registro,OLD.fecha_aprobacion_registro)
        OR NEW.fecha_fin <= v_ultima) THEN
        RAISE EXCEPTION USING ERRCODE='P2015', MESSAGE='La participación respalda hechos históricos de Paula';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER participacion_contexto_paula BEFORE UPDATE ON participacion
    FOR EACH ROW EXECUTE FUNCTION _preservar_registro_paula();

CREATE FUNCTION _validar_disponibilidad_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_etapa ingreso%ROWTYPE; v_anterior timestamptz;
BEGIN
    PERFORM _fecha_real_paula(NEW.fecha);
    IF NEW.participacion_responsable_id IS DISTINCT FROM _personal_paula(NEW.responsable_id,NEW.fecha) THEN
        RAISE EXCEPTION USING ERRCODE='P2004', MESSAGE='Participación del responsable incorrecta';
    END IF;
    SELECT * INTO v_etapa FROM ingreso WHERE id_ingreso=NEW.ingreso_id;
    IF FOUND AND v_etapa.animal_codigo=NEW.animal_codigo AND
       (NEW.fecha < v_etapa.fecha_ingreso OR (v_etapa.fecha_cierre IS NOT NULL AND NEW.fecha >= v_etapa.fecha_cierre)) THEN
        RAISE EXCEPTION USING ERRCODE='P2010', MESSAGE='Disponibilidad fuera de la etapa';
    END IF;
    SELECT max(fecha) INTO v_anterior FROM cambio_disponibilidad
        WHERE animal_codigo=NEW.animal_codigo AND ingreso_id=NEW.ingreso_id;
    IF NEW.fecha < v_anterior THEN
        RAISE EXCEPTION USING ERRCODE='P2002', MESSAGE='Disponibilidad anterior a la decisión vigente';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER disponibilidad_contexto BEFORE INSERT ON cambio_disponibilidad
    FOR EACH ROW EXECUTE FUNCTION _validar_disponibilidad_paula();

CREATE FUNCTION _validar_solicitud_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    PERFORM _fecha_real_paula(NEW.fecha_solicitud);
    RETURN NEW;
END $$;
CREATE TRIGGER solicitud_fecha BEFORE INSERT ON solicitud_adopcion
    FOR EACH ROW EXECUTE FUNCTION _validar_solicitud_paula();

CREATE FUNCTION _exigir_recepcion_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    IF NOT EXISTS (SELECT FROM evento_solicitud WHERE solicitud_id=NEW.id_solicitud AND tipo_evento='RECEPCION') THEN
        RAISE EXCEPTION USING ERRCODE='P2020', MESSAGE='Solicitud sin recepción atribuible';
    END IF;
    RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER solicitud_recepcion AFTER INSERT ON solicitud_adopcion
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION _exigir_recepcion_paula();

CREATE FUNCTION _validar_interes_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    PERFORM _contexto_solicitud_paula(NEW.solicitud_id,NEW.fecha_interes);
    RETURN NEW;
END $$;
CREATE TRIGGER interes_contexto BEFORE INSERT ON solicitud_animal
    FOR EACH ROW EXECUTE FUNCTION _validar_interes_paula();

CREATE FUNCTION _validar_evento_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_anterior evento_solicitud%ROWTYPE;
BEGIN
    PERFORM _contexto_solicitud_paula(NEW.solicitud_id,NEW.fecha);
    IF NEW.participacion_responsable_id IS DISTINCT FROM _personal_paula(NEW.responsable_id,NEW.fecha) THEN
        RAISE EXCEPTION USING ERRCODE='P2004', MESSAGE='Participación del responsable incorrecta';
    END IF;
    IF NEW.tipo_evento IN ('RECEPCION','DECISION') THEN
        SELECT * INTO v_anterior FROM evento_solicitud WHERE solicitud_id=NEW.solicitud_id
            AND estado_resultante IS NOT NULL ORDER BY fecha DESC,id_evento_solicitud DESC LIMIT 1;
        IF NEW.tipo_evento='DECISION' AND v_anterior.id_evento_solicitud IS NULL THEN
            RAISE EXCEPTION USING ERRCODE='P2020', MESSAGE='Decisión sin recepción previa';
        END IF;
        IF NEW.antecedente_decision_id IS DISTINCT FROM v_anterior.id_evento_solicitud THEN
            RAISE EXCEPTION USING ERRCODE='P2021', MESSAGE='Antecedente desactualizado; relea la decisión y no reintente a ciegas';
        END IF;
        IF NEW.fecha < v_anterior.fecha THEN
            RAISE EXCEPTION USING ERRCODE='P2002', MESSAGE='La decisión precede a su antecedente';
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER evento_contexto BEFORE INSERT ON evento_solicitud
    FOR EACH ROW EXECUTE FUNCTION _validar_evento_paula();

CREATE FUNCTION _validar_compatibilidad_paula() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_fecha timestamptz; v_etapa ingreso%ROWTYPE; v_evento evento_solicitud%ROWTYPE;
BEGIN
    PERFORM _contexto_solicitud_paula(NEW.solicitud_id,NEW.fecha);
    IF NEW.participacion_responsable_id IS DISTINCT FROM _personal_paula(NEW.responsable_id,NEW.fecha) THEN
        RAISE EXCEPTION USING ERRCODE='P2004', MESSAGE='Participación del responsable incorrecta';
    END IF;
    SELECT fecha_interes INTO v_fecha FROM solicitud_animal
        WHERE solicitud_id=NEW.solicitud_id AND animal_codigo=NEW.animal_codigo;
    IF NEW.fecha < v_fecha THEN
        RAISE EXCEPTION USING ERRCODE='P2002', MESSAGE='Compatibilidad anterior al interés';
    END IF;
    SELECT * INTO v_etapa FROM ingreso WHERE id_ingreso=NEW.ingreso_id;
    IF FOUND AND v_etapa.animal_codigo=NEW.animal_codigo AND
       (NEW.fecha < v_etapa.fecha_ingreso OR (v_etapa.fecha_cierre IS NOT NULL AND NEW.fecha >= v_etapa.fecha_cierre)) THEN
        RAISE EXCEPTION USING ERRCODE='P2010', MESSAGE='Compatibilidad fuera de la etapa';
    END IF;
    IF NEW.actividad_contexto_id IS NOT NULL THEN
        SELECT * INTO v_evento FROM evento_solicitud WHERE id_evento_solicitud=NEW.actividad_contexto_id;
        IF FOUND AND v_evento.solicitud_id=NEW.solicitud_id AND
           (v_evento.estado_resultante IS NOT NULL OR NEW.fecha < v_evento.fecha) THEN
            RAISE EXCEPTION USING ERRCODE='P2022', MESSAGE='El contexto debe ser una actividad previa de esa solicitud';
        END IF;
    END IF;
    SELECT max(fecha) INTO v_fecha FROM compatibilidad_animal_hogar
        WHERE solicitud_id=NEW.solicitud_id AND animal_codigo=NEW.animal_codigo AND ingreso_id=NEW.ingreso_id;
    IF NEW.fecha < v_fecha THEN
        RAISE EXCEPTION USING ERRCODE='P2002', MESSAGE='Reevaluación anterior a la valoración vigente';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER compatibilidad_contexto BEFORE INSERT ON compatibilidad_animal_hogar
    FOR EACH ROW EXECUTE FUNCTION _validar_compatibilidad_paula();

CREATE FUNCTION crear_solicitud(p_clave uuid,p_solicitante bigint,p_fecha timestamptz,
    p_vivienda text,p_integrantes text,p_experiencia text,p_cuidado text,p_responsable bigint,
    p_animales text[] DEFAULT ARRAY[]::text[]) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_id bigint; v_registro bigint; v_animal text;
BEGIN
    PERFORM _bloquear_alojamiento();
    v_registro := _personal_paula(p_responsable,p_fecha);
    INSERT INTO solicitud_adopcion(clave_operacion,solicitante_id,fecha_solicitud,informacion_vivienda,
        integrantes_hogar,experiencia_animales,condiciones_cuidado)
    VALUES(p_clave,p_solicitante,p_fecha,p_vivienda,p_integrantes,p_experiencia,p_cuidado)
    RETURNING id_solicitud INTO v_id;
    INSERT INTO evento_solicitud(clave_operacion,solicitud_id,fecha,tipo_evento,responsable_id,
        participacion_responsable_id,estado_resultante,razon)
    VALUES(p_clave,v_id,p_fecha,'RECEPCION',p_responsable,v_registro,'RECIBIDA','Recepción de solicitud');
    FOREACH v_animal IN ARRAY coalesce(p_animales,ARRAY[]::text[]) LOOP
        INSERT INTO solicitud_animal VALUES(v_id,v_animal,p_fecha);
    END LOOP;
    RETURN v_id;
END $$;

CREATE FUNCTION asociar_animal(p_solicitud bigint,p_animal text,p_fecha timestamptz) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, huellas, pg_temp AS $$
BEGIN
    PERFORM _bloquear_alojamiento();
    INSERT INTO solicitud_animal VALUES(p_solicitud,p_animal,p_fecha);
END $$;

CREATE FUNCTION registrar_actividad(p_clave uuid,p_solicitud bigint,p_fecha timestamptz,
    p_responsable bigint,p_tipo text,p_resultado text,p_observaciones text) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_id bigint;
BEGIN
    PERFORM _bloquear_alojamiento();
    IF p_tipo IS NULL OR p_tipo NOT IN ('ENTREVISTA','VISITA_HOGAR','INFORMACION','OTRA_ACTIVIDAD') THEN
        RAISE EXCEPTION USING ERRCODE='P2023', MESSAGE='Tipo de actividad inválido; use decidir_solicitud para estados';
    END IF;
    INSERT INTO evento_solicitud(clave_operacion,solicitud_id,fecha,tipo_evento,responsable_id,
        participacion_responsable_id,resultado_actividad,observaciones)
    VALUES(p_clave,p_solicitud,p_fecha,p_tipo,p_responsable,_personal_paula(p_responsable,p_fecha),p_resultado,p_observaciones)
    RETURNING id_evento_solicitud INTO v_id;
    RETURN v_id;
END $$;

CREATE FUNCTION decidir_solicitud(p_clave uuid,p_solicitud bigint,p_antecedente bigint,p_fecha timestamptz,
    p_responsable bigint,p_estado text,p_razon text,p_observaciones text DEFAULT NULL) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_id bigint;
BEGIN
    PERFORM _bloquear_alojamiento();
    INSERT INTO evento_solicitud(clave_operacion,solicitud_id,fecha,tipo_evento,responsable_id,
        participacion_responsable_id,estado_resultante,razon,observaciones,antecedente_decision_id)
    VALUES(p_clave,p_solicitud,p_fecha,'DECISION',p_responsable,_personal_paula(p_responsable,p_fecha),
        p_estado,p_razon,p_observaciones,p_antecedente)
    RETURNING id_evento_solicitud INTO v_id;
    RETURN v_id;
END $$;

CREATE FUNCTION evaluar_compatibilidad(p_clave uuid,p_solicitud bigint,p_animal text,p_ingreso bigint,
    p_fecha timestamptz,p_responsable bigint,p_resultado text,p_valoracion text,p_razon text,
    p_observaciones text,p_actividad bigint DEFAULT NULL) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE v_id bigint;
BEGIN
    PERFORM _bloquear_alojamiento();
    INSERT INTO compatibilidad_animal_hogar(clave_operacion,solicitud_id,animal_codigo,ingreso_id,fecha,
        responsable_id,participacion_responsable_id,resultado,valoracion_hogar,razon,observaciones,actividad_contexto_id)
    VALUES(p_clave,p_solicitud,p_animal,p_ingreso,p_fecha,p_responsable,_personal_paula(p_responsable,p_fecha),
        p_resultado,p_valoracion,p_razon,p_observaciones,p_actividad)
    RETURNING id_compatibilidad INTO v_id;
    RETURN v_id;
END $$;

-- Reutilización adaptada de Lab03 sql/04_rutinas.sql: misma consulta, esquema y tipo actuales.
CREATE FUNCTION contar_revisiones_animal(p_codigo_animal text) RETURNS integer
LANGUAGE plpgsql STABLE SET search_path = pg_catalog, huellas, pg_temp AS $$
DECLARE total integer;
BEGIN
    SELECT count(*) INTO total FROM evaluacion_salud
    WHERE animal_codigo=p_codigo_animal AND tipo_evaluacion='REVISION_VETERINARIA';
    RETURN total;
END $$;

REVOKE ALL ON FUNCTION _solo_insercion_paula(),_fecha_real_paula(timestamptz),_personal_paula(bigint,timestamptz),
    _contexto_solicitud_paula(bigint,timestamptz),_validar_fecha_reporte_paula(),_validar_evaluacion_paula(),
    _exigir_inicial_paula(),_preservar_etapa_clinica_paula(),_preservar_registro_paula(),
    _validar_disponibilidad_paula(),_validar_solicitud_paula(),_exigir_recepcion_paula(),
    _validar_interes_paula(),_validar_evento_paula(),_validar_compatibilidad_paula() FROM PUBLIC;
REVOKE ALL ON FUNCTION crear_solicitud(uuid,bigint,timestamptz,text,text,text,text,bigint,text[]),
    asociar_animal(bigint,text,timestamptz),registrar_actividad(uuid,bigint,timestamptz,bigint,text,text,text),
    decidir_solicitud(uuid,bigint,bigint,timestamptz,bigint,text,text,text),
    evaluar_compatibilidad(uuid,bigint,text,bigint,timestamptz,bigint,text,text,text,text,bigint),
    contar_revisiones_animal(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION crear_solicitud(uuid,bigint,timestamptz,text,text,text,text,bigint,text[]),
    asociar_animal(bigint,text,timestamptz),registrar_actividad(uuid,bigint,timestamptz,bigint,text,text,text),
    decidir_solicitud(uuid,bigint,bigint,timestamptz,bigint,text,text,text),
    evaluar_compatibilidad(uuid,bigint,text,bigint,timestamptz,bigint,text,text,text,text,bigint),
    contar_revisiones_animal(text) TO huellas_g05_operador;
GRANT SELECT ON reporte,reporte_animal,evaluacion_salud,diagnostico,diagnostico_revision,cambio_disponibilidad,
    solicitud_adopcion,solicitud_animal,evento_solicitud,compatibilidad_animal_hogar TO huellas_g05_operador;
COMMIT;
