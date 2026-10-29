-- Ejecutar tras esquema y datos, en una base limpia; no es una migracion.
BEGIN;
-- Decision de negocio: facultad para UNA organizacion y UN instante.
CREATE FUNCTION public.fn_persona_tiene_facultad(
    p_id_cliente bigint, p_id_persona bigint, p_id_facultad bigint,
    p_fecha timestamp with time zone
) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE v_tipo text;
BEGIN
    IF p_id_cliente IS NULL OR p_id_persona IS NULL OR p_id_facultad IS NULL OR p_fecha IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='22004', MESSAGE='Cliente, persona, facultad y fecha son obligatorios';
    END IF;
    SELECT tipo_cliente INTO v_tipo FROM public.cliente WHERE id_cliente=p_id_cliente;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='23503', MESSAGE='Cliente inexistente';
    END IF;
    IF v_tipo <> 'Organización' THEN
        RAISE EXCEPTION USING ERRCODE='23514', MESSAGE='Solo organizaciones conceden autorizaciones';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.persona WHERE id_persona=p_id_persona) THEN
        RAISE EXCEPTION USING ERRCODE='23503', MESSAGE='Persona inexistente';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.facultad WHERE id_facultad=p_id_facultad) THEN
        RAISE EXCEPTION USING ERRCODE='23503', MESSAGE='Facultad inexistente';
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.autorizacion a
        JOIN public.autorizacion_facultad af USING (id_autorizacion)
        WHERE a.id_cliente=p_id_cliente AND a.id_persona=p_id_persona
          AND af.id_facultad=p_id_facultad AND a.inicio_vigencia<=p_fecha
          AND (a.fin_vigencia IS NULL OR p_fecha<a.fin_vigencia)
    );
END;
$$;
-- Calcula numero de otorgamientos vigentes, NO numero de personas distintas.
CREATE FUNCTION public.fn_contar_autorizaciones_activas(
    p_id_cliente bigint, p_fecha timestamp with time zone
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_total bigint;
BEGIN
    IF p_id_cliente IS NULL OR p_fecha IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='22004', MESSAGE='Cliente y fecha son obligatorios';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.cliente WHERE id_cliente=p_id_cliente) THEN
        RAISE EXCEPTION USING ERRCODE='23503', MESSAGE='Cliente inexistente';
    END IF;
    SELECT count(*) INTO v_total FROM public.autorizacion a
    WHERE a.id_cliente=p_id_cliente AND a.inicio_vigencia<=p_fecha
      AND (a.fin_vigencia IS NULL OR p_fecha<a.fin_vigencia);
    RETURN v_total;
END;
$$;
-- ID explicito; valida antes de insertar. Sin COMMIT interno ni excepciones silenciadas.
CREATE PROCEDURE public.sp_registrar_autorizacion(
    p_id_autorizacion bigint, p_id_cliente bigint, p_id_persona bigint,
    p_inicio timestamp with time zone, p_fin timestamp with time zone,
    p_facultades bigint[]
) LANGUAGE plpgsql AS $$
DECLARE v_tipo text;
BEGIN
    IF p_id_autorizacion IS NULL OR p_id_cliente IS NULL OR p_id_persona IS NULL OR p_inicio IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='22004', MESSAGE='ID, cliente, persona e inicio son obligatorios';
    END IF;
    SELECT tipo_cliente INTO v_tipo FROM public.cliente WHERE id_cliente=p_id_cliente FOR SHARE;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='23503', MESSAGE='Cliente inexistente';
    END IF;
    IF v_tipo <> 'Organización' THEN
        RAISE EXCEPTION USING ERRCODE='23514', MESSAGE='Solo organizaciones conceden autorizaciones';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.persona WHERE id_persona=p_id_persona) THEN
        RAISE EXCEPTION USING ERRCODE='23503', MESSAGE='Persona inexistente';
    END IF;
    IF p_fin IS NOT NULL AND p_fin<=p_inicio THEN
        RAISE EXCEPTION USING ERRCODE='23514', MESSAGE='Fin debe ser posterior al inicio';
    END IF;
    IF p_facultades IS NULL OR cardinality(p_facultades)=0 THEN
        RAISE EXCEPTION USING ERRCODE='23514', MESSAGE='Se requiere al menos una facultad';
    END IF;
    IF array_ndims(p_facultades) IS DISTINCT FROM 1 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='La lista debe ser unidimensional';
    END IF;
    IF array_position(p_facultades, NULL) IS NOT NULL THEN
        RAISE EXCEPTION USING ERRCODE='23514', MESSAGE='La lista no admite elementos nulos';
    END IF;
    IF (SELECT count(DISTINCT f) FROM unnest(p_facultades) AS x(f)) <> cardinality(p_facultades) THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='La lista contiene facultades duplicadas';
    END IF;
    IF EXISTS (SELECT 1 FROM unnest(p_facultades) AS x(f)
               WHERE NOT EXISTS (SELECT 1 FROM public.facultad c WHERE c.id_facultad=x.f)) THEN
        RAISE EXCEPTION USING ERRCODE='23503', MESSAGE='La lista contiene facultades inexistentes';
    END IF;
    INSERT INTO public.autorizacion (id_autorizacion,id_cliente,id_persona,inicio_vigencia,fin_vigencia)
    VALUES (p_id_autorizacion,p_id_cliente,p_id_persona,p_inicio,p_fin);
    INSERT INTO public.autorizacion_facultad (id_autorizacion,id_facultad)
    SELECT p_id_autorizacion,f FROM unnest(p_facultades) AS x(f);
END;
$$;
-- Tecnica C3: materializacion temporal para reutilizar la clasificacion en reportes.
-- Llamar dentro de BEGIN/COMMIT; la tabla desaparece al terminar la transaccion.
CREATE PROCEDURE public.sp_preparar_resumen(p_fecha timestamp with time zone)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_fecha IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='22004', MESSAGE='Fecha obligatoria';
    END IF;
    DROP TABLE IF EXISTS pg_temp.resumen_autorizaciones;
    CREATE TEMP TABLE resumen_autorizaciones ON COMMIT DROP AS
    SELECT a.id_autorizacion,a.id_cliente,a.id_persona,
           CASE WHEN p_fecha<a.inicio_vigencia THEN 'futura'
                WHEN a.fin_vigencia IS NOT NULL AND p_fecha>=a.fin_vigencia THEN 'vencida'
                ELSE 'vigente' END AS estado
    FROM public.autorizacion a;
END;
$$;
COMMIT;
