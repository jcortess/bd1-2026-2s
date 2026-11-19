\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = huellas, pg_catalog;

CREATE FUNCTION _bloquear_alojamiento() RETURNS void
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION USING ERRCODE = 'P1001', MESSAGE = 'Alojamiento requiere READ COMMITTED';
    END IF;
    -- Reserva para Huellas Seguras en esta base. Se libera al terminar la transacción.
    PERFORM pg_advisory_xact_lock(50301, 1);
END
$$;

CREATE FUNCTION _serializar_catalogo() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    PERFORM _bloquear_alojamiento();
    RETURN NULL;
END
$$;

CREATE TRIGGER animal_serializar BEFORE INSERT OR UPDATE OR DELETE ON animal
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER ingreso_serializar BEFORE INSERT OR UPDATE OR DELETE ON ingreso
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER participacion_serializar BEFORE INSERT OR UPDATE OR DELETE ON participacion
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER ubicacion_serializar BEFORE INSERT OR UPDATE OR DELETE ON ubicacion
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();
CREATE TRIGGER especie_aceptada_serializar BEFORE INSERT OR UPDATE OR DELETE ON ubicacion_especie_aceptada
    FOR EACH STATEMENT EXECUTE FUNCTION _serializar_catalogo();

CREATE FUNCTION _preservar_animal() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    IF NEW.codigo_interno IS DISTINCT FROM OLD.codigo_interno OR
       (NEW.especie IS DISTINCT FROM OLD.especie AND
        EXISTS (SELECT FROM estancia WHERE animal_codigo = OLD.codigo_interno)) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1002', MESSAGE = 'La identidad o especie histórica del animal es fija';
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER animal_historia BEFORE UPDATE ON animal
    FOR EACH ROW EXECUTE FUNCTION _preservar_animal();

CREATE FUNCTION _preservar_ingreso() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    IF (OLD.fecha_cierre IS NOT NULL AND NEW.fecha_cierre IS DISTINCT FROM OLD.fecha_cierre) OR
       (NEW.fecha_cierre IS NOT NULL AND EXISTS (
            SELECT FROM estancia WHERE ingreso_id = OLD.id_ingreso
            AND (fecha_fin_real IS NULL OR fecha_fin_real > NEW.fecha_cierre)
       )) OR
       ((NEW.id_ingreso, NEW.animal_codigo, NEW.fecha_ingreso) IS DISTINCT FROM
        (OLD.id_ingreso, OLD.animal_codigo, OLD.fecha_ingreso) AND
        EXISTS (SELECT FROM estancia WHERE ingreso_id = OLD.id_ingreso)) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1002', MESSAGE = 'El cambio de etapa contradice su historial de alojamiento';
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER ingreso_historia BEFORE UPDATE ON ingreso
    FOR EACH ROW EXECUTE FUNCTION _preservar_ingreso();

CREATE FUNCTION _preservar_participacion() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    IF EXISTS (SELECT FROM estancia WHERE aprobacion_hogar_id = OLD.id_participacion) AND (
        (NEW.id_participacion, NEW.persona_id, NEW.tipo_participacion, NEW.fecha_inicio,
         NEW.requisitos, NEW.estado_aprobacion_registro, NEW.fecha_aprobacion_registro)
        IS DISTINCT FROM
        (OLD.id_participacion, OLD.persona_id, OLD.tipo_participacion, OLD.fecha_inicio,
         OLD.requisitos, OLD.estado_aprobacion_registro, OLD.fecha_aprobacion_registro)
        OR EXISTS (SELECT FROM estancia WHERE aprobacion_hogar_id = OLD.id_participacion
                   AND fecha_inicio_real >= NEW.fecha_fin)
    ) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1002', MESSAGE = 'El cambio invalida una aprobación histórica';
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER participacion_historia BEFORE UPDATE ON participacion
    FOR EACH ROW EXECUTE FUNCTION _preservar_participacion();

