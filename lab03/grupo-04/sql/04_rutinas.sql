-- IC-4301 | Laboratorio 3 | Grupo 04 | Alquileres El Roble
-- Script de rutinas: Funciones, Procedimiento y Trigger (04_rutinas.sql)

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Función 1: Verificar si una persona tiene autorización vigente para una facultad
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_persona_tiene_facultad(
    p_id_persona bigint,
    p_id_facultad bigint
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    v_tiene_permiso boolean := false;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM autorizacion a
        JOIN autorizacion_facultad af ON a.id_autorizacion = af.id_autorizacion
        WHERE a.id_persona = p_id_persona
          AND af.id_facultad = p_id_facultad
          AND a.inicio_vigencia <= CURRENT_TIMESTAMP
          AND (a.fin_vigencia IS NULL OR a.fin_vigencia > CURRENT_TIMESTAMP)
    ) INTO v_tiene_permiso;

    RETURN v_tiene_permiso;
END;
$$;


-- -----------------------------------------------------------------------------
-- 2. Función 2: Contar autorizaciones activas por cliente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_contar_autorizaciones_activas(
    p_id_cliente bigint
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_total integer := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM autorizacion a
    WHERE a.id_cliente = p_id_cliente
      AND a.inicio_vigencia <= CURRENT_TIMESTAMP
      AND (a.fin_vigencia IS NULL OR a.fin_vigencia > CURRENT_TIMESTAMP);

    RETURN v_total;
END;
$$;


-- -----------------------------------------------------------------------------
-- 3. Procedimiento Almacenado: Registrar una nueva autorización con facultades
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE public.sp_registrar_autorizacion(
    p_id_cliente bigint,
    p_id_persona bigint,
    p_inicio timestamp with time zone,
    p_fin timestamp with time zone,
    p_facultades bigint[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_autorizacion bigint;
    v_facultad_id bigint;
BEGIN
    -- Validar que el cliente existe
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id_cliente = p_id_cliente) THEN
        RAISE EXCEPTION 'El cliente especificado (ID %) no existe.', p_id_cliente;
    END IF;

    -- Validar que la persona existe
    IF NOT EXISTS (SELECT 1 FROM persona WHERE id_persona = p_id_persona) THEN
        RAISE EXCEPTION 'La persona especificada (ID %) no existe.', p_id_persona;
    END IF;

    -- Insertar la autorización
    INSERT INTO autorizacion (id_cliente, id_persona, inicio_vigencia, fin_vigencia)
    VALUES (p_id_cliente, p_id_persona, p_inicio, p_fin)
    RETURNING id_autorizacion INTO v_id_autorizacion;

    -- Asociar facultades
    FOREACH v_facultad_id IN ARRAY p_facultades LOOP
        IF NOT EXISTS (SELECT 1 FROM facultad WHERE id_facultad = v_facultad_id) THEN
            RAISE EXCEPTION 'La facultad especificada (ID %) no existe.', v_facultad_id;
        END IF;

        INSERT INTO autorizacion_facultad (id_autorizacion, id_facultad)
        VALUES (v_id_autorizacion, v_facultad_id);
    END LOOP;

    RAISE NOTICE 'Autorizacion ID % creada exitosamente.', v_id_autorizacion;
END;
$$;


-- -----------------------------------------------------------------------------
-- 4. Técnica adicional: Trigger para validar fechas de vigencia
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_trg_validar_vigencia()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.fin_vigencia IS NOT NULL AND NEW.fin_vigencia <= NEW.inicio_vigencia THEN
        RAISE EXCEPTION 'La fecha de fin de vigencia (%) debe ser posterior a la fecha de inicio (%).', 
            NEW.fin_vigencia, NEW.inicio_vigencia;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_vigencia ON public.autorizacion;

CREATE TRIGGER trg_validar_vigencia
BEFORE INSERT OR UPDATE ON public.autorizacion
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_validar_vigencia();

COMMIT;