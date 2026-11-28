
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path = huellas, pg_catalog;

-- ============================================================
-- HUELLAS SEGURAS - GRUPO 05
--  OPERACIONES Y VALIDACIONES
-- ============================================================

-- 1. SERIALIZACION DEL BLOQUE CLINICO

CREATE TRIGGER indicacion_serializar
BEFORE INSERT OR UPDATE OR DELETE ON indicacion
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();

CREATE TRIGGER indicacion_diagnostico_serializar
BEFORE INSERT OR UPDATE OR DELETE ON indicacion_diagnostico
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();

CREATE TRIGGER aplicacion_indicacion_serializar
BEFORE INSERT OR UPDATE OR DELETE ON aplicacion_indicacion
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();


-- 2. VALIDAR SUSTITUCION DE INDICACIONES

CREATE FUNCTION _validar_indicacion_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_animal_actual text;
    v_animal_anterior text;
    v_fecha_actual timestamptz;
    v_fecha_anterior timestamptz;
BEGIN
    IF NEW.indicacion_sustituida_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT animal_codigo, fecha_evaluacion
    INTO v_animal_actual, v_fecha_actual
    FROM evaluacion_salud
    WHERE id_evaluacion = NEW.evaluacion_id;

    SELECT e.animal_codigo, e.fecha_evaluacion
    INTO v_animal_anterior, v_fecha_anterior
    FROM indicacion i
    JOIN evaluacion_salud e
        ON e.id_evaluacion = i.evaluacion_id
    WHERE i.id_indicacion = NEW.indicacion_sustituida_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3001',
            MESSAGE = 'La indicacion sustituida no existe';
    END IF;

    IF v_animal_actual IS DISTINCT FROM v_animal_anterior THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3002',
            MESSAGE = 'No se puede sustituir una indicacion de otro animal';
    END IF;

    IF v_fecha_actual < v_fecha_anterior THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3003',
            MESSAGE = 'La sustitucion no puede ser anterior a la indicacion original';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER indicacion_validar
BEFORE INSERT ON indicacion
FOR EACH ROW
EXECUTE FUNCTION _validar_indicacion_jeank();


-- 3. PROTEGER EL HISTORIAL CLINICO

CREATE TRIGGER indicacion_historia
BEFORE UPDATE OR DELETE ON indicacion
FOR EACH ROW
EXECUTE FUNCTION _solo_insercion_paula();

CREATE TRIGGER indicacion_diagnostico_historia
BEFORE UPDATE OR DELETE ON indicacion_diagnostico
FOR EACH ROW
EXECUTE FUNCTION _solo_insercion_paula();


-- 4. VALIDAR APLICACIONES DE INDICACIONES

CREATE FUNCTION _validar_aplicacion_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_fecha_evaluacion timestamptz;
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3004',
            MESSAGE = 'No se permite eliminar el historial de aplicaciones';
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.fecha_real IS NOT NULL THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3005',
                MESSAGE = 'Una aplicacion realizada no puede modificarse';
        END IF;

        IF NEW.id_aplicacion IS DISTINCT FROM OLD.id_aplicacion
           OR NEW.indicacion_id IS DISTINCT FROM OLD.indicacion_id
           OR NEW.fecha_planificada IS DISTINCT FROM OLD.fecha_planificada
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3006',
                MESSAGE = 'No se puede alterar el contexto de la aplicacion';
        END IF;
    END IF;

    SELECT e.fecha_evaluacion
    INTO v_fecha_evaluacion
    FROM indicacion i
    JOIN evaluacion_salud e
        ON e.id_evaluacion = i.evaluacion_id
    WHERE i.id_indicacion = NEW.indicacion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3007',
            MESSAGE = 'La indicacion asociada no existe';
    END IF;

    IF NEW.fecha_planificada < v_fecha_evaluacion THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3008',
            MESSAGE = 'La fecha planificada es anterior a la evaluacion';
    END IF;

    IF NEW.fecha_real IS NOT NULL THEN

        IF NEW.fecha_real < v_fecha_evaluacion THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3009',
                MESSAGE = 'La aplicacion es anterior a la evaluacion';
        END IF;

        IF NEW.fecha_real > clock_timestamp() THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3010',
                MESSAGE = 'La fecha real no puede estar en el futuro';
        END IF;

        IF NEW.responsable_id IS NULL
           OR NULLIF(btrim(NEW.observaciones), '') IS NULL
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3011',
                MESSAGE = 'Debe registrar responsable y observaciones';
        END IF;

    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER aplicacion_validar
BEFORE INSERT OR UPDATE OR DELETE ON aplicacion_indicacion
FOR EACH ROW
EXECUTE FUNCTION _validar_aplicacion_jeank();


-- 5. FUNCION REUTILIZADA DE LAB03
-- CONSULTAR EL ESTADO DE UNA APLICACION

CREATE FUNCTION estado_aplicacion(
    p_id_aplicacion bigint
)
RETURNS text
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_fecha_planificada timestamptz;
    v_fecha_real timestamptz;