CREATE FUNCTION _preservar_ubicacion() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    IF NEW IS DISTINCT FROM OLD AND EXISTS (SELECT FROM estancia WHERE ubicacion_id = OLD.id_ubicacion) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1002', MESSAGE = 'Una ubicación utilizada conserva su configuración histórica';
    END IF;
    IF NEW.tipo_ubicacion <> 'HOGAR_TEMPORAL' AND
       EXISTS (SELECT FROM ubicacion_especie_aceptada WHERE ubicacion_id = OLD.id_ubicacion) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1003', MESSAGE = 'Solo un hogar temporal declara especies admitidas';
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER ubicacion_historia BEFORE UPDATE ON ubicacion
    FOR EACH ROW EXECUTE FUNCTION _preservar_ubicacion();

CREATE FUNCTION _preservar_especies() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    IF TG_OP <> 'DELETE' AND EXISTS (
        SELECT FROM ubicacion WHERE id_ubicacion = NEW.ubicacion_id AND tipo_ubicacion <> 'HOGAR_TEMPORAL'
    ) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1003', MESSAGE = 'Solo un hogar temporal declara especies admitidas';
    END IF;
    IF TG_OP <> 'INSERT' AND EXISTS (
        SELECT FROM estancia e JOIN animal a ON a.codigo_interno = e.animal_codigo
        WHERE e.ubicacion_id = OLD.ubicacion_id AND a.especie = OLD.especie
    ) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1002', MESSAGE = 'La especie admitida respalda una estancia histórica';
    END IF;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER especie_aceptada_historia BEFORE INSERT OR UPDATE OR DELETE ON ubicacion_especie_aceptada
    FOR EACH ROW EXECUTE FUNCTION _preservar_especies();

CREATE FUNCTION mover_animal(
    p_ingreso_id bigint,
    p_estancia_esperada bigint,
    p_destino_id bigint,
    p_fecha_real timestamptz,
    p_actor_id bigint,
    p_condicion_alojamiento text DEFAULT NULL,
    p_inicio_previsto timestamptz DEFAULT NULL,
    p_fin_previsto timestamptz DEFAULT NULL,
    p_condicion_especial text DEFAULT NULL,
    p_valoracion_sanitaria text DEFAULT NULL
) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    etapa ingreso%ROWTYPE;
    anterior estancia%ROWTYPE;
    destino ubicacion%ROWTYPE;
    especie_ingreso especie_animal;
    aprobacion_id bigint;
    nueva_id bigint;
BEGIN
    PERFORM _bloquear_alojamiento();

    SELECT * INTO etapa FROM ingreso WHERE id_ingreso = p_ingreso_id;
    IF NOT FOUND OR etapa.fecha_cierre IS NOT NULL THEN
        RAISE EXCEPTION USING ERRCODE = 'P1004', MESSAGE = 'Se requiere un ingreso existente y abierto';
    END IF;
    IF p_fecha_real IS NULL OR NOT isfinite(p_fecha_real) OR
       p_fecha_real < etapa.fecha_ingreso OR p_fecha_real > clock_timestamp() THEN
        RAISE EXCEPTION USING ERRCODE = 'P1005', MESSAGE = 'El movimiento real debe estar entre el ingreso y el presente';
    END IF;

    SELECT * INTO anterior FROM estancia WHERE animal_codigo = etapa.animal_codigo AND fecha_fin_real IS NULL;
    IF anterior.id_estancia IS DISTINCT FROM p_estancia_esperada THEN
        RAISE EXCEPTION USING ERRCODE = 'P1006', MESSAGE = 'La estancia vigente difiere de la esperada';
    END IF;
    IF anterior.id_estancia IS NOT NULL THEN
        IF anterior.ingreso_id <> etapa.id_ingreso OR p_fecha_real <= anterior.fecha_inicio_real THEN
            RAISE EXCEPTION USING ERRCODE = 'P1005', MESSAGE = 'La salida debe suceder después de la entrada en esta etapa';
        END IF;
        IF anterior.ubicacion_id = p_destino_id THEN
            RAISE EXCEPTION USING ERRCODE = 'P1007', MESSAGE = 'El traslado requiere otra ubicación u oferta';
        END IF;
        IF p_valoracion_sanitaria IS NULL OR p_valoracion_sanitaria !~ '[^[:space:]]' THEN
            RAISE EXCEPTION USING ERRCODE = 'P1008', MESSAGE = 'Registre la valoración sanitaria o su falta de incidencia en el traslado';
        END IF;
    END IF;

    SELECT * INTO destino FROM ubicacion WHERE id_ubicacion = p_destino_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE = 'P1009', MESSAGE = 'La ubicación de destino no existe';
    END IF;

    -- El cierre y el alta son una sola sentencia invocada por el cliente.
    -- Un rechazo posterior a este UPDATE revierte también el cierre.
    UPDATE estancia SET fecha_fin_real = p_fecha_real, actor_salida_id = p_actor_id
    WHERE id_estancia = anterior.id_estancia;

    IF destino.tipo_ubicacion = 'AREA_INTERNA' AND
       p_condicion_alojamiento IS DISTINCT FROM destino.condicion_admitida::text THEN
        RAISE EXCEPTION USING ERRCODE = 'P1010', MESSAGE = 'La condición declarada no coincide con la admitida por el área';
    END IF;

    IF destino.tipo_ubicacion = 'HOGAR_TEMPORAL' THEN
        IF p_inicio_previsto IS NULL OR p_fin_previsto IS NULL OR NOT isfinite(p_inicio_previsto) OR
           NOT isfinite(p_fin_previsto) OR p_inicio_previsto >= p_fin_previsto OR
           p_inicio_previsto < destino.disponibilidad_desde OR p_fin_previsto > destino.disponibilidad_hasta OR
           p_fecha_real < destino.disponibilidad_desde OR p_fecha_real >= destino.disponibilidad_hasta THEN
            RAISE EXCEPTION USING ERRCODE = 'P1011', MESSAGE = 'La llegada real y el plan deben caber en la oferta del hogar';
        END IF;

        SELECT id_participacion INTO aprobacion_id FROM participacion
        WHERE persona_id = destino.persona_oferente_id AND tipo_participacion = 'HOGAR_TEMPORAL'
          AND estado_aprobacion_registro = 'APROBADO' AND fecha_aprobacion_registro < p_fecha_real
          AND fecha_inicio <= p_fecha_real AND (fecha_fin IS NULL OR p_fecha_real < fecha_fin)
        ORDER BY fecha_aprobacion_registro DESC, id_participacion DESC LIMIT 1;
        IF NOT FOUND THEN
            RAISE EXCEPTION USING ERRCODE = 'P1012', MESSAGE = 'El oferente requiere aprobación previa y participación vigente';
        END IF;

        SELECT especie INTO especie_ingreso FROM animal WHERE codigo_interno = etapa.animal_codigo;
        IF NOT EXISTS (SELECT FROM ubicacion_especie_aceptada
                       WHERE ubicacion_id = destino.id_ubicacion AND especie = especie_ingreso) THEN
            RAISE EXCEPTION USING ERRCODE = 'P1013', MESSAGE = 'El hogar no admite la especie del animal';
        END IF;
    END IF;

    IF destino.capacidad IS NOT NULL AND EXISTS (
        WITH ocupantes AS (
            SELECT e.fecha_inicio_real, e.fecha_fin_real, u.capacidad
            FROM estancia e JOIN ubicacion u ON u.id_ubicacion = e.ubicacion_id
            WHERE (u.id_ubicacion = destino.id_ubicacion OR u.codigo_hogar = destino.codigo_hogar)
              AND (e.fecha_fin_real IS NULL OR e.fecha_fin_real > p_fecha_real)
        ),
        puntos AS (
            SELECT p_fecha_real AS fecha, destino.capacidad AS capacidad
            UNION ALL
            SELECT fecha_inicio_real, capacidad FROM ocupantes WHERE fecha_inicio_real > p_fecha_real
        )
        SELECT FROM puntos p
        WHERE (SELECT count(*) FROM ocupantes o WHERE o.fecha_inicio_real <= p.fecha
               AND (o.fecha_fin_real IS NULL OR o.fecha_fin_real > p.fecha)) >= p.capacidad
    ) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1014', MESSAGE = 'La ubicación no tiene cupo en el intervalo real';
    END IF;

    INSERT INTO estancia (
        animal_codigo, ingreso_id, ubicacion_id, fecha_inicio_real, actor_entrada_id, condicion_alojamiento,
        fecha_inicio_prevista, fecha_fin_prevista, condicion_especial, aprobacion_hogar_id, valoracion_sanitaria
    ) VALUES (
        etapa.animal_codigo, etapa.id_ingreso, destino.id_ubicacion, p_fecha_real, p_actor_id, p_condicion_alojamiento,
        p_inicio_previsto, p_fin_previsto, p_condicion_especial, aprobacion_id, p_valoracion_sanitaria
    ) RETURNING id_estancia INTO nueva_id;
    RETURN nueva_id;