BEGIN
    SELECT fecha_planificada, fecha_real
    INTO v_fecha_planificada, v_fecha_real
    FROM aplicacion_indicacion
    WHERE id_aplicacion = p_id_aplicacion;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3012',
            MESSAGE = 'La aplicacion consultada no existe';
    END IF;

    IF v_fecha_real IS NOT NULL THEN
        RETURN 'REALIZADA';
    ELSIF v_fecha_planificada < clock_timestamp() THEN
        RETURN 'VENCIDA';
    ELSE
        RETURN 'PROGRAMADA';
    END IF;
END;
$$;


-- 6. PROCEDIMIENTO REUTILIZADO DE LAB03
-- REGISTRAR UNA APLICACION REALIZADA

CREATE PROCEDURE registrar_aplicacion(
    p_id_aplicacion bigint,
    p_fecha_real timestamptz,
    p_responsable_id bigint,
    p_observaciones text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_fecha_real timestamptz;
BEGIN
    PERFORM _bloquear_alojamiento();

    SELECT fecha_real
    INTO v_fecha_real
    FROM aplicacion_indicacion
    WHERE id_aplicacion = p_id_aplicacion
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3012',
            MESSAGE = 'La aplicacion no existe';
    END IF;

    IF v_fecha_real IS NOT NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3005',
            MESSAGE = 'La aplicacion ya fue realizada';
    END IF;

    IF p_fecha_real IS NULL
       OR p_responsable_id IS NULL
       OR NULLIF(btrim(p_observaciones), '') IS NULL
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3011',
            MESSAGE = 'Debe indicar fecha, responsable y observaciones';
    END IF;

    UPDATE aplicacion_indicacion
    SET fecha_real = p_fecha_real,
        responsable_id = p_responsable_id,
        observaciones = p_observaciones
    WHERE id_aplicacion = p_id_aplicacion;
END;
$$;

REVOKE ALL ON PROCEDURE registrar_aplicacion(
    bigint, timestamptz, bigint, text
) FROM PUBLIC;

GRANT EXECUTE ON PROCEDURE registrar_aplicacion(
    bigint, timestamptz, bigint, text
) TO huellas_g05_operador;


-- FIN DEL BLOQUE CLINICO


-- ============================================================
-- G05-P03: RESERVA EXCLUSIVA DE ANIMALES
-- ============================================================

-- 7. SERIALIZACION DE OPERACIONES

CREATE TRIGGER reserva_serializar
BEFORE INSERT OR UPDATE OR DELETE ON reserva
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();

CREATE TRIGGER adopcion_serializar
BEFORE INSERT OR UPDATE OR DELETE ON adopcion
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();

CREATE TRIGGER restriccion_serializar
BEFORE INSERT OR UPDATE OR DELETE ON restriccion_persona
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();

CREATE TRIGGER resultado_etapa_serializar
BEFORE INSERT OR UPDATE OR DELETE ON resultado_etapa
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();


-- 8. VALIDAR DISPONIBILIDAD DEL ANIMAL

CREATE FUNCTION _exigir_disponibilidad_jeank(
    p_animal text,
    p_ingreso bigint,
    p_fecha timestamptz
)
RETURNS void
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    PERFORM _bloquear_alojamiento();

    IF NOT EXISTS (
        SELECT 1
        FROM disponibilidad_actual
        WHERE animal_codigo = p_animal
          AND ingreso_id = p_ingreso
          AND estado_disponibilidad = 'HABILITADO'
          AND fecha <= p_fecha
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3013',
            MESSAGE = 'El animal no tiene disponibilidad habilitada para esta etapa';
    END IF;
END;
$$;


-- 9. VALIDAR RESTRICCIONES VIGENTES

CREATE FUNCTION _exigir_persona_sin_restriccion(
    p_persona bigint,
    p_fecha timestamptz
)
RETURNS void
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    PERFORM _bloquear_alojamiento();

    IF NOT EXISTS (
        SELECT 1
        FROM persona
        WHERE id_persona = p_persona
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3014',
            MESSAGE = 'La persona indicada no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM restriccion_persona
        WHERE persona_afectada_id = p_persona
          AND fecha_inicio <= p_fecha
          AND (
              fecha_fin IS NULL
              OR fecha_fin > p_fecha
          )
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3015',
            MESSAGE = 'La persona tiene una restriccion vigente documentada';
    END IF;
END;
$$;


-- 10. VALIDAR EL CONTEXTO DE UNA RESERVA

CREATE FUNCTION _validar_reserva_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_compatibilidad bigint;
    v_solicitante bigint;
BEGIN
    PERFORM _bloquear_alojamiento();

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3016',
            MESSAGE = 'No se permite eliminar el historial de reservas';
    END IF;

    IF TG_OP = 'UPDATE' THEN

        IF OLD.fecha_fin_reserva IS NOT NULL THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3017',
                MESSAGE = 'Una reserva finalizada no puede modificarse';
        END IF;

        IF (
            NEW.id_reserva,
            NEW.clave_operacion,
            NEW.solicitud_id,
            NEW.animal_codigo,
            NEW.ingreso_id,
            NEW.compatibilidad_id,
            NEW.fecha_reserva,
            NEW.responsable_id
        ) IS DISTINCT FROM (
            OLD.id_reserva,
            OLD.clave_operacion,
            OLD.solicitud_id,
            OLD.animal_codigo,
            OLD.ingreso_id,
            OLD.compatibilidad_id,
            OLD.fecha_reserva,
            OLD.responsable_id
        ) THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3018',
                MESSAGE = 'No se permite modificar el contexto historico de una reserva';
        END IF;

        IF NEW.fecha_fin_reserva IS NULL
           OR NEW.fecha_fin_reserva > clock_timestamp()
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3019',
                MESSAGE = 'La fecha de finalizacion de la reserva no es valida';
        END IF;

        RETURN NEW;
    END IF;

    IF NEW.fecha_fin_reserva IS NOT NULL
       OR NEW.fecha_reserva IS NULL
       OR NEW.fecha_reserva > clock_timestamp()
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3019',
            MESSAGE = 'La reserva debe iniciar vigente y con una fecha valida';
    END IF;

    PERFORM _personal_paula(
        NEW.responsable_id,
        NEW.fecha_reserva
    );

    v_compatibilidad := _exigir_compatibilidad(
        NEW.solicitud_id,
        NEW.animal_codigo,
        NEW.ingreso_id,
        NEW.fecha_reserva
    );

    IF NEW.compatibilidad_id IS DISTINCT FROM v_compatibilidad THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3020',
            MESSAGE = 'La compatibilidad indicada no corresponde a la valoracion vigente';
    END IF;

    PERFORM _exigir_disponibilidad_jeank(
        NEW.animal_codigo,
        NEW.ingreso_id,
        NEW.fecha_reserva
    );

    SELECT solicitante_id
    INTO v_solicitante
    FROM solicitud_adopcion
    WHERE id_solicitud = NEW.solicitud_id;

    PERFORM _exigir_persona_sin_restriccion(
        v_solicitante,
        NEW.fecha_reserva
    );

    IF EXISTS (
        SELECT 1
        FROM reserva
        WHERE animal_codigo = NEW.animal_codigo
          AND fecha_fin_reserva IS NULL
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3021',
            MESSAGE = 'El animal ya tiene una reserva vigente';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM adopcion
        WHERE ingreso_id = NEW.ingreso_id
    ) OR EXISTS (
        SELECT 1
        FROM resultado_etapa
        WHERE ingreso_id = NEW.ingreso_id
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3022',
            MESSAGE = 'La etapa del animal ya tiene un resultado registrado';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER reserva_validar
BEFORE INSERT OR UPDATE OR DELETE ON reserva
FOR EACH ROW
EXECUTE FUNCTION _validar_reserva_jeank();


-- 11. OPERACION PUBLICA: REGISTRAR RESERVA

CREATE FUNCTION registrar_reserva(
    p_clave_operacion uuid,
    p_solicitud_id bigint,
    p_animal_codigo text,
    p_ingreso_id bigint,
    p_fecha_reserva timestamptz,
    p_responsable_id bigint
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_id_reserva bigint;
    v_compatibilidad_id bigint;
BEGIN
    PERFORM _bloquear_alojamiento();

    IF p_clave_operacion IS NULL
       OR p_solicitud_id IS NULL
       OR p_animal_codigo IS NULL
       OR p_ingreso_id IS NULL
       OR p_fecha_reserva IS NULL
       OR p_responsable_id IS NULL
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3023',
            MESSAGE = 'Debe proporcionar todos los datos obligatorios de la reserva';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reserva
        WHERE clave_operacion = p_clave_operacion
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3024',
            MESSAGE = 'La clave de operacion ya fue utilizada';
    END IF;

    v_compatibilidad_id := _exigir_compatibilidad(
        p_solicitud_id,
        p_animal_codigo,
        p_ingreso_id,
        p_fecha_reserva
    );

    INSERT INTO reserva (
        clave_operacion,
        solicitud_id,
        animal_codigo,
        ingreso_id,
        compatibilidad_id,
        fecha_reserva,
        responsable_id
    )
    VALUES (
        p_clave_operacion,
        p_solicitud_id,
        p_animal_codigo,
        p_ingreso_id,
        v_compatibilidad_id,
        p_fecha_reserva,
        p_responsable_id
    )
    RETURNING id_reserva INTO v_id_reserva;

    RETURN v_id_reserva;
END;
$$;


-- 12. OPERACION PUBLICA: FINALIZAR RESERVA

CREATE FUNCTION finalizar_reserva(
    p_reserva_id bigint,
    p_fecha_fin timestamptz,
    p_responsable_id bigint
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_reserva reserva%ROWTYPE;
BEGIN
    PERFORM _bloquear_alojamiento();

    IF p_fecha_fin IS NULL
       OR p_fecha_fin > clock_timestamp()
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3019',
            MESSAGE = 'La fecha de finalizacion no es valida';
    END IF;

    PERFORM _personal_paula(
        p_responsable_id,
        p_fecha_fin
    );

    SELECT *
    INTO v_reserva
    FROM reserva
    WHERE id_reserva = p_reserva_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3025',
            MESSAGE = 'La reserva indicada no existe';
    END IF;

    IF v_reserva.fecha_fin_reserva IS NOT NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3017',
            MESSAGE = 'La reserva ya fue finalizada';
    END IF;

    IF p_fecha_fin < v_reserva.fecha_reserva THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3019',
            MESSAGE = 'La finalizacion es anterior al inicio de la reserva';
    END IF;

    UPDATE reserva
    SET fecha_fin_reserva = p_fecha_fin
    WHERE id_reserva = p_reserva_id;

    RETURN p_reserva_id;
END;
$$;


-- 13. CONTROL DE PRIVILEGIOS

REVOKE ALL ON FUNCTION
    _exigir_disponibilidad_jeank(
        text, bigint, timestamptz
    ),
    _exigir_persona_sin_restriccion(
        bigint, timestamptz
    ),
    _validar_reserva_jeank()
FROM PUBLIC;

REVOKE ALL ON FUNCTION registrar_reserva(
    uuid, bigint, text, bigint, timestamptz, bigint
) FROM PUBLIC;

REVOKE ALL ON FUNCTION finalizar_reserva(
    bigint, timestamptz, bigint
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION registrar_reserva(
    uuid, bigint, text, bigint, timestamptz, bigint
) TO huellas_g05_operador;

GRANT EXECUTE ON FUNCTION finalizar_reserva(
    bigint, timestamptz, bigint
) TO huellas_g05_operador;

GRANT SELECT ON reserva TO huellas_g05_operador;


-- FIN DEL BLOQUE DE RESERVAS


-- ============================================================
-- G05-P03: FORMALIZACION DE ADOPCIONES
-- ============================================================

-- 14. VALIDAR EL CONTEXTO DE LA ADOPCION

CREATE FUNCTION _validar_adopcion_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_reserva reserva%ROWTYPE;
    v_compatibilidad bigint;
    v_solicitante bigint;
BEGIN
    PERFORM _bloquear_alojamiento();

    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3026',
            MESSAGE = 'No se permite alterar directamente el historial de adopcion';
    END IF;

    SELECT *
    INTO v_reserva
    FROM reserva
    WHERE id_reserva = NEW.reserva_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3025',
            MESSAGE = 'La reserva indicada no existe';
    END IF;

    IF v_reserva.fecha_fin_reserva IS NOT NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3017',
            MESSAGE = 'La reserva ya fue finalizada';
    END IF;

    IF (
        NEW.solicitud_id,
        NEW.animal_codigo,
        NEW.ingreso_id
    ) IS DISTINCT FROM (
        v_reserva.solicitud_id,
        v_reserva.animal_codigo,
        v_reserva.ingreso_id
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3027',
            MESSAGE = 'La adopcion no corresponde al contexto de la reserva';
    END IF;

    IF NEW.fecha_entrega IS NULL
       OR NEW.fecha_entrega < v_reserva.fecha_reserva
       OR NEW.fecha_entrega > clock_timestamp()
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3028',
            MESSAGE = 'La fecha de entrega no es valida';
    END IF;

    PERFORM _personal_paula(
        NEW.responsable_entrega_id,
        NEW.fecha_entrega
    );

    v_compatibilidad := _exigir_compatibilidad(
        NEW.solicitud_id,
        NEW.animal_codigo,
        NEW.ingreso_id,
        NEW.fecha_entrega
    );

    IF NEW.compatibilidad_id IS DISTINCT FROM v_compatibilidad THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3020',
            MESSAGE = 'La compatibilidad indicada no es la vigente';
    END IF;

    PERFORM _exigir_disponibilidad_jeank(
        NEW.animal_codigo,
        NEW.ingreso_id,
        NEW.fecha_entrega
    );

    SELECT solicitante_id
    INTO v_solicitante
    FROM solicitud_adopcion
    WHERE id_solicitud = NEW.solicitud_id;

    PERFORM _exigir_persona_sin_restriccion(
        v_solicitante,
        NEW.fecha_entrega
    );

    IF EXISTS (
        SELECT 1
        FROM resultado_etapa
        WHERE ingreso_id = NEW.ingreso_id
    ) OR EXISTS (
        SELECT 1
        FROM adopcion
        WHERE ingreso_id = NEW.ingreso_id
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3022',
            MESSAGE = 'El ingreso ya tiene un resultado registrado';
    END IF;

    IF NEW.tipo_finalizacion IS NOT NULL
       OR NEW.fecha_finalizacion IS NOT NULL
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3029',
            MESSAGE = 'Una nueva adopcion no puede iniciar finalizada';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER adopcion_validar
BEFORE INSERT OR UPDATE OR DELETE ON adopcion
FOR EACH ROW
EXECUTE FUNCTION _validar_adopcion_jeank();


-- 15. OPERACION PUBLICA: FORMALIZAR ADOPCION

CREATE FUNCTION formalizar_adopcion(
    p_clave_operacion uuid,
    p_reserva_id bigint,
    p_estancia_esperada bigint,
    p_fecha_entrega timestamptz,
    p_condiciones_aceptadas text,
    p_responsable_entrega bigint,
    p_responsables bigint[]
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_reserva reserva%ROWTYPE;
    v_id_adopcion bigint;
    v_compatibilidad bigint;
    v_persona bigint;
    v_solicitante bigint;
BEGIN
    PERFORM _bloquear_alojamiento();

    IF current_setting('transaction_isolation')
        <> 'read committed'
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3030',
            MESSAGE = 'La formalizacion requiere READ COMMITTED';
    END IF;

    IF p_clave_operacion IS NULL
       OR p_reserva_id IS NULL
       OR p_fecha_entrega IS NULL
       OR p_responsable_entrega IS NULL
       OR NULLIF(btrim(p_condiciones_aceptadas), '') IS NULL
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3031',
            MESSAGE = 'Faltan datos obligatorios de la adopcion';
    END IF;

    IF COALESCE(cardinality(p_responsables), 0) = 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3032',
            MESSAGE = 'La adopcion requiere al menos un responsable';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM adopcion
        WHERE clave_operacion = p_clave_operacion
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3024',
            MESSAGE = 'La clave de operacion ya fue utilizada';
    END IF;

    SELECT *
    INTO v_reserva
    FROM reserva
    WHERE id_reserva = p_reserva_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3025',
            MESSAGE = 'La reserva no existe';
    END IF;

    IF v_reserva.fecha_fin_reserva IS NOT NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3017',
            MESSAGE = 'La reserva ya fue finalizada';
    END IF;

    v_compatibilidad := _exigir_compatibilidad(
        v_reserva.solicitud_id,
        v_reserva.animal_codigo,
        v_reserva.ingreso_id,
        p_fecha_entrega
    );

    SELECT solicitante_id
    INTO v_solicitante
    FROM solicitud_adopcion
    WHERE id_solicitud = v_reserva.solicitud_id;

    IF NOT COALESCE(
        v_solicitante = ANY(p_responsables),
        false
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3033',
            MESSAGE = 'El solicitante debe figurar entre los responsables';
    END IF;

    FOREACH v_persona IN ARRAY p_responsables
    LOOP
        PERFORM _exigir_persona_sin_restriccion(
            v_persona,
            p_fecha_entrega
        );
    END LOOP;

    -- Registrar la adopcion.

    INSERT INTO adopcion (
        clave_operacion,
        reserva_id,
        solicitud_id,
        animal_codigo,
        ingreso_id,
        compatibilidad_id,
        fecha_entrega,
        condiciones_aceptadas,
        responsable_entrega_id
    )
    VALUES (
        p_clave_operacion,
        v_reserva.id_reserva,
        v_reserva.solicitud_id,
        v_reserva.animal_codigo,
        v_reserva.ingreso_id,
        v_compatibilidad,
        p_fecha_entrega,
        p_condiciones_aceptadas,
        p_responsable_entrega
    )
    RETURNING id_adopcion INTO v_id_adopcion;

    -- Registrar responsables del animal adoptado.

    FOREACH v_persona IN ARRAY p_responsables
    LOOP
        INSERT INTO adopcion_responsable (
            adopcion_id,
            persona_id
        )
        VALUES (
            v_id_adopcion,
            v_persona
        );
    END LOOP;

    -- Finalizar la reserva.

    UPDATE reserva
    SET fecha_fin_reserva = p_fecha_entrega
    WHERE id_reserva = p_reserva_id;

    -- Integracion con G05-P01: cerrar estancia e ingreso.

    PERFORM _cerrar_etapa_alojamiento(
        v_reserva.ingreso_id,
        p_estancia_esperada,
        p_fecha_entrega,
        p_responsable_entrega
    );

    RETURN v_id_adopcion;
END;
$$;


-- 16. CONTROL DE PRIVILEGIOS

REVOKE ALL ON FUNCTION
    _validar_adopcion_jeank()
FROM PUBLIC;

REVOKE ALL ON FUNCTION formalizar_adopcion(
    uuid,
    bigint,
    bigint,
    timestamptz,
    text,
    bigint,
    bigint[]
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION formalizar_adopcion(
    uuid,
    bigint,
    bigint,
    timestamptz,
    text,
    bigint,
    bigint[]
) TO huellas_g05_operador;

GRANT SELECT ON adopcion,
    adopcion_responsable
TO huellas_g05_operador;


-- FIN DEL BLOQUE DE FORMALIZACION


-- ============================================================
-- INTEGRIDAD DE RESULTADOS DE ETAPA
-- ============================================================

-- 17. VALIDAR RESULTADOS DE ETAPA

CREATE FUNCTION _validar_resultado_etapa_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    PERFORM _bloquear_alojamiento();

    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3034',
            MESSAGE = 'No se permite modificar el historial de resultados';
    END IF;

    IF NEW.fecha IS NULL
       OR NEW.fecha > clock_timestamp()
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3035',
            MESSAGE = 'La fecha del resultado no es valida';
    END IF;

    PERFORM _personal_paula(
        NEW.responsable_id,
        NEW.fecha
    );

    IF EXISTS (
        SELECT 1
        FROM adopcion
        WHERE ingreso_id = NEW.ingreso_id
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3022',
            MESSAGE = 'El ingreso ya fue cerrado mediante una adopcion';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reserva
        WHERE ingreso_id = NEW.ingreso_id
          AND fecha_fin_reserva IS NULL
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3036',
            MESSAGE = 'El ingreso tiene una reserva vigente';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER resultado_etapa_validar
BEFORE INSERT OR UPDATE OR DELETE ON resultado_etapa
FOR EACH ROW
EXECUTE FUNCTION _validar_resultado_etapa_jeank();


-- 18. VALIDAR RESTRICCIONES DE PERSONAS

CREATE FUNCTION _validar_restriccion_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    PERFORM _bloquear_alojamiento();

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3037',
            MESSAGE = 'No se permite eliminar restricciones historicas';
    END IF;

    IF TG_OP = 'UPDATE' THEN

        IF OLD.fecha_fin IS NOT NULL THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3038',
                MESSAGE = 'La restriccion ya fue finalizada';
        END IF;

        IF (
            NEW.id_restriccion,
            NEW.persona_afectada_id,
            NEW.motivo,
            NEW.fecha_inicio,
            NEW.responsable_decision_id
        ) IS DISTINCT FROM (
            OLD.id_restriccion,
            OLD.persona_afectada_id,
            OLD.motivo,
            OLD.fecha_inicio,
            OLD.responsable_decision_id
        ) THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3039',
                MESSAGE = 'No se permite alterar la decision original';
        END IF;

        IF NEW.fecha_fin IS NULL THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3040',
                MESSAGE = 'Debe indicar la fecha de finalizacion';
        END IF;

    END IF;

    PERFORM _personal_paula(
        NEW.responsable_decision_id,
        NEW.fecha_inicio
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER restriccion_validar
BEFORE INSERT OR UPDATE OR DELETE ON restriccion_persona
FOR EACH ROW
EXECUTE FUNCTION _validar_restriccion_jeank();


-- ============================================================
-- SEGUIMIENTO DE ADOPCIONES
-- ============================================================

-- 19. SERIALIZACION DE SEGUIMIENTOS

CREATE TRIGGER seguimiento_serializar
BEFORE INSERT OR UPDATE OR DELETE ON seguimiento_adopcion
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();


-- 20. VALIDAR SEGUIMIENTOS Y REPROGRAMACIONES

CREATE FUNCTION _validar_seguimiento_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_fecha_entrega timestamptz;
    v_origen seguimiento_adopcion%ROWTYPE;
BEGIN
    PERFORM _bloquear_alojamiento();

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3041',
            MESSAGE = 'No se permite eliminar seguimientos historicos';
    END IF;

    IF TG_OP = 'UPDATE' THEN

        IF OLD.estado_seguimiento <> 'PENDIENTE' THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3042',
                MESSAGE = 'El seguimiento ya tiene un resultado definitivo';
        END IF;

        IF (
            NEW.id_seguimiento,
            NEW.adopcion_id,
            NEW.fecha_prevista,
            NEW.seguimiento_origen_id
        ) IS DISTINCT FROM (
            OLD.id_seguimiento,
            OLD.adopcion_id,
            OLD.fecha_prevista,
            OLD.seguimiento_origen_id
        ) THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3043',
                MESSAGE = 'No se permite alterar el contexto del seguimiento';
        END IF;

    END IF;

    SELECT fecha_entrega
    INTO v_fecha_entrega
    FROM adopcion
    WHERE id_adopcion = NEW.adopcion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3044',
            MESSAGE = 'La adopcion asociada no existe';
    END IF;

    IF NEW.fecha_prevista < v_fecha_entrega THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3045',
            MESSAGE = 'El seguimiento no puede ser anterior a la adopcion';
    END IF;

    IF NEW.fecha_efectiva IS NOT NULL THEN

        IF NEW.fecha_efectiva < v_fecha_entrega
           OR NEW.fecha_efectiva > clock_timestamp()
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3046',
                MESSAGE = 'La fecha efectiva del seguimiento no es valida';
        END IF;

    END IF;

    IF NEW.seguimiento_origen_id IS NOT NULL THEN

        SELECT *
        INTO v_origen
        FROM seguimiento_adopcion
        WHERE id_seguimiento = NEW.seguimiento_origen_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3047',
                MESSAGE = 'El seguimiento de origen no existe';
        END IF;

        IF v_origen.adopcion_id <> NEW.adopcion_id THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3048',
                MESSAGE = 'La reprogramacion pertenece a otra adopcion';
        END IF;

        IF v_origen.estado_seguimiento <> 'REPROGRAMADO' THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3049',
                MESSAGE = 'El seguimiento original debe estar reprogramado';
        END IF;

        IF NEW.fecha_prevista <= v_origen.fecha_prevista THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P3050',
                MESSAGE = 'La nueva fecha debe ser posterior a la original';
        END IF;

    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER seguimiento_validar
BEFORE INSERT OR UPDATE OR DELETE ON seguimiento_adopcion
FOR EACH ROW
EXECUTE FUNCTION _validar_seguimiento_jeank();

CREATE UNIQUE INDEX seguimiento_reprogramacion_uq
ON seguimiento_adopcion(seguimiento_origen_id)
WHERE seguimiento_origen_id IS NOT NULL;


-- 21. CONTROL DE PRIVILEGIOS

REVOKE ALL ON FUNCTION
    _validar_resultado_etapa_jeank(),
    _validar_restriccion_jeank(),
    _validar_seguimiento_jeank()
FROM PUBLIC;

GRANT SELECT ON
    indicacion,
    indicacion_diagnostico,
    aplicacion_indicacion,
    seguimiento_adopcion,
    restriccion_persona,
    resultado_etapa
TO huellas_g05_operador;


-- FIN DEL BLOQUE DE INTEGRIDAD HISTORICA


-- ============================================================
-- INTEGRACION DE REINGRESOS
-- ============================================================

-- 22. VALIDAR EL ORIGEN DE UN REINGRESO

CREATE FUNCTION _validar_reingreso_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_adopcion adopcion%ROWTYPE;
BEGIN
    IF NEW.adopcion_origen_id IS NULL THEN
        RETURN NEW;
    END IF;

    PERFORM _bloquear_alojamiento();

    SELECT *
    INTO v_adopcion
    FROM adopcion
    WHERE id_adopcion = NEW.adopcion_origen_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3051',
            MESSAGE = 'La adopcion de origen no existe';
    END IF;

    IF NEW.animal_codigo IS DISTINCT FROM
       v_adopcion.animal_codigo
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3052',
            MESSAGE = 'El reingreso corresponde a otro animal';
    END IF;

    IF v_adopcion.fecha_finalizacion IS NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3053',
            MESSAGE = 'La adopcion de origen no ha finalizado';
    END IF;

    IF NEW.fecha_ingreso < v_adopcion.fecha_finalizacion
       OR NEW.fecha_ingreso <= v_adopcion.fecha_entrega
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3054',
            MESSAGE = 'La fecha del reingreso no es valida';
    END IF;

    IF NEW.circunstancia_ingreso = 'DEVOLUCION'
       AND v_adopcion.tipo_finalizacion
           IS DISTINCT FROM 'DEVOLUCION_VOLUNTARIA'
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3055',
            MESSAGE = 'La devolucion no coincide con el cierre de la adopcion';
    END IF;

    IF NEW.circunstancia_ingreso = 'RECUPERACION'
       AND v_adopcion.tipo_finalizacion
           IS DISTINCT FROM 'RECUPERACION_POR_INCUMPLIMIENTO'
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3056',
            MESSAGE = 'La recuperacion no coincide con el cierre de la adopcion';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER ingreso_reingreso_jeank
BEFORE INSERT OR UPDATE ON ingreso
FOR EACH ROW
EXECUTE FUNCTION _validar_reingreso_jeank();


-- 23. PERMITIR LA FINALIZACION CONTROLADA DE ADOPCIONES

CREATE FUNCTION _validar_finalizacion_adopcion_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    PERFORM _bloquear_alojamiento();

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3057',
            MESSAGE = 'No se permite eliminar adopciones historicas';
    END IF;

    IF OLD.fecha_finalizacion IS NOT NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3058',
            MESSAGE = 'La adopcion ya fue finalizada';
    END IF;

    IF (
        NEW.id_adopcion,
        NEW.clave_operacion,
        NEW.reserva_id,
        NEW.solicitud_id,
        NEW.animal_codigo,
        NEW.ingreso_id,
        NEW.compatibilidad_id,
        NEW.fecha_entrega,
        NEW.condiciones_aceptadas,
        NEW.responsable_entrega_id
    ) IS DISTINCT FROM (
        OLD.id_adopcion,
        OLD.clave_operacion,
        OLD.reserva_id,
        OLD.solicitud_id,
        OLD.animal_codigo,
        OLD.ingreso_id,
        OLD.compatibilidad_id,
        OLD.fecha_entrega,
        OLD.condiciones_aceptadas,
        OLD.responsable_entrega_id
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3059',
            MESSAGE = 'No se puede alterar el contexto original de la adopcion';
    END IF;

    IF NEW.tipo_finalizacion IS NULL
       OR NEW.fecha_finalizacion IS NULL
       OR NEW.fecha_finalizacion < OLD.fecha_entrega
       OR NEW.fecha_finalizacion > clock_timestamp()
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3060',
            MESSAGE = 'Los datos de finalizacion no son validos';
    END IF;

    RETURN NEW;
END;
$$;


-- Separar la validacion de insercion y finalizacion.

DROP TRIGGER adopcion_validar ON adopcion;

CREATE TRIGGER adopcion_validar
BEFORE INSERT ON adopcion
FOR EACH ROW
EXECUTE FUNCTION _validar_adopcion_jeank();

CREATE TRIGGER adopcion_finalizacion_validar
BEFORE UPDATE OR DELETE ON adopcion
FOR EACH ROW
EXECUTE FUNCTION _validar_finalizacion_adopcion_jeank();


-- 24. ACTIVAR LA REFERENCIA DE REINGRESO

ALTER TABLE ingreso
ADD CONSTRAINT ingreso_adopcion_origen_fk
FOREIGN KEY (adopcion_origen_id, animal_codigo)
REFERENCES adopcion (id_adopcion, animal_codigo);

ALTER TABLE ingreso
DROP CONSTRAINT zz_ingreso_adopcion_pendiente;


-- 25. CONTROL DE PRIVILEGIOS

REVOKE ALL ON FUNCTION
    _validar_reingreso_jeank(),
    _validar_finalizacion_adopcion_jeank()
FROM PUBLIC;


-- FIN DEL BLOQUE DE REINGRESOS


-- ============================================================
-- CONTROLES DIFERIDOS DE INTEGRIDAD
-- ============================================================

-- 26. COMPROBAR LA CONSISTENCIA DE UNA ADOPCION

CREATE FUNCTION _comprobar_adopcion_jeank(
    p_adopcion_id bigint
)
RETURNS void
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_adopcion adopcion%ROWTYPE;
    v_fecha_cierre timestamptz;
    v_fecha_fin_reserva timestamptz;
BEGIN
    PERFORM _bloquear_alojamiento();

    SELECT *
    INTO v_adopcion
    FROM adopcion
    WHERE id_adopcion = p_adopcion_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- La adopcion debe tener al menos un responsable.

    IF NOT EXISTS (
        SELECT 1
        FROM adopcion_responsable
        WHERE adopcion_id = p_adopcion_id
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3061',
            MESSAGE = 'La adopcion debe tener al menos un responsable';
    END IF;

    -- La reserva debe finalizar en la fecha de entrega.

    SELECT fecha_fin_reserva
    INTO v_fecha_fin_reserva
    FROM reserva
    WHERE id_reserva = v_adopcion.reserva_id;

    IF v_fecha_fin_reserva IS DISTINCT FROM
       v_adopcion.fecha_entrega
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3062',
            MESSAGE = 'La reserva no fue finalizada correctamente';
    END IF;

    -- El ingreso debe cerrar en la fecha de entrega.

    SELECT fecha_cierre
    INTO v_fecha_cierre
    FROM ingreso
    WHERE id_ingreso = v_adopcion.ingreso_id;

    IF v_fecha_cierre IS DISTINCT FROM
       v_adopcion.fecha_entrega
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3063',
            MESSAGE = 'El ingreso no fue cerrado correctamente';
    END IF;

    -- No puede existir otro resultado para el ingreso.

    IF EXISTS (
        SELECT 1
        FROM resultado_etapa
        WHERE ingreso_id = v_adopcion.ingreso_id
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3022',
            MESSAGE = 'El ingreso tiene resultados incompatibles';
    END IF;
END;
$$;


-- 27. TRIGGER DIFERIDO DE ADOPCIONES

CREATE FUNCTION _adopcion_diferida_jeank()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, huellas, pg_temp
AS $$
BEGIN
    PERFORM _comprobar_adopcion_jeank(
        NEW.id_adopcion
    );

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER adopcion_integridad_final
AFTER INSERT OR UPDATE ON adopcion
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION _adopcion_diferida_jeank();


-- 28. PROTEGER RESPONSABLES DE ADOPCION

CREATE TRIGGER adopcion_responsable_serializar
BEFORE INSERT OR UPDATE OR DELETE ON adopcion_responsable
FOR EACH STATEMENT
EXECUTE FUNCTION _serializar_catalogo();

CREATE FUNCTION _validar_responsable_adopcion_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_fecha_entrega timestamptz;
BEGIN
    PERFORM _bloquear_alojamiento();

    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3064',
            MESSAGE = 'No se permite alterar los responsables historicos';
    END IF;

    SELECT fecha_entrega
    INTO v_fecha_entrega
    FROM adopcion
    WHERE id_adopcion = NEW.adopcion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3044',
            MESSAGE = 'La adopcion asociada no existe';
    END IF;

    PERFORM _exigir_persona_sin_restriccion(
        NEW.persona_id,
        v_fecha_entrega
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER adopcion_responsable_validar
BEFORE INSERT OR UPDATE OR DELETE ON adopcion_responsable
FOR EACH ROW
EXECUTE FUNCTION _validar_responsable_adopcion_jeank();


-- 29. VALIDAR EL CIERRE DE OTROS RESULTADOS

CREATE FUNCTION _resultado_diferido_jeank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, huellas, pg_temp
AS $$
DECLARE
    v_fecha_cierre timestamptz;
BEGIN
    SELECT fecha_cierre
    INTO v_fecha_cierre
    FROM ingreso
    WHERE id_ingreso = NEW.ingreso_id;

    IF v_fecha_cierre IS DISTINCT FROM NEW.fecha THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P3065',
            MESSAGE = 'El resultado requiere el cierre correspondiente del ingreso';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER resultado_integridad_final
AFTER INSERT ON resultado_etapa
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION _resultado_diferido_jeank();


-- 30. CONTROL FINAL DE PRIVILEGIOS

REVOKE ALL ON FUNCTION
    _comprobar_adopcion_jeank(bigint),
    _adopcion_diferida_jeank(),
    _validar_responsable_adopcion_jeank(),
    _resultado_diferido_jeank(),
    _validar_indicacion_jeank(),
    _validar_aplicacion_jeank()
FROM PUBLIC;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON
    indicacion,
    indicacion_diagnostico,
    aplicacion_indicacion,
    reserva,
    adopcion,
    adopcion_responsable,
    seguimiento_adopcion,
    restriccion_persona,
    resultado_etapa
FROM PUBLIC, huellas_g05_operador;


-- ============================================================
-- FIN DE LAS OPERACIONES DEL BLOQUE 
-- ============================================================

COMMIT;