END
$$;

-- Primitiva privada. La futura formalización llama a esta función dentro de la
-- transacción que registra su resultado, su adopción y el cambio de reserva.
CREATE FUNCTION _cerrar_etapa_alojamiento(
    p_ingreso_id bigint, p_estancia_esperada bigint, p_fecha_real timestamptz, p_actor_id bigint
) RETURNS bigint
LANGUAGE plpgsql SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    etapa ingreso%ROWTYPE;
    anterior estancia%ROWTYPE;
BEGIN
    PERFORM _bloquear_alojamiento();
    SELECT * INTO etapa FROM ingreso WHERE id_ingreso = p_ingreso_id;
    IF NOT FOUND OR etapa.fecha_cierre IS NOT NULL THEN
        RAISE EXCEPTION USING ERRCODE = 'P1004', MESSAGE = 'Se requiere un ingreso existente y abierto';
    END IF;
    IF p_fecha_real IS NULL OR NOT isfinite(p_fecha_real) OR
       p_fecha_real <= etapa.fecha_ingreso OR p_fecha_real > clock_timestamp() THEN
        RAISE EXCEPTION USING ERRCODE = 'P1005', MESSAGE = 'El cierre debe suceder después del ingreso y hasta el presente';
    END IF;
    IF NOT EXISTS (SELECT FROM persona WHERE id_persona = p_actor_id) THEN
        RAISE EXCEPTION USING ERRCODE = 'P1015', MESSAGE = 'El cierre requiere una persona registrada';
    END IF;
    SELECT * INTO anterior FROM estancia WHERE ingreso_id = p_ingreso_id AND fecha_fin_real IS NULL;
    IF anterior.id_estancia IS DISTINCT FROM p_estancia_esperada THEN
        RAISE EXCEPTION USING ERRCODE = 'P1006', MESSAGE = 'La estancia vigente difiere de la esperada';
    END IF;
    IF anterior.id_estancia IS NOT NULL AND p_fecha_real <= anterior.fecha_inicio_real THEN
        RAISE EXCEPTION USING ERRCODE = 'P1005', MESSAGE = 'La salida debe suceder después de la entrada en esta etapa';
    END IF;
    UPDATE estancia SET fecha_fin_real = p_fecha_real, actor_salida_id = p_actor_id
    WHERE id_estancia = anterior.id_estancia;
    UPDATE ingreso SET fecha_cierre = p_fecha_real WHERE id_ingreso = p_ingreso_id;
    RETURN anterior.id_estancia;
END
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA huellas FROM PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA huellas TO huellas_g05_operador;
GRANT EXECUTE ON FUNCTION mover_animal(bigint, bigint, bigint, timestamptz, bigint, text,
    timestamptz, timestamptz, text, text) TO huellas_g05_operador;

COMMIT;
